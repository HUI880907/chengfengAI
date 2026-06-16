import Foundation
import SwiftUI

// MARK: - Token 用量监控
// 估算当前对话的 token 占用，在接近上限时提醒上层截断历史消息

/// Token 用量监控器
@MainActor
class TokenUsageMonitor: ObservableObject {

    // MARK: - 可观察状态

    /// 当前会话（应用启动以来）累计 token 数
    @Published var sessionTokens: Int = 0

    /// 累计总 token 数（跨会话）
    @Published var totalTokens: Int = 0

    /// 当前对话估算的 token 数
    @Published var currentConversationTokens: Int = 0

    /// 是否接近上限（超过阈值）
    @Published var approachingLimit: Bool = false

    // MARK: - 常量

    /// Token 上限（模型可容纳的最大 token 数）
    private let tokenLimit: Int = 32768

    /// 阈值（85%），超出后触发 approachingLimit
    private let threshold: Double = 0.85

    // MARK: - UserDefaults 键

    private let totalTokensKey = "token.totalTokens"

    // MARK: - 初始化

    init() {
        let defaults = UserDefaults.standard
        totalTokens = defaults.integer(forKey: totalTokensKey)
    }

    // MARK: - 公开方法

    /// 根据消息列表估算并更新 currentConversationTokens
    /// - Parameter messages: 对话消息列表
    func update(for messages: [Message]) {
        var tokens = 0
        for message in messages {
            // 简化估算：中文字符 ~ 1 token/字，英文字符 ~ 4 token/字符
            // 使用折衷算法：count * 0.3（中文） + count * 0.25（英文），最后累加
            let content = message.content
            tokens += Int(Double(content.count) * 0.7)
            // 若消息带有附件，附加 token（粗略）
            if let attachments = message.attachments, !attachments.isEmpty {
                tokens += attachments.count * 200
            }
        }
        currentConversationTokens = tokens
        approachingLimit = checkApproachingLimit()
    }

    /// 增加本次请求的 token（会话累计 + 总累计）
    /// - Parameter count: 本次消耗的 token 数
    func addTokens(_ count: Int) {
        sessionTokens += count
        totalTokens += count
        UserDefaults.standard.set(totalTokens, forKey: totalTokensKey)
    }

    /// 重置当前会话累计（如用户主动清理时调用）
    func resetSession() {
        sessionTokens = 0
    }

    /// 判断当前对话 token 数是否接近上限
    /// - Returns: true 表示已接近或超过上限
    func checkApproachingLimit() -> Bool {
        return Double(currentConversationTokens) >= Double(tokenLimit) * threshold
    }
}
