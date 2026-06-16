import SwiftUI
import UIKit

// MARK: - 单条消息气泡视图
// 负责根据消息角色（user / assistant / system）显示不同样式的气泡
// 提供长按后的操作：复制、朗读、分享
// 支持附件缩略图，当附件数量超过3个时以网格形式展示

/// 单条消息气泡视图
struct MessageBubbleView: View {

    // MARK: - 输入
    let message: Message

    // MARK: - 环境对象
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var speechService: SpeechService

    // MARK: - 视图状态
    /// 复制成功提示
    @State private var isCopied: Bool = false
    /// 是否展示附件预览（使用 QuickLook 的简单替换）
    @State private var showAttachmentPreview: Bool = false
    /// 是否展示系统分享面板
    @State private var showShareSheet: Bool = false

    // MARK: - 计算属性：气泡对齐方式
    private var isUser: Bool { message.role == .user }
    private var isSystem: Bool { message.role == .system }

    /// 发送者显示名
    private var senderName: String {
        switch message.role {
        case .user:
            return settingsStore.settings.profile.useCustomNickname
                ? settingsStore.settings.profile.nickname.isEmpty ? "用户" : settingsStore.settings.profile.nickname
                : "用户"
        case .assistant:
            return "AI助手"
        case .system:
            return "系统"
        }
    }

    // MARK: - 主体
    var body: some View {
        // 根据角色决定对齐方式
        // 用户消息右对齐，AI 助手左对齐，系统消息居中
        HStack {
            if isUser { Spacer() }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                // 发送者名称
                Text(senderName)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // 系统消息：居中、浅色小字
                if isSystem {
                    Text(message.content)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                } else {
                    // 非系统消息气泡
                    VStack(alignment: .leading, spacing: 6) {
                        // 附件缩略图
                        if let attachments = message.attachments, !attachments.isEmpty {
                            AttachmentThumbnailView(attachments: attachments)
                        }
                        // 消息文本
                        Text(message.content)
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(bubbleBackgroundColor)
                    .foregroundColor(bubbleForegroundColor)
                    .cornerRadius(12)
                    .contextMenu {
                        // 复制
                        Button {
                            UIPasteboard.general.string = message.content
                            withAnimation { isCopied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                isCopied = false
                            }
                        } label: {
                            Label("复制", systemImage: "doc.on.doc")
                        }

                        // 朗读
                        Button {
                            speechService.speak(message.content)
                        } label: {
                            Label("朗读", systemImage: "speaker.wave.2.fill")
                        }

                        // 分享
                        Button {
                            showShareSheet = true
                        } label: {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }
                    }
                    // 长按手势也可以触发自定义操作
                    .overlay(
                        // 复制成功提示
                        isCopied ?
                            Text("已复制")
                                .font(.caption)
                                .padding(4)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                                .padding(.bottom, -32)
                        : nil,
                        alignment: .bottom
                    )
                }

                // 底部可选：功能按钮（仅 user 与 assistant 显示）
                if !isSystem {
                    HStack(spacing: 12) {
                        // 复制
                        Button {
                            UIPasteboard.general.string = message.content
                        } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.plain)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // 朗读 / 停止
                        Button {
                            if speechService.isSpeaking {
                                speechService.stop()
                            } else {
                                speechService.speak(message.content)
                            }
                        } label: {
                            Image(systemName: speechService.isSpeaking ? "stop.circle" : "speaker.wave.2.fill")
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundColor(.secondary)

                        // 分享
                        Button {
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.78, alignment: isUser ? .trailing : .leading)

            if !isUser { Spacer() }
        }
        // 分享面板
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [message.content])
        }
    }

    // MARK: - 气泡颜色
    private var bubbleBackgroundColor: Color {
        isUser ? Color.blue : Color(.secondarySystemBackground)
    }

    private var bubbleForegroundColor: Color {
        isUser ? Color.white : Color.primary
    }
}

#Preview {
    VStack {
        MessageBubbleView(message: Message(role: .user, content: "你好，这是一段测试消息"))
        MessageBubbleView(message: Message(role: .assistant, content: "你好！这是来自 AI 助手的回复。"))
        MessageBubbleView(message: Message(role: .system, content: "系统提示示例"))
    }
    .environmentObject(SettingsStore.shared)
    .environmentObject(SpeechService())
    .padding()
}
