import Foundation
import Network
import Combine

// MARK: - 模型调度器
// 作用：在 云端API 与 本地模型 之间智能切换，保证应用在任意网络条件下都能"最小可用"。
//
// === 降级逻辑总览 ===
// 1️⃣ 默认首选云端模型（qwenCloud）：当网络可用 + API Key 配置 + token 未超限 + 非超大附件
// 2️⃣ 云端失败时（限流/超时/报错/无网络），切换至 iosLocal 并在 UI 上提示"已切换到本地助手"
// 3️⃣ 批量上传大文件（>10 个 或 总大小 > 50MB）时直接使用 iosLocal
// 4️⃣ 任何降级事件通过 @Published 通知 UI 刷新
//
// === 线程模型 ===
// @MainActor：所有对外的 @Published 属性以及 UI 相关状态必须在主线程更新
// async/await：网络与本地调用在后台线程执行
// ObservableObject：供 SwiftUI / Combine 订阅

/// 模型调度器，负责决策"云端 / 本地" 智能切换
@MainActor
class ModelScheduler: ObservableObject {

    // MARK: - 可观察状态

    /// 当前使用的模型提供者
    @Published var currentProvider: ModelProviderType

    /// 是否正在请求中（UI 加载态）
    @Published var isLoading: Bool = false

    /// 最近一次错误（用于 UI 提示）
    @Published var lastError: String? = nil

    /// 本次请求是否发生过提供者切换（用于 UI 显示提示气泡）
    @Published var providerSwitched: Bool = false

    // MARK: - 依赖

    /// 云端 API 客户端
    let apiClient: QwenAPIClient

    /// 本地模型服务
    let localModel: IOSLocalModelService

    // MARK: - 内部状态

    /// 网络监视器（nonisolated 以便 deinit 可访问）
    nonisolated(unsafe) private let pathMonitor = NWPathMonitor()
    nonisolated(unsafe) private let monitorQueue = DispatchQueue(label: "com.chengfeng.modelScheduler.pathMonitor")
    private var lastPath: NWPath?

    /// 当前正在执行的请求句柄（用于取消）
    private var currentRequestID: UUID?
    private var currentTask: Task<Void, Never>?

    /// token 超限阈值（简化估算，约等于字符数）
    private let tokenThreshold: Int = 32000

    // MARK: - 初始化

