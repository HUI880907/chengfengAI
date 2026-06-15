import SwiftUI
import UIKit

// MARK: - 聊天输入栏视图
// 负责输入文本、发送消息、展示加载状态与模型切换提示
// 通过 Task + async/await 异步调用模型调度器，成功/失败后更新对话

/// 聊天输入栏，包含附件按钮、重置上下文按钮、文本输入框、发送按钮与加载提示
struct ChatInputBarView: View {

    // MARK: - Binding
    @Binding var inputText: String
    @Binding var showAttachmentPicker: Bool
    @Binding var showResetAlert: Bool

    // MARK: - 环境对象
    @EnvironmentObject var conversationStore: ConversationStore
    @EnvironmentObject var modelScheduler: ModelScheduler

    // MARK: - 主体
    var body: some View {
        VStack(spacing: 8) {
            // 模型切换提示（当 providerSwitched 为 true 时展示，点击发送后重置）
            if modelScheduler.providerSwitched {
                HStack {
                    Image(systemName: "info.circle")
                    Text("已切换至本地模型")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
            }

            // 主输入行
            HStack(spacing: 8) {
                // 附件按钮
                Button {
                    showAttachmentPicker.toggle()
                } label: {
                    Image(systemName: "paperclip")
                        .font(.title3)
                }
                .buttonStyle(.plain)

                // 重置上下文按钮
                Button {
                    showResetAlert.toggle()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.title3)
                }
                .buttonStyle(.plain)

                // 文本输入框（支持多行，1~5 行）
                TextField("输入消息...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)

                // 发送按钮
                Button(action: sendMessage) {
                    if modelScheduler.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                    }
                }
                .buttonStyle(.plain)
                // 输入为空或正在加载时禁用
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || modelScheduler.isLoading)
            }
            .padding(.horizontal, 12)

            // 加载中的思考提示
            if modelScheduler.isLoading {
                HStack {
                    ProgressView()
                    Text("正在思考...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 发送消息逻辑
    /// 发送消息：先追加用户消息，再异步调用模型并追加 AI 回复
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        // 追加用户消息
        let userMsg = Message(role: .user, content: text)
        conversationStore.appendMessage(userMsg)
        // 清空输入
        inputText = ""
        // 重置模型切换提示（发送新消息时清除）
        modelScheduler.providerSwitched = false

        // 异步请求模型回复
        Task {
            do {
                let messages = conversationStore.activeConversation?.messages ?? []
                let response = try await modelScheduler.sendToModel(messages: messages)
                let assistantMsg = Message(role: .assistant, content: response)
                await MainActor.run {
                    conversationStore.appendMessage(assistantMsg)
                }
            } catch {
                await MainActor.run {
                    let errorMsg = Message(role: .assistant, content: "出错: \(error.localizedDescription)")
                    conversationStore.appendMessage(errorMsg)
                }
            }
        }
    }
}

#Preview {
    ChatInputBarView(
        inputText: .constant(""),
        showAttachmentPicker: .constant(false),
        showResetAlert: .constant(false)
    )
    .environmentObject(ConversationStore.shared)
    .environmentObject(ModelScheduler(
        apiClient: QwenAPIClient(apiKey: ""),
        localModel: IOSLocalModelService()
    ))
}
