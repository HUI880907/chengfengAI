import SwiftUI
import UIKit

// MARK: - 附件缩略图视图
// 根据附件类型渲染图片缩略图或文件卡片
// 当附件数量 > 3 时以 2 列网格展示

/// 附件缩略图视图，支持图片和其他文件类型
struct AttachmentThumbnailView: View {

    // MARK: - 输入
    let attachments: [Attachment]

    // MARK: - 主体
    var body: some View {
        if attachments.count > 3 {
            // 超过3个附件，使用两列网格布局
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 8
            ) {
                ForEach(attachments) { attachment in
                    renderAttachment(attachment)
                }
            }
        } else {
            // 3 个及以下附件，纵向排列
            VStack(alignment: .leading, spacing: 8) {
                ForEach(attachments) { attachment in
                    renderAttachment(attachment)
                }
            }
        }
    }

    // MARK: - 单个附件渲染
    /// 根据附件类型渲染图片或文件卡片
    @ViewBuilder
    private func renderAttachment(_ attachment: Attachment) -> some View {
        if attachment.type == .image,
           let data = attachment.thumbnailData ?? attachment.fileData,
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 120)
                .cornerRadius(8)
        } else {
            // 非图片类型：文件卡片
            HStack(spacing: 8) {
                Image(systemName: icon(for: attachment.type))
                    .foregroundColor(.secondary)
                Text(attachment.fileName.isEmpty ? "未命名文件" : attachment.fileName)
                    .font(.footnote)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                Spacer(minLength: 8)
                if attachment.size > 0 {
                    Text(byteCountFormatter.string(fromByteCount: attachment.size))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
    }

    // MARK: - 图标映射
    private func icon(for type: AttachmentType) -> String {
        switch type {
        case .image: return "photo"
        case .pdf: return "doc.richtext"
        case .doc: return "doc.fill"
        case .text: return "doc.text"
        }
    }

    // MARK: - 字节数格式化器
    private let byteCountFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f
    }()
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        AttachmentThumbnailView(attachments: [
            Attachment(type: .text, fileName: "readme.txt", fileData: nil, size: 1024),
            Attachment(type: .pdf, fileName: "demo.pdf", fileData: nil, size: 20480)
        ])
    }
    .padding()
}
