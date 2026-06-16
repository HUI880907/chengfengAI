import SwiftUI
import Combine

// MARK: - 应用入口视图
// 负责装载全局状态（对话、设置、模型调度、语音）并作为侧边栏容器
// 使用 NotificationCenter 驱动侧边栏展开/收起通知："ToggleSidebar"

/// 应用根视图，承载主聊天界面与侧边栏
struct RootView: View {

    // MARK: - 全局状态对象（从上一层 ChengFengAIApp 注入）
    @EnvironmentObject private var conversationStore: ConversationStore
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var modelScheduler: ModelScheduler
    @EnvironmentObject private var speechService: SpeechService
    @EnvironmentObject private var clipboardService: ClipboardService
    @EnvironmentObject private var quickPromptService: QuickPromptService
    @EnvironmentObject private var tokenUsageMonitor: TokenUsageMonitor
    @EnvironmentObject private var speechSettings: SpeechSettings

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
