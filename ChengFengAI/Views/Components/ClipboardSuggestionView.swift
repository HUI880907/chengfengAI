import SwiftUI

// MARK: - 剪贴板新内容提示条
// 当剪贴板有新内容时展示，用户可点击"提问"直接发送，或点击"×"忽略

/// 剪贴板提示视图
struct ClipboardSuggestionView: View {

    // MARK: - 环境对象

    /// 剪贴板服务
    @EnvironmentObject var clipboardService: ClipboardService

    /// 对话存储服务，用于追加消息
    @EnvironmentObject var conversationStore: ConversationStore

    /// 快捷提问服务，用于生成建议的提问词
    @EnvironmentObject var quickPromptService: QuickPromptService

    // MARK: - 视图主体

    var body: some View {
        if clipboardService.hasNewContent {
            HStack(alignment: .center, spacing: 8) {
                // 文本分支
                if let text = clipboardService.clipboardText {
                    Image(systemName: "doc.text")
                        .foregroundColor(.orange)
                    Text("检测到剪贴板文本")
                        .font(.caption)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Button(action: { useClipboardTextAsPrompt(text) }) {
                        Text(quickPromptService.promptForClipboardText(text))
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.accentColor)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    Button(action: { clipboardService.markAsRead() }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                // 图片分支
                else if clipboardService.clipboardImage != nil {
                    Image(systemName: "photo")
                        .foregroundColor(.orange)
                    Text("检测到剪贴板图片")
                        .font(.caption)
                    Spacer(minLength: 8)
                    Button(action: { clipboardService.markAsRead() }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }

    // MARK: - 行为方法

    /// 将剪贴板文本作为用户提问，追加到当前对话
    /// - Parameter text: 剪贴板文本内容
    private func useClipboardTextAsPrompt(_ text: String) {
        let prompt = quickPromptService.promptForClipboardText(text)
        let combined = "\(prompt)\n\n\(text)"
        var message = Message(role: .user, content: combined)
        message.id = UUID()
        message.timestamp = Date()
        if var conversation = conversationStore.activeConversation {
            conversation.messages.append(message)
            conversationStore.updateConversation(conversation)
        }
        clipboardService.markAsRead()
    }
}
