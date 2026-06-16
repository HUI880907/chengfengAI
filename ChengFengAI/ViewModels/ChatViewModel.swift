import Foundation
import SwiftUI

// MARK: - 聊天视图模型
// 作用：作为聊天视图的"业务层"，负责：
// 1. 驱动消息输入 → 调用 ModelScheduler → 将结果追加到对话
// 2. 管理加载/错误状态
// 3. 自动截断过长上下文（token 超限处理）
// 4. 上下文重置支持（在消息前插入 system 消息，标记一次请求重置）
// 5. 请求取消（取消当前发送中的 Task）
//
// 线程模型：@MainActor 确保所有 @Published 属性在主线程更新

@MainActor
class ChatViewModel: ObservableObject {

    // MARK: - @Published 可观察状态

    /// 用户输入的文本
    @Published var inputText: String = ""

    /// 是否正在加载（用于显示进度动画）
    @Published var isLoading: Bool = false

    /// 最近一次错误信息（供 UI 展示提示）
    @Published var errorMessage: String?

    /// 本次发送是否发生过提供者切换（云端 → 本地），供 UI 显示提示气泡
    @Published var providerSwitched: Bool = false

    /// 是否处于"上下文已重置"状态（下次发送前插入系统消息）
    @Published var isContextReset: Bool = false

    // MARK: - 依赖（通过 init 注入，避免依赖 @EnvironmentObject）

    /// 对话存储器
    private var conversationStore: ConversationStore

    /// 模型调度器
    private var modelScheduler: ModelScheduler

    /// 应用设置存储器
    private var settingsStore: SettingsStore

    /// 语音朗读服务
    private var speechService: SpeechService

    /// 当前发送中的 Task（用于取消）
    private var sendTask: Task<Void, Never>?

    /// token 估算阈值（约等于字符数），用于自动截断
    private let tokenThreshold: Int = 32000

    /// 自动截断时保留的最近消息条数（不含 system 消息）
    private let keepRecentCount: Int = 10

    // MARK: - 初始化

    /// 初始化视图模型
    /// - Parameters:
    ///   - conversationStore: 对话存储器
    ///   - modelScheduler: 模型调度器
    ///   - settingsStore: 应用设置存储器
    ///   - speechService: 语音朗读服务
    init(conversationStore: ConversationStore,
         modelScheduler: ModelScheduler,
         settingsStore: SettingsStore,
         speechService: SpeechService) {
        self.conversationStore = conversationStore
        self.modelScheduler = modelScheduler
        self.settingsStore = settingsStore
        self.speechService = speechService
    }

    // MARK: - 发送消息

