import Foundation
import SwiftUI
import Combine

// MARK: - 应用设置存储器
// 负责AppSettings对象的加载与保存，使用UserDefaults存储JSON字符串

@MainActor
class SettingsStore: ObservableObject {
    // MARK: - 单例
    static let shared = SettingsStore()

    // MARK: - @Published属性
    @Published var settings: AppSettings

    // MARK: - UserDefaults键名
    private let settingsKey: String = "SettingsStore.appSettingsJSON"

    // MARK: - 初始化方法
    private init() {
        self.settings = AppSettings()
        loadSettings()
    }

    // MARK: - 加载与保存

    /// 从UserDefaults加载AppSettings（JSON字符串）
    func loadSettings() {
        let defaults = UserDefaults.standard
        // 读取保存的JSON字符串
        guard let jsonString = defaults.string(forKey: settingsKey),
              let data = jsonString.data(using: .utf8) else {
            // 若没有保存过，则使用默认值
            settings = AppSettings()
            return
        }
        do {
            let decoder = JSONDecoder()
            settings = try decoder.decode(AppSettings.self, from: data)
        } catch {
            print("⚠️ 加载设置失败: \(error.localizedDescription)")
            settings = AppSettings()
        }
    }

    /// 将当前设置保存到UserDefaults（JSON字符串格式）
    func saveSettings() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(settings)
            if let jsonString = String(data: data, encoding: .utf8) {
                UserDefaults.standard.set(jsonString, forKey: settingsKey)
            }
        } catch {
            print("⚠️ 保存设置失败: \(error.localizedDescription)")
        }
    }
}
