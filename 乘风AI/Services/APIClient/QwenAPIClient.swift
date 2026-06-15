import Foundation

// MARK: - 千问API客户端
// 用于对接通义千问（DashScope）兼容OpenAI Chat Completions接口的云端API
// 支持异步请求、流式响应、错误识别（限流、鉴权失败等）

/// 千问API客户端类
class QwenAPIClient {

    // MARK: - 属性

    /// API基础URL（默认使用阿里云DashScope兼容模式接口）
    var baseURL: String = "https://dashscope.aliyuncs.com/compatible-mode/v1"

    /// API密钥（需要用户配置）
    var apiKey: String

    /// 模型名称（默认使用 qwen3.5-9b-chat）
    var model: String = "qwen3.5-9b-chat"

    /// URLSession 实例（用于发起网络请求，可注入自定义配置）
    var urlSession: URLSession

    // MARK: - 初始化方法

    /// 初始化千问API客户端
    /// - Parameters:
    ///   - apiKey: API密钥（必需）
    ///   - baseURL: 基础URL，默认使用阿里云DashScope兼容模式
    ///   - model: 模型名称，默认 qwen3.5-9b-chat
    ///   - urlSession: URLSession，默认使用共享实例
    init(apiKey: String,
         baseURL: String = "https://dashscope.aliyuncs.com/compatible-mode/v1",
         model: String = "qwen3.5-9b-chat",
         urlSession: URLSession = .shared) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model
        self.urlSession = urlSession
    }

    // MARK: - 公开方法（回调式 API）

    /// 发送聊天消息（回调式接口，向后兼容）
    /// - Parameters:
    ///   - messages: 聊天消息数组（按顺序包含 system/user/assistant）
    ///   - completion: 完成回调，返回成功文本或错误
    func sendMessage(messages: [Message],
                     completion: @escaping (Result<String, Error>) -> Void) {
        // 使用 Task 封装 async/await 调用以适配回调式接口
        Task {
            do {
                let result = try await sendMessageAsync(messages: messages)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - 公开方法（async/await API）

    /// 发送聊天消息（async/await 版本，推荐使用）
    /// - Parameter messages: 聊天消息数组
    /// - Returns: 模型返回的纯文本回答
    /// - Throws: QwenAPIError 或其他网络错误
    func sendMessageAsync(messages: [Message]) async throws -> String {
        // 1. 校验 API 密钥是否已配置
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw QwenAPIError.apiKeyMissing
        }

        // 2. 构建请求
        let request = try buildRequest(messages: messages)

        // 3. 使用 async/await 发起网络请求（iOS 15.0+ 可用）
        let (data, response) = try await urlSession.data(for: request)

        // 4. 校验 HTTP 响应状态码
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QwenAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            // 5. 解析 JSON 响应
            return try parseResponse(data: data)
        case 401:
            // 鉴权失败：API Key 无效或缺失
            throw QwenAPIError.invalidResponse
        case 429:
            // 请求限流：短时间内请求过多
            throw QwenAPIError.rateLimit
        case 400...499:
            // 其他客户端错误，可能是 token 超限
            if let errorInfo = try? JSONDecoder().decode(ErrorWrapper.self, from: data) {
                if errorInfo.error?.message?.lowercased().contains("token") ?? false {
                    throw QwenAPIError.tokenExceeded
                }
            }
            throw QwenAPIError.invalidResponse
        case 500...599:
            // 服务端错误
            throw QwenAPIError.networkError
        default:
            throw QwenAPIError.invalidResponse
        }
    }

    // MARK: - 公开方法（流式响应，可选）

    /// 发送聊天消息并逐行接收流式响应
    /// - Parameters:
    ///   - messages: 聊天消息数组
    ///   - onReceive: 每次收到新片段时回调（参数为累计文本 / 增量文本）
    /// - Returns: 最终完整文本
    /// - Throws: QwenAPIError 或其他网络错误
    func sendMessageStream(messages: [Message],
                           onReceive: @escaping (_ delta: String, _ fullText: String) -> Void) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw QwenAPIError.apiKeyMissing
        }

        // 开启流式模式：在请求体中添加 stream=true
        var request = try buildRequest(messages: messages, stream: true)
        request.timeoutInterval = 120 // 流式请求允许更长超时

        let (bytes, response) = try await urlSession.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw QwenAPIError.networkError
        }

        var fullText = ""
        var buffer = Data()

        // 使用 bytes 逐行解析 Server-Sent Events (SSE) 格式
        for try await byte in bytes {
            buffer.append(byte)

            // SSE 使用 \n\n 作为事件分隔符；每个 data: 前缀的行是一段 JSON
            if let chunk = String(data: buffer, encoding: .utf8), chunk.contains("\n\n") {
                let lines = chunk.components(separatedBy: "\n")
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard trimmed.hasPrefix("data:") else { continue }
                    let jsonPart = trimmed
                        .dropFirst("data:".count)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !jsonPart.isEmpty, jsonPart != "[DONE]" else { continue }

                    if let jsonData = jsonPart.data(using: .utf8),
                       let chunk = try? JSONDecoder().decode(StreamChunk.self, from: jsonData),
                       let delta = chunk.choices?.first?.delta?.content {
                        fullText += delta
                        onReceive(delta, fullText)
                    }
                }
                buffer.removeAll()
            }
        }

        return fullText
    }

    // MARK: - 请求构建

    /// 构建 POST 请求
    /// - Parameters:
    ///   - messages: 聊天消息数组
    ///   - stream: 是否开启流式模式，默认 false
    /// - Returns: 已配置好的 URLRequest
    func buildRequest(messages: [Message], stream: Bool = false) throws -> URLRequest {
        // 1. 组装 URL
        guard let url = URL(string: baseURL + "/chat/completions") else {
            throw QwenAPIError.invalidResponse
        }

        // 2. 构造请求体（兼容 OpenAI Chat Completions 格式）
        let apiMessages = messages.map { msg in
            ChatMessage(role: msg.role.rawValue, content: msg.content)
        }
        let body = RequestBody(model: model,
                               messages: apiMessages,
                               stream: stream)

        // 3. 序列化为 JSON
        let jsonData = try JSONEncoder().encode(body)

        // 4. 构造 URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30 // 默认 30 秒超时

        return request
    }

    // MARK: - 响应解析（私有辅助）

    /// 解析非流式 JSON 响应
    private func parseResponse(data: Data) throws -> String {
        let wrapper = try JSONDecoder().decode(ResponseWrapper.self, from: data)
        guard let text = wrapper.choices?.first?.message?.content else {
            throw QwenAPIError.invalidResponse
        }
        return text
    }

    // MARK: - 内部数据结构（用于 JSON 编解码）

    /// 请求体结构（OpenAI Chat Completions 格式）
    private struct RequestBody: Encodable {
        let model: String
        let messages: [ChatMessage]
        let stream: Bool?
    }

    /// 单条消息结构
    private struct ChatMessage: Encodable {
        let role: String
        let content: String
    }

    /// 非流式响应包装
    private struct ResponseWrapper: Decodable {
        let choices: [Choice]?
    }

    private struct Choice: Decodable {
        let message: ChatResponseMessage?
    }

    private struct ChatResponseMessage: Decodable {
        let content: String?
    }

    /// 流式响应结构
    private struct StreamChunk: Decodable {
        let choices: [StreamChoice]?
    }

    private struct StreamChoice: Decodable {
        let delta: StreamDelta?
    }

    private struct StreamDelta: Decodable {
        let content: String?
    }

    /// 错误响应包装
    private struct ErrorWrapper: Decodable {
        let error: ErrorInfo?
    }

    private struct ErrorInfo: Decodable {
        let message: String?
    }
}

// MARK: - 错误枚举

/// 千问 API 相关错误类型
enum QwenAPIError: Error, LocalizedError {
    case networkError          // 网络错误（无法连接 / 超时 / 服务端 5xx）
    case rateLimit             // 429 限流
    case tokenExceeded         // token 数量超出模型限制
    case invalidResponse       // 响应格式异常或非 2xx
    case apiKeyMissing         // API Key 未配置

    /// 本地化错误描述（用于 UI 展示）
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "网络连接异常，请检查网络后重试。"
        case .rateLimit:
            return "请求过于频繁，请稍后再试。"
        case .tokenExceeded:
            return "消息内容过长，超出模型 token 限制。"
        case .invalidResponse:
            return "服务器响应异常，请稍后重试。"
        case .apiKeyMissing:
            return "未配置 API Key，请在设置中填写。"
        }
    }
}
