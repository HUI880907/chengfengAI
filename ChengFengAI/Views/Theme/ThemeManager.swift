import SwiftUI
import Foundation

// MARK: - 主题管理器
// 管理应用的浅色/深色/跟随系统主题，通过 UserDefaults 持久化

/// 主题管理器
@MainActor
class ThemeManager: ObservableObject {

    // MARK: - 外观枚举

    /// 外观模式
    enum Appearance: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        /// 显示名称
        var displayName: String {
            switch self {
            case .system: return "跟随系统"
            case .light: return "浅色"
            case .dark: return "深色"
            }
        }
    }

    // MARK: - 可观察状态

    /// 当前选择的外观
    @Published var appearance: Appearance = .system

    // MARK: - UserDefaults 键

    private let appearanceKey = "theme.appearance"

    // MARK: - 计算属性

    /// 根据当前外观返回对应的 SwiftUI ColorScheme
    /// system → nil（由系统决定）；light → .light；dark → .dark
    var colorScheme: ColorScheme? {
        switch appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    // MARK: - 初始化

    init() {
        load()
    }

    // MARK: - 公开方法

    /// 将当前 appearance 写入 UserDefaults
    func apply() {
        UserDefaults.standard.set(appearance.rawValue, forKey: appearanceKey)
    }

    /// 从 UserDefaults 读取 appearance
    func load() {
        if let raw = UserDefaults.standard.string(forKey: appearanceKey),
           let saved = Appearance(rawValue: raw) {
            appearance = saved
        } else {
            appearance = .system
        }
    }
}