    /// 发送消息：读取输入文本 → 创建 user 消息 → 调用 ModelScheduler → 追加 assistant 消息
    func sendMessage() async {
        // 1. 校验：输入文本必须非空
        let trimmedInput = inputText.trimmed
        guard !trimmedInput.isEmpty else { return }

        // 2. 确保存在活动对话；若没有，则自动创建一个新对话
        var conversation: Conversation
        if let active = conversationStore.activeConversation {
            conversation = active
        } else {
            conversation = conversationStore.createConversation(title: trimmedInput)
        }

        // 3. 创建并追加用户消息
        var userMessage = Message(role: .user, content: trimmedInput)
        userMessage.tokenCount = estimateTokens(text: trimmedInput)
        conversation.appendMessage(userMessage)
        conversationStore.updateConversation(conversation)

        // 4. 清空输入框并切换为加载态
        inputText = ""
        errorMessage = nil
        providerSwitched = false
        isLoading = true

        // 5. 构造发送消息列表：若 isContextReset 为 true，在前面插入 system 消息
        var messagesToSend: [Message] = conversation.messages

        if isContextReset {
            let resetSystem = Message(
                role: .system,
                content: "上下文已重置，以下内容作为新的对话开始。"
            )
            messagesToSend = [resetSystem] + messagesToSend
        }

        // 6. 自动截断（若消息整体过长）
        messagesToSend = autoTruncateIfNeeded(messages: messagesToSend)

        // 7. 创建可取消的 Task 并等待调度完成
        sendTask?.cancel()
        sendTask = Task { [weak self] in
            guard let self = self else { return }

            await self.modelScheduler.sendToModel(messages: messagesToSend) { result in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }

                    self.isLoading = false

                    // 同步 providerSwitched 状态（从 ModelScheduler 读取）
                    self.providerSwitched = self.modelScheduler.providerSwitched

                    var updatedConversation = self.conversationStore.activeConversation ?? Conversation()

                    switch result {
                    case .success(let text):
                        // 8. 追加助手消息
                        var assistantMessage = Message(role: .assistant, content: text)
                        assistantMessage.tokenCount = self.estimateTokens(text: text)
                        updatedConversation.appendMessage(assistantMessage)
                        updatedConversation.totalTokens += (userMessage.tokenCount ?? 0) + (assistantMessage.tokenCount ?? 0)
                        self.conversationStore.updateConversation(updatedConversation)

                        // 9. 重置上下文状态（一次发送即消耗）
                        self.isContextReset = false

                        // 10. 若启用了自动语音播放，则朗读回复
                        if self.settingsStore.settings.profile.speechAutoPlay {
                            self.speechService.speak(text)
                        }

                    case .failure(let error):
                        // 11. 失败时：把错误信息以 assistant 消息形式呈现，便于阅读
                        let errorText = (error as? LocalizedError)?.errorDescription
                            ?? error.localizedDescription
                        self.errorMessage = errorText
                        var errorMessage = Message(
                            role: .assistant,
                            content: "⚠️ 请求失败：\(errorText)"
                        )
                        updatedConversation.appendMessage(errorMessage)
                        self.conversationStore.updateConversation(updatedConversation)
                    }
                }
            }
        }

        await sendTask?.value
    }

    // MARK: - 重置上下文

    /// 标记当前对话处于"上下文已重置"状态；下次 sendMessage 将在消息前插入 system 提示
    func resetContext() {
        isContextReset = true
        // 同时同步到 activeConversation 的 branchId（便于持久化区分）
        if var active = conversationStore.activeConversation {
            active.branchId = UUID().uuidString
            active.totalTokens = 0
            active.title = active.title + "（上下文已重置）"
            conversationStore.updateConversation(active)
        }
    }

    // MARK: - 取消发送

    /// 取消当前正在发送的请求
    func cancelSending() {
        sendTask?.cancel()
        sendTask = nil
        modelScheduler.cancelCurrentRequest()
        isLoading = false
    }

    // MARK: - 自动截断

    /// 根据 token 阈值自动截断历史消息（保留 system 消息与最近 N 条）
    /// - Parameter messages: 原始消息列表
    /// - Returns: 截断后的消息列表
    func autoTruncateIfNeeded(messages: [Message]) -> [Message] {
        // 分离 system 消息与普通消息（system 始终保留）
        var systemMessages: [Message] = []
        var nonSystemMessages: [Message] = []

        for msg in messages {
            if msg.role == .system {
                systemMessages.append(msg)
            } else {
                nonSystemMessages.append(msg)
            }
        }

        // 估算当前 token 总量（简化：字符数 * 系数）
        var totalTokens = estimateTokens(messages: messages)

        // 循环截断，直到 token 降到阈值以下，或仅剩下最近 keepRecentCount 条
        while totalTokens > tokenThreshold && nonSystemMessages.count > keepRecentCount {
            nonSystemMessages.removeFirst()
            totalTokens = estimateTokens(messages: systemMessages + nonSystemMessages)
        }

        return systemMessages + nonSystemMessages
    }

    // MARK: - 私有辅助

    /// 粗略估算文本 token 数（字符数 * 0.7）
    private func estimateTokens(text: String) -> Int {
        return Int(Double(text.count) * 0.7)
    }

    /// 估算整个消息列表的 token 总数
    private func estimateTokens(messages: [Message]) -> Int {
        return messages.reduce(0) { $0 + ($1.tokenCount ?? estimateTokens(text: $1.content)) }
    }
}
