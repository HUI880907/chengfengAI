import Foundation

// MARK: - Bundle 版本信息扩展
// 便捷获取应用版本号、构建号、显示名称

extension Bundle {

    /// 应用版本号（CFBundleShortVersionString）
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// 构建号（CFBundleVersion）
    var appBuild: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// 应用显示名（CFBundleDisplayName），若未设置则回落为 CFBundleName
    var appDisplayName: String {
        if let display = infoDictionary?["CFBundleDisplayName"] as? String, !display.isEmpty {
            return display
        }
        if let name = infoDictionary?["CFBundleName"] as? String, !name.isEmpty {
            return name
        }
        return "乘风AI"
    }
}
