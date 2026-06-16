import SwiftUI

// MARK: - 主聊天视图
// 组合消息列表 + 输入栏，负责输入/重置上下文/附件选择状态管理
// 首次出现时若没有对话，则自动创建一条新对话

/// 主聊天视图，包含消息列表、输入栏及各类弹层
struct MainChatView: View {

    // MARK: - 环境对象
    @EnvironmentObject var conversationStore: ConversationStore
    @EnvironmentObject var modelScheduler: ModelScheduler

    // MARK: - 视图状态
    /// 当前输入框内容
    @State private var inputText: String = ""
    /// 是否显示"重置上下文"确认框
    @State private var showResetAlert: Bool = false
    /// 是否显示附件选择器
    @State private var showAttachmentPicker: Bool = false

    // MARK: - 主体
    var body: some View {
        VStack(spacing: 0) {
            // 消息列表
            MessageListView()

            // 分隔线
            Divider()

            // 输入栏
            ChatInputBarView(
                inputText: $inputText,
                showAttachmentPicker: $showAttachmentPicker,
                showResetAlert: $showResetAlert
            )
        }
        // 附件选择器弹层
        .sheet(isPresented: $showAttachmentPicker) {
            AttachmentPickerView()
        }
        // 重置上下文确认框
        .alert("重置上下文", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) { }
            Button("确认", role: .destructive) {
                conversationStore.resetActiveContext()
            }
        } message: {
            Text("重置后将创建一个新的对话分支，保留历史消息但不影响模型上下文。")
        }
        // 导航标题（绑定当前对话标题）
        .navigationTitle(conversationStore.activeConversation?.title ?? "新对话")
        .navigationBarTitleDisplayMode(.inline)
        // 首次出现时若没有对话，则自动创建一条新对话
        .onAppear {
            if conversationStore.conversations.isEmpty {
                let newConv = conversationStore.createConversation(title: "新对话")
                conversationStore.selectConversation(newConv)
            } else if conversationStore.activeConversation == nil,
                      let first = conversationStore.conversations.first(where: { !$0.isArchived }) {
                conversationStore.selectConversation(first)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MainChatView()
            .environmentObject(ConversationStore.shared)
            .environmentObject(ModelScheduler(
                apiClient: QwenAPIClient(apiKey: ""),
                localModel: IOSLocalModelService()
            ))
    }
}
