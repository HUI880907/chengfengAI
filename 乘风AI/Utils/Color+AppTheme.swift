import SwiftUI

// MARK: - Color 应用主题
// 统一管理应用内常用颜色，便于整体替换主题色

extension Color {

    /// 主色调（应用 Logo / 按钮等主要强调色
    static let appPrimary = Color.blue

    /// 次要强调色（用于辅助操作/警告等非主要位置）
    static let appSecondary = Color.orange

    /// 用户消息气泡颜色
    static let appUserBubble = Color.blue.opacity(0.9)

    /// AI 助手消息气泡颜色
    static let appAssistantBubble = Color.gray.opacity(0.15)

    /// 应用背景色（跟随系统背景色）
    static let appBackground = Color(UIColor.systemBackground)
}
