import SwiftUI
import Combine

// MARK: - 应用入口视图
// 负责装载全局状态（对话、设置、模型调度、语音）并作为侧边栏容器
// 使用 NotificationCenter 驱动侧边栏展开/收起通知："ToggleSidebar"

/// 应用根视图，承载主聊天界面与侧边栏
struct RootView: View {

    // MARK: - 全局状态对象（由当前视图持有并向下注入）
    @StateObject private var conversationStore: ConversationStore = .shared
    @StateObject private var settingsStore: SettingsStore = .shared
    @StateObject private var modelScheduler: ModelScheduler = ModelScheduler(
        apiClient: QwenAPIClient(apiKey: SettingsStore.shared.settings.apiKey),
        localModel: IOSLocalModelService()
    )
    @StateObject private var speechService: SpeechService = SpeechService()

    // MARK: - 视图状态
    /// 侧边栏是否已展开
    @State private var isSidebarOpen: Bool = false

    // MARK: - 通知订阅（用于监听 ToggleSidebar 通知）
    private let togglePublisher = NotificationCenter.default.publisher(for: NSNotification.Name("ToggleSidebar"))

    // MARK: - 主体
    var body: some View {
        ZStack {
            // 主聊天导航栈
            NavigationStack {
                MainChatView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                withAnimation(.easeInOut) {
                                    isSidebarOpen.toggle()
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal")
                            }
                        }
                    }
            }

            // 侧边栏（在 isSidebarOpen 为 true 时覆盖显示）
            if isSidebarOpen {
                SidebarView()
                    .transition(.move(edge: .leading))
                    .zIndex(1)
            }
        }
        // 向下注入所有全局状态
        .environmentObject(conversationStore)
        .environmentObject(settingsStore)
        .environmentObject(modelScheduler)
        .environmentObject(speechService)
        // 监听来自子视图（例如 SidebarView）的切换通知
        .onReceive(togglePublisher) { _ in
            withAnimation(.easeInOut) {
                isSidebarOpen.toggle()
            }
        }
    }
}

#Preview {
    RootView()
}
