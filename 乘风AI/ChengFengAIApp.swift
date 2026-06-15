import SwiftUI
import Foundation

// MARK: - 应用主入口
// 负责创建并注入全局状态（对话、设置、模型调度、语音），启动应用根视图

@main
struct ChengFengAIApp: App {

    // MARK: - 全局状态对象

    /// 对话存储器（单例）
    @StateObject private var conversationStore: ConversationStore = .shared

    /// 应用设置存储器（单例）
    @StateObject private var settingsStore: SettingsStore = .shared

    /// 模型调度器（在 init 中手动创建，以保证依赖注入顺序）
    @StateObject private var modelScheduler: ModelScheduler

    /// 语音朗读服务
    @StateObject private var speechService: SpeechService = SpeechService()

    // MARK: - 初始化

    init() {
        // 1. 使用 settingsStore 的 API Key 创建云端 API 客户端
        let apiClient = QwenAPIClient(apiKey: SettingsStore.shared.settings.apiKey)
        // 2. 创建本地模型服务
        let localModel = IOSLocalModelService()
        // 3. 构造 ModelScheduler 并包装为 StateObject
        _modelScheduler = StateObject(
            wrappedValue: ModelScheduler(apiClient: apiClient, localModel: localModel)
        )
    }

    // MARK: - Scene 主体

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(conversationStore)
                .environmentObject(settingsStore)
                .environmentObject(modelScheduler)
                .environmentObject(speechService)
        }
    }
}
