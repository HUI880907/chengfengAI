import Foundation

// MARK: - 用户配置模型
// 用于保存用户个人偏好设置

/// 用户配置结构体，保存昵称、主题、语音播放等偏好
struct UserProfile: Codable {
    // MARK: - 属性
    var nickname: String = "用户"                // 用户昵称
    var useCustomNickname: Bool = false          // 是否使用自定义昵称
    var themePreference: String = "system"       // 主题偏好（system/light/dark），默认跟随系统
    var speechAutoPlay: Bool = false             // 是否自动语音播放
    var advancedFeaturesEnabled: Bool = false    // 是否启用高级功能
    var icloudBackupEnabled: Bool = false        // 是否启用iCloud备份

    // MARK: - 初始化方法
    /// 默认初始化
    init() {}

    // MARK: - 静态默认值
    /// 提供一个默认的用户配置实例
    static let defaultProfile: UserProfile = {
        var profile = UserProfile()
        profile.nickname = "用户"
        profile.useCustomNickname = false
        profile.themePreference = "system"
        profile.speechAutoPlay = false
        profile.advancedFeaturesEnabled = false
        profile.icloudBackupEnabled = false
        return profile
    }()
}
