import SwiftUI
import UniformTypeIdentifiers

// MARK: - 导出面板视图
// 提供从当前对话导出为 纯文本 / Markdown / 长截图 的入口

struct ExportPanelView: View {

    // MARK: - 属性

    /// 需要导出的对话
    let conversation: Conversation

    /// 用于关闭当前 sheet
    @Environment(\.dismiss) private var dismiss

    /// 导出进度状态（用于禁用按钮，避免重复点击）
    @State private var isExporting: Bool = false

    /// 是否显示分享面板
    @State private var showActivityView: Bool = false

    /// 待分享的文件 URL（导出后写入 Documents/temp）
    @State private var exportURL: URL?

    // MARK: - 主体

    var body: some View {
        NavigationStack {
            Form {
                Section("导出格式") {
                    Button {
                        exportFile(as: "txt", type: .plainText)
                    } label: {
                        Label("导出为纯文本", systemImage: "doc.text")
                    }
                    .disabled(isExporting)

                    Button {
                        exportFile(as: "md", type: .plainText)
                    } label: {
                        Label("导出为 Markdown", systemImage: "doc.plaintext")
                    }
                    .disabled(isExporting)

                    Button {
                        exportScreenshot()
                    } label: {
                        Label("导出为长截图", systemImage: "photo")
                    }
                    .disabled(isExporting)
                }

                Section("说明") {
                    Text("导出后会弹出分享面板，可保存到文件、分享到其他 App。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("导出对话")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showActivityView) {
                if let url = exportURL {
                    ActivityView(activityItems: [url])
                }
            }
        }
    }

    // MARK: - 方法

    /// 导出为文本文件（txt / md），写入临时目录并弹出分享面板
    /// - Parameters:
    ///   - ext: 文件扩展名
    ///   - type: 文件 UTType（用于系统识别）
    func exportFile(as ext: String, type: UTType) {
        isExporting = true

        let content: String
        let filename: String

        switch ext {
        case "md":
            content = ExportService.shared.exportToMarkdown(conversation: conversation)
            filename = conversation.title
        default:
            content = ExportService.shared.exportToText(conversation: conversation)
            filename = conversation.title
        }

        if let url = ExportService.shared.saveFile(content, filename: filename, type: type) {
            self.exportURL = url
            self.showActivityView = true
        }

        isExporting = false
    }

    /// 导出为长截图（使用 SwiftUI 预览视图 + ImageRenderer）
    func exportScreenshot() {
        isExporting = true

        // 构造一个简洁的 SwiftUI 预览视图，按消息顺序绘制
        let previewView = ConversationScreenshotView(conversation: conversation)
            .frame(width: UIScreen.main.bounds.width - 32)

        ExportService.shared.exportToScreenshot(view: previewView) { image in
            if let image = image,
               let url = ExportService.shared.saveImage(image, filename: conversation.title) {
                self.exportURL = url
                self.showActivityView = true
            }
            self.isExporting = false
        }
    }
}

// MARK: - 辅助预览视图（用于长截图）

/// 作为长截图渲染源的简洁聊天预览
struct ConversationScreenshotView: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(conversation.title)
                .font(.headline)
                .padding(.bottom, 4)

            ForEach(conversation.messages) { message in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(roleLabel(for: message.role))
                            .font(.footnote)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(message.timestamp.formattedString())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Text(message.content)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)

                    if let attachments = message.attachments, !attachments.isEmpty {
                        ForEach(attachments) { attachment in
                            Text("[附件: \(attachment.fileName)]")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(message.role == .user
                    ? Color.blue.opacity(0.15)
                    : Color.gray.opacity(0.08))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
    }

    private func roleLabel(for role: Role) -> String {
        switch role {
        case .user: return "用户"
        case .assistant: return "AI 助手"
        case .system: return "系统"
        }
    }
}
