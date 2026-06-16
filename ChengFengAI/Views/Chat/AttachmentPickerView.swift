import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - 附件选择器视图
// 提供三种附件添加方式：图片（相册）、文件（文件选择器）、文本片段（粘贴输入）
// 添加成功后将附件绑定到当前活动对话的最新消息或直接追加一个带附件的消息

/// 附件选择器视图
struct AttachmentPickerView: View {

    // MARK: - 环境
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var conversationStore: ConversationStore

    // MARK: - 视图状态
    /// 是否显示图片选择器
    @State private var showImagePicker: Bool = false
    /// 是否显示文件选择器
    @State private var showFilePicker: Bool = false
    /// 是否显示文本输入框
    @State private var showTextInput: Bool = false
    /// 文本输入内容
    @State private var plainTextInput: String = ""

    // MARK: - 主体
    var body: some View {
        NavigationStack {
            Form {
                Section("选择附件类型") {
                    Button {
                        showImagePicker = true
                    } label: {
                        HStack {
                            Label("图片", systemImage: "photo")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)

                    Button {
                        showFilePicker = true
                    } label: {
                        HStack {
                            Label("文件", systemImage: "folder")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)

                    Button {
                        showTextInput = true
                    } label: {
                        HStack {
                            Label("文本片段", systemImage: "doc.text")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                Section("说明") {
                    Text("支持上传图片/PDF/文档到千问 API 进行分析。大批量文件（>10 个 或 >50MB）会自动切换至本地模型以减少云端传输耗时。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("添加附件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            // 图片选择器
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: .photoLibrary) { image in
                    handleImage(image)
                }
                .ignoresSafeArea()
            }
            // 文件选择器
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf, .plainText, .png, .jpeg],
                allowsMultipleSelection: true
            ) { result in
                handleFiles(result)
            }
            // 文本输入弹框
            .alert("粘贴文本", isPresented: $showTextInput) {
                TextField("粘贴文本内容", text: $plainTextInput, axis: .vertical)
                    .lineLimit(1...20)
                Button("添加") {
                    handleText(plainTextInput)
                    plainTextInput = ""
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("添加一段纯文本作为对话附件，便于模型引用。")
            }
        }
    }

    // MARK: - 图片处理
    /// 将选取的图片压缩为 JPEG 并作为 Attachment 添加到当前对话的最新消息
    private func handleImage(_ image: UIImage) {
        // 压缩质量 0.7
        guard let data = image.jpegData(compressionQuality: 0.7) else { return }

        // 生成一个缩略图
        let thumbnailData: Data? = {
            let size = CGSize(width: 200, height: 200)
            UIGraphicsBeginImageContext(size)
            image.draw(in: CGRect(origin: .zero, size: size))
            let thumb = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return thumb?.jpegData(compressionQuality: 0.5)
        }()

        let fileName = "IMG_\(Date().timeIntervalSince1970).jpg"
        var attachment = Attachment(
            type: .image,
            fileName: fileName,
            fileData: data,
            size: Int64(data.count)
        )
        attachment.thumbnailData = thumbnailData

        conversationStore.appendAttachment(attachment)
        dismiss()
    }

    // MARK: - 文件处理
    /// 读取文件内容，根据扩展名判断类型，创建 Attachment
    private func handleFiles(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                // 请求访问权限
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }

                do {
                    let data = try Data(contentsOf: url)
                    let ext = url.pathExtension.lowercased()
                    let type: AttachmentType
                    switch ext {
                    case "png", "jpg", "jpeg", "heic":
                        type = .image
                    case "pdf":
                        type = .pdf
                    case "txt", "md":
                        type = .text
                    default:
                        type = .doc
                    }
                    var attachment = Attachment(
                        type: type,
                        fileName: url.lastPathComponent,
                        fileData: data,
                        size: Int64(data.count)
                    )
                    // 图片类顺便生成缩略图
                    if type == .image, let uiImage = UIImage(data: data) {
                        UIGraphicsBeginImageContext(CGSize(width: 200, height: 200))
                        uiImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
                        let thumb = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        attachment.thumbnailData = thumb?.jpegData(compressionQuality: 0.5)
                    }
                    conversationStore.appendAttachment(attachment)
                } catch {
                    print("⚠️ 读取文件失败: \(error.localizedDescription)")
                }
            }
            dismiss()
        case .failure(let error):
            print("⚠️ 文件选择失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 文本处理
    /// 将纯文本创建为 text 类型 Attachment
    private func handleText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let data = trimmed.data(using: .utf8) ?? Data()
        let attachment = Attachment(
            type: .text,
            fileName: "文本片段_\(Date().timeIntervalSince1970).txt",
            fileData: data,
            size: Int64(data.count)
        )
        conversationStore.appendAttachment(attachment)
        dismiss()
    }
}

#Preview {
    AttachmentPickerView()
        .environmentObject(ConversationStore.shared)
}