    /// 初始化模型调度器
    /// - Parameters:
    ///   - currentProvider: 默认模型提供者，默认 .qwenCloud
    ///   - apiClient: 云端 API 客户端实例
    ///   - localModel: 本地模型服务实例
    init(currentProvider: ModelProviderType = .qwenCloud,
         apiClient: QwenAPIClient,
         localModel: IOSLocalModelService) {
        self.currentProvider = currentProvider
        self.apiClient = apiClient
        self.localModel = localModel

        // 启动网络监视器（后台队列，避免阻塞主线程）
        pathMonitor.start(queue: monitorQueue)
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.lastPath = path
            }
        }
    }

    deinit {
        pathMonitor.cancel()
    }

    // MARK: - 主调度方法

    /// 对外主调度方法（回调式接口）
    ///
    /// 调度决策顺序：
    /// 1. 若附件总数 > 10 或总大小 > 50MB → 直接走 iosLocal
    /// 2. 否则尝试 qwenCloud；若失败（限流/超时/报错/无网络）→ 降级至 iosLocal
    /// 3. iosLocal 再次失败 → 向上层抛出错误
    ///
    /// - Parameters:
    ///   - messages: 聊天消息数组
    ///   - completion: 完成回调（返回 回答文本 或 错误）
    func sendToModel(messages: [Message],
                    completion: @escaping (Result<String, Error>) -> Void) async {

        // 为当前请求分配一个 UUID，便于取消
        let requestID = UUID()
        currentRequestID = requestID
        providerSwitched = false
        lastError = nil
        isLoading = true

        // 构造一个可取消的 Task
        currentTask = Task { [weak self] in
            guard let self = self else { return }

            defer {
                // 主线程统一更新加载状态
                Task { @MainActor in
                    if self.currentRequestID == requestID {
                        self.isLoading = false
                    }
                }
            }

            // 检查是否已被取消
            if Task.isCancelled { return }

            // === 阶段 1：收集附件信息，判断是否优先本地 ===
            let allAttachments = self.collectAttachments(from: messages)
            if self.shouldUseLocalModel(for: allAttachments) {
                self.logSwitch(to: .iosLocal, reason: "批量大文件，优先本地")
                self.switchProvider(to: .iosLocal)
                await self.runLocal(messages: messages,
                                    requestID: requestID,
                                    completion: completion)
                return
            }

            // === 阶段 2：网络与token 检查，决定首选云端 ===
            let networkAvailable = await self.checkNetworkAvailability()
            let tokenOK = !self.isTokenExceeded(in: messages)
            let apiKeyOK = !self.apiClient.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            let canUseCloud = networkAvailable && tokenOK && apiKeyOK

            if canUseCloud {
                self.switchProvider(to: .qwenCloud)

                // 使用 withTimeout 为云端请求加上 30 秒超时保护
                do {
                    let text = try await self.withCloudTimeout { [weak self] in
                        guard let self = self else { throw QwenAPIError.networkError }
                        return try await self.apiClient.sendMessageAsync(messages: messages)
                    }

                    // 请求未被取消才回调
                    guard self.currentRequestID == requestID && !Task.isCancelled else { return }
                    completion(.success(text))
                    return

                } catch {
                    // === 阶段 3：云端失败 → 降级至本地
                    self.logSwitch(to: .iosLocal, reason: "云端失败: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)")

                    // token超限的场合直接提示而非降级
                    if let qwenErr = error as? QwenAPIError, qwenErr == .tokenExceeded {
                        Task { @MainActor in
                            self.lastError = "消息内容过长，超出模型 token 限制"
                        }
                        completion(.failure(error))
                        return
                    }

                    await self.runLocal(messages: messages,
                                       requestID: requestID,
                                       completion: completion)
                    return
                }
            } else {
                // === 阶段 4：云端不可用 → 直接本地 ===
                let reason: String
                if !apiKeyOK {
                    reason = "未配置 API Key"
                } else if !networkAvailable {
                    reason = "网络不可用"
                } else {
                    reason = "token 超限"
                }
                self.logSwitch(to: .iosLocal, reason: reason)
                self.switchProvider(to: .iosLocal)
                await self.runLocal(messages: messages,
                                    requestID: requestID,
                                    completion: completion)
                return
            }
        }

        // 等待 Task 完成（当前方法本身也是 async）
        await currentTask?.value
    }

    // MARK: - 网络可达性检测

    /// 检测当前网络是否可用
    /// - Returns: true 表示网络可用
    func checkNetworkAvailability() async -> Bool {
        // 优先使用 NWPathMonitor 的缓存结果
        if let path = lastPath {
            return path.status == .satisfied
        }
        // 若尚未收到网络路径，尝试一次简单的 DNS/主机探测
        return await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "com.chengfeng.modelScheduler.oneShot")
            monitor.pathUpdateHandler = { path in
                continuation.resume(returning: path.status == .satisfied)
                monitor.cancel()
            }
            monitor.start(queue: queue)
            // 1.5 秒超时保护
            queue.asyncAfter(deadline: .now() + 1.5) {
                continuation.resume(returning: false)
                monitor.cancel()
            }
        }
    }

    // MARK: - 是否应切本地（基于附件规模）

    /// 根据附件规模判断是否应切本地模型
    ///
    /// 规则：
    ///   • 附件总数 > 10 个
    ///   • 附件总大小 > 50 MB（50 * 1024 * 1024 字节）
    ///
    /// - Parameter attachments: 附件数组
    /// - Returns: true 表示应使用本地模型
    func shouldUseLocalModel(for attachments: [Attachment]) -> Bool {
        if attachments.isEmpty { return false }
        let count = attachments.count
        let totalSize = attachments.reduce(Int64(0)) { $0 + $1.size }
        let sizeMB = Double(totalSize) / (1024.0 * 1024.0)
        return count > 10 || sizeMB > 50.0
    }

    // MARK: - 取消请求

    /// 取消当前请求（通过 UUID 比对）
    func cancelCurrentRequest() {
        currentRequestID = nil
        currentTask?.cancel()
        currentTask = nil
        isLoading = false
    }

    // MARK: - 私有辅助

    /// 切换当前提供者并通知UI
    private func switchProvider(to provider: ModelProviderType) {
        if currentProvider != provider {
            currentProvider = provider
            providerSwitched = true
            // 同时记录最后一条错误以在UI提示降级
            lastError = provider.isLocal
                ? "已切换至本地助手（离线模式）"
                : nil
        }
    }

    /// 收集消息中的所有附件
    private func collectAttachments(from messages: [Message]) -> [Attachment] {
        return messages.compactMap { $0.attachments }.flatMap { $0 }
    }

    /// 估算消息是否超限（简化规则：字符数 * 系数）
    private func isTokenExceeded(in messages: [Message]) -> Bool {
        // 简化估算：token 数 ≈ 字符数 * 0.5（中英文混合粗略估算）
        let totalChars = messages.reduce(0) { $0 + $1.content.count }
        let estimatedTokens = Int(Double(totalChars) * 0.7)
        return estimatedTokens > tokenThreshold
    }

    /// 执行本地模型调用
    private func runLocal(messages: [Message],
                         requestID: UUID,
                         completion: @escaping (Result<String, Error>) -> Void) async {
        do {
            // 取最后一条消息文本作为主输入
            let lastContent = messages.last?.content ?? ""
            let text = try await localModel.sendMessage(lastContent, context: messages)
            guard currentRequestID == requestID && !Task.isCancelled else { return }
            completion(.success(text))
        } catch {
            guard currentRequestID == requestID && !Task.isCancelled else { return }
            Task { @MainActor in
                self.lastError = error.localizedDescription
            }
            completion(.failure(error))
        }
    }

    /// 为云端请求添加 30 秒超时保护
    private func withCloudTimeout<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                return try await operation()
            }
            group.addTask {
                // 30 秒超时
                try await Task.sleep(nanoseconds: 30_000_000_000)
                throw QwenAPIError.networkError
            }
            // 先完成者胜出
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    /// 统一日志输出（便于后续接入文件日志）
    private func logSwitch(to provider: ModelProviderType, reason: String) {
        #if DEBUG
        print("[ModelScheduler] 切换至 \(provider.displayName)，原因：\(reason)")
        #endif
    }
}
