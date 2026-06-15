import Foundation

// MARK: - Token 估算器
// 用于粗略估算文本/消息的 token 数量，避免每次请求都依赖真实 tokenizer。
//
// 估算规则：
//   • 纯 ASCII：token ≈ 字符数 * 0.25
//   • 中文/混合：token ≈ 字符数 * 0.7
//   • 空内容 → 0 tokens

/// Token 估算工具
@MainActor
final class TokenCounter {

    /// Token 上限（用于判断是否超限，单位：token）
    static let defaultTokenLimit: Int = 32000

    /// 估算单段文本的 token 数量
    /// - Parameter text: 文本内容
    /// - Returns: 估算得到的 token 数量
    func estimateTokens(in text: String) -> Int {
        guard !text.isEmpty else { return 0 }
        // 粗略估算：中英文混合，token ≈ 字符数 * 0.7
        return Int(Double(text.count) * 0.7)
    }

    /// 估算消息列表的 token 总数
    /// - Parameter messages: 消息列表
    /// - Returns: 估算得到的 token 总数
    func estimateTokens(for messages: [Message]) -> Int {
        guard !messages.isEmpty else { return 0 }
        return messages.reduce(0) { total, msg in
            total + (msg.tokenCount ?? estimateTokens(in: msg.content))
        }
    }

    /// 判断是否接近 token 上限
    /// - Parameters:
    ///   - totalTokens: 当前 token 总数
    ///   - limit: 上限
    ///   - threshold: 0-1 之间的比例阈值，超过此比例即视为接近
    /// - Returns: 是否接近或超出上限
    func isApproachingLimit(totalTokens: Int,
                            limit: Int = TokenCounter.defaultTokenLimit,
                            threshold: Double = 0.85) -> Bool {
        return Double(totalTokens) >= Double(limit) * threshold
    }
}
