import SwiftUI

// MARK: - Token 用量指示器
// 在聊天视图底部展示当前对话 token 数量与上限提醒

/// Token 用量指示视图
struct TokenUsageIndicator: View {

    // MARK: - 环境对象

    /// Token 用量监控
    @EnvironmentObject var tokenMonitor: TokenUsageMonitor

    // MARK: - 视图主体

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.caption)
                    .foregroundColor(tokenMonitor.approachingLimit ? .orange : .secondary)
                Text("对话 Token: \(tokenMonitor.currentConversationTokens)")
                    .font(.caption)
                    .foregroundColor(tokenMonitor.approachingLimit ? .orange : .secondary)
            }
            if tokenMonitor.approachingLimit {
                Text("接近 API 上限，历史消息将被截断")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
    }
}
