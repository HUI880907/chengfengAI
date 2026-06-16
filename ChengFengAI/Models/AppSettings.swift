import Foundation
import SwiftUI
import Combine

// MARK: - 应用设置模型
// 作为整个应用的全局配置对象，可观察（ObservableObject），与SwiftUI结合使用

/// 应用设置类，包含用户配置、API密钥、模型优先级等
@MainActor
class AppSettings: ObservableObject {
    // MARK: - @Published属性（与UserDefaults联动）
    // 使用@Published标记，变化时会通知SwiftUI视图更新

    @Published var profile: UserProfile = UserProfile.defaultProfile  // 用户配置
    @Published var apiKey: String = ""                                 // API密钥
    @Published var modelPriority: String = "cloud"                     // 模型优先级（cloud/local/custom）
    @Published var tokenThreshold: Double = 0.85                       // Token阈值（0-1，超过则提醒）

    // MARK: - UserDefaults持久化键名
    private enum Keys {
        static let profile = "AppSettings.profile"
        static let apiKey = "AppSettings.apiKey"
        static let modelPriority = "AppSettings.modelPriority"
        static let tokenThreshold = "AppSettings.tokenThreshold"
    }

    // MARK: - 初始化方法
    /// 默认初始化
    init() {}

    /// 从UserDefaults加载初始化
    /// - Parameter userDefaults: 用于持久化存储的UserDefaults实例
    init(userDefaults: UserDefaults = .standard) {
        // 从UserDefaults恢复profile的JSON字符串并解码
        if let profileData = userDefaults.string(forKey: Keys.profile)?.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            self.profile = decoded
        }
        // 恢复简单类型字段
        self.apiKey = userDefaults.string(forKey: Keys.apiKey) ?? ""
        self.modelPriority = userDefaults.string(forKey: Keys.modelPriority) ?? "cloud"
        self.tokenThreshold = userDefaults.double(forKey: Keys.tokenThreshold)
        // 若tokenThreshold为0（UserDefaults默认值），则使用默认值0.85
        if self.tokenThreshold == 0 {
            self.tokenThreshold = 0.85
        }
    }

    // MARK: - 保存到UserDefaults
    /// 将当前设置保存到UserDefaults
    /// - Parameter userDefaults: 用于持久化存储的UserDefaults实例
    func save(to userDefaults: UserDefaults = .standard) {
        // profile编码为JSON字符串存储
        if let data = try? JSONEncoder().encode(profile),
           let jsonString = String(data: data, encoding: .utf8) {
            userDefaults.set(jsonString, forKey: Keys.profile)
        }
        userDefaults.set(apiKey, forKey: Keys.apiKey)
        userDefaults.set(modelPriority, forKey: Keys.modelPriority)
        userDefaults.set(tokenThreshold, forKey: Keys.tokenThreshold)
    }
}
