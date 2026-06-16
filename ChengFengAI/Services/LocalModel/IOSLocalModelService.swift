import Foundation

// MARK: - iOS 本地模型服务
// iOS 16.0 不提供系统级大语言模型接口，因此这里提供一套"兜底方案"：
//   - 基于关键词匹配的规则引擎
//   - 本地预设回答
//   - 附件文本内容本地摘要解析
// 作用：当云端 API 不可用时（无网络 / 限流 / 未配置 API Key），
//       仍能为用户提供最基本的交互与内容摘要能力。

/// iOS 本地模型服务类（作为云端 API 失败时的最小可用兜底）
class IOSLocalModelService {

    // MARK: - 公开方法

    /// 发送消息并获取本地规则匹配后的回答
    /// - Parameters:
    ///   - content: 用户最新一条消息的文本内容
    ///   - context: 上下文消息列表（可选，用于简单关联）
    /// - Returns: 本地规则生成的回答文本
    /// - Throws: LocalModelError
    func sendMessage(_ content: String, context: [Message]?) async throws -> String {
        // 轻量级异步处理，避免阻塞主线程
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: LocalModelError.localModelUnavailable)
                    return
                }

                // 1. 基础内容校验
                let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    continuation.resume(throwing: LocalModelError.contentTooComplex)
                    return
                }

                // 2. 收集上下文附件内容（若有），用于本地解析
                var attachmentsText = ""
                if let context = context {
                    for msg in context {
                        if let attachments = msg.attachments, !attachments.isEmpty {
                            attachmentsText += self.extractText(from: attachments)
                        }
                    }
                }
                // 合并用户最新消息中的附件
                if let lastMsg = context?.last, let attachments = lastMsg.attachments {
                    attachmentsText += self.extractText(from: attachments)
                }

                // 3. 规则匹配：按优先级依次识别
                if let reply = self.handleGreeting(content: trimmed) {
                    continuation.resume(returning: reply)
                    return
                }
                if let reply = self.handleDateQuery(content: trimmed) {
                    continuation.resume(returning: reply)
                    return
                }
                if let reply = self.handleWeatherQuery(content: trimmed) {
                    continuation.resume(returning: reply)
                    return
                }
                if let reply = self.handleTimeQuery(content: trimmed) {
                    continuation.resume(returning: reply)
                    return
                }
                if let reply = self.handleHelpQuery(content: trimmed) {
                    continuation.resume(returning: reply)
                    return
                }

                // 4. 若有附件内容，尝试本地摘要
                if !attachmentsText.isEmpty {
                    let summary = self.summarize(attachmentsText: attachmentsText, query: trimmed)
                    continuation.resume(returning: summary)
                    return
                }

                // 5. 兜底通用答复：提示当前为离线模式
                continuation.resume(returning: self.fallbackReply(for: trimmed))
            }
        }
    }

    // MARK: - 私有规则方法

    /// 问候语识别
    private func handleGreeting(content: String) -> String? {
        let greetings = ["你好", "您好", "hi", "hello", "哈喽", "在吗", "在么", "嗨"]
        for g in greetings {
            if content.lowercased().contains(g.lowercased()) {
                return "你好！我是本地助手（离线模式）。我可以回答简单问题、读取本地文件内容。\n如需更智能的回答，请连接网络或配置云端 API。"
            }
        }
        return nil
    }

    /// 日期相关询问
    private func handleDateQuery(content: String) -> String? {
        let keywords = ["今天", "日期", "几号", "星期", "今日"]
        guard keywords.contains(where: { content.contains($0) }) else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 EEEE"
        let dateStr = formatter.string(from: Date())
        return "今天是 \(dateStr)。（本地回答）"
    }

    /// 时间相关询问
    private func handleTimeQuery(content: String) -> String? {
        let keywords = ["现在几点", "几点钟", "时间", "几点了"]
        guard keywords.contains(where: { content.contains($0) }) else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm:ss"
        let timeStr = formatter.string(from: Date())
        return "当前时间为 \(timeStr)。（本地回答）"
    }

    /// 天气相关询问（仅给出无法查询的友好提示）
    private func handleWeatherQuery(content: String) -> String? {
        let keywords = ["天气", "下雨", "温度", "多冷", "多热", "气温"]
        guard keywords.contains(where: { content.contains($0) }) else { return nil }
        return "抱歉，本地助手无法实时查询天气。请连接网络后使用云端模型查询。"
    }

    /// 帮助 / 使用说明
    private func handleHelpQuery(content: String) -> String? {
        let keywords = ["帮助", "怎么用", "help", "使用说明", "功能"]
        guard keywords.contains(where: { content.lowercased().contains($0.lowercased()) }) else { return nil }
        return """
        【本地助手支持功能】
        • 简单问答：你好、日期、时间等
        • 文件摘要：可读取 txt / 文本类附件内容并给出简要摘要
        • 离线兜底：云端不可用时提供最小交互能力

        如需更强大的 AI 能力，请在设置中配置 API Key 并保持网络连接。
        """
    }

    /// 从附件中抽取可识别的文本内容
    private func extractText(from attachments: [Attachment]) -> String {
        var result = ""
        for att in attachments {
            // 对于纯文本附件直接读取；其他类型提示无法本地解析
            switch att.type {
            case .text:
                if let data = att.fileData,
                   let text = String(data: data, encoding: .utf8) ??
                             String(data: data, encoding: .utf16) {
                    result += "\n[\(att.fileName)]\n\(text)\n"
                } else {
                    result += "\n[\(att.fileName)] - 文件编码无法本地解析\n"
                }
            case .pdf, .doc, .image:
                result += "\n[\(att.fileName)] - 该格式无法由本地助手解析，建议联网后使用云端模型\n"
            }
        }
        return result
    }

    /// 对附件文本进行简单本地摘要：按句截取前若干行
    private func summarize(attachmentsText: String, query: String) -> String {
        // 取前 2000 字符作为摘要内容（过长内容本地不做语义处理）
        let maxLength = 2000
        let snippet: String
        if attachmentsText.count > maxLength {
            let index = attachmentsText.index(attachmentsText.startIndex,
                                              offsetBy: maxLength)
            snippet = String(attachmentsText[..<index]) + "……"
        } else {
            snippet = attachmentsText
        }

        var reply = "【本地助手 · 文件摘要】\n"
        reply += "查询：\(query)\n\n"
        reply += "已识别的文本内容片段：\n"
        reply += snippet
        reply += "\n\n提示：完整语义分析请连接网络并使用云端模型。"
        return reply
    }

    /// 通用兜底回答（当所有规则都不匹配时）
    private func fallbackReply(for content: String) -> String {
        // 内容过长时提示复杂度问题
        if content.count > 2000 {
            return "抱歉，当前为离线模式，本地助手无法处理复杂问题。\n请尝试更简短的提问，或连接网络以使用云端 AI。"
        }
        return "（离线模式）本地助手已收到消息：\"\(content)\"，但无法进行语义理解。\n建议：\n• 检查网络连接\n• 在设置中配置 API Key\n• 提问可简化为：日期、时间、文件摘要等本地支持的类型"
    }
}

// MARK: - 错误枚举

/// 本地模型服务相关错误类型
enum LocalModelError: Error, LocalizedError {
    case localModelUnavailable  // 本地模型不可用（服务实例释放等异常）
    case contentTooComplex      // 内容过于复杂 / 为空，本地无法处理
    case unsupportedType        // 不支持的附件类型或请求类型

    var errorDescription: String? {
        switch self {
        case .localModelUnavailable:
            return "本地助手暂时不可用。"
        case .contentTooComplex:
            return "内容过于复杂，本地助手无法处理。"
        case .unsupportedType:
            return "不支持的内容类型。"
        }
    }
}
