import SwiftUI

// MARK: - 侧边栏视图
// 从左侧滑入，展示对话列表、新建对话、设置入口
// 通过 NotificationCenter 发送 "ToggleSidebar" 通知以关闭侧边栏

/// 侧边栏视图：对话列表 + 入口
struct SidebarView: View {

    // MARK: - 环境对象
    @EnvironmentObject var conversationStore: ConversationStore

    // MARK: - 视图状态
    /// 是否显示设置页面
    @State private var showSettings: Bool = false

    // MARK: - 主体
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // 标题栏
                    HStack {
                        Text("乘风AI")
                            .font(.headline)
                        Spacer()
                    }
                    .padding()

                    Divider()

                    // 对话列表
                    List {
                        Section("对话列表") {
                            ForEach(conversationStore.conversations.filter { !$0.isArchived }) { conversation in
                                Button {
                                    conversationStore.selectConversation(conversation)
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("ToggleSidebar"),
                                        object: nil
                                    )
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(conversation.title)
                                            .lineLimit(1)
                                        Text(conversation.lastMessageText ?? "暂无消息")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        conversationStore.deleteConversation(conversation)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                            }
                        }

                        Section {
                            Button {
                                let newConv = conversationStore.createConversation(title: "新对话")
                                conversationStore.selectConversation(newConv)
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("ToggleSidebar"),
                                    object: nil
                                )
                            } label: {
                                Label("新建对话", systemImage: "plus")
                            }

                            Button {
                                showSettings = true
                            } label: {
                                Label("设置", systemImage: "gear")
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
                .frame(width: min(geo.size.width * 0.8, 320))
                .background(Color(UIColor.systemBackground))

                Spacer(minLength: 0)
            }
        }
        .background(Color.black.opacity(0.3))
        // 点击空白处关闭侧边栏
        .contentShape(Rectangle())
        .onTapGesture {
            NotificationCenter.default.post(
                name: NSNotification.Name("ToggleSidebar"),
                object: nil
            )
        }
        // 设置页弹层
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

#Preview {
    SidebarView()
        .environmentObject(ConversationStore.shared)
}
