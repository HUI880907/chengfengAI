import SwiftUI

// MARK: - 消息列表视图
// 使用 List + ScrollViewReader 实现消息列表与自动滚动到底部的能力
// 监听 activeConversation.messages 数量变化，在新增消息时滚动到最后一条

/// 消息列表视图，负责渲染多条消息气泡
struct MessageListView: View {

    // MARK: - 环境对象
    @EnvironmentObject var conversationStore: ConversationStore
    @EnvironmentObject var modelScheduler: ModelScheduler

    // MARK: - 主体
    var body: some View {
        ScrollViewReader { proxy in
            List(conversationStore.activeConversation?.messages ?? []) { message in
                MessageBubbleView(message: message)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .id(message.id)
            }
            .listStyle(.plain)
            // 消息数量变化时，滚动到最后一条
            .onChange(of: conversationStore.activeConversation?.messages.count) { _ in
                if let lastId = conversationStore.activeConversation?.messages.last?.id {
                    withAnimation {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            // 首次出现时若已有消息，也滚动到底部
            .onAppear {
                if let lastId = conversationStore.activeConversation?.messages.last?.id {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
    }
}

#Preview {
    MessageListView()
        .environmentObject(ConversationStore.shared)
        .environmentObject(ModelScheduler(
            apiClient: QwenAPIClient(apiKey: ""),
            localModel: IOSLocalModelService()
        ))
}
