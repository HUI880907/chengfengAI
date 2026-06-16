import Foundation
import UIKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - 导出服务
// 提供将对话导出为文本、Markdown、长截图的能力，并辅助文件保存
//
// iOS 16+：使用 ImageRenderer 渲染 SwiftUI 视图为 UIImage
// 文件写入：写入 Documents/temp 目录，以便 UIActivityViewController 分享

class ExportService {

    // MARK: - 单例

    static let shared = ExportService()

    private init() {}

    // MARK: - 导出为纯文本

    /// 将对话导出为纯文本字符串
    /// - Parameter conversation: 需要导出的对话
    /// - Returns: 格式化后的纯文本内容
    func exportToText(conversation: Conversation) -> String {
        var output = "=== 对话: \(conversation.title) ==="
        output += "\n创建时间: \(conversation.createdAt.formattedString())"
        output += "\n最后更新: \(conversation.updatedAt.formattedString())"
        output += "\n消息总数: \(conversation.messages.count)\n\n"

        for message in conversation.messages {
            let roleText = (message.role == .user) ? "【用户】"
                         : (message.role == .assistant) ? "【AI】"
                         : "【系统】"
            let timeText = message.timestamp.formattedString()
            output += "\(roleText) \(timeText): \(message.content)\n"

            if let attachments = message.attachments, !attachments.isEmpty {
                for attachment in attachments {
                    output += "    [附件: \(attachment.fileName)]\n"
                }
            }
            output += "\n"
        }

        return output
    }

    // MARK: - 导出为 Markdown

    /// 将对话导出为 Markdown 字符串
    /// - Parameter conversation: 需要导出的对话
    /// - Returns: Markdown 格式的内容
    func exportToMarkdown(conversation: Conversation) -> String {
        var output = "# \(conversation.title)\n\n"
        output += "**创建时间**: \(conversation.createdAt.formattedString())  \n"
        output += "**最后更新**: \(conversation.updatedAt.formattedString())  \n"
        output += "**消息总数**: \(conversation.messages.count)\n\n"
        output += "---\n\n"

        for message in conversation.messages {
            let roleText = (message.role == .user) ? "用户"
                         : (message.role == .assistant) ? "AI 助手"
                         : "系统"
            let timeText = message.timestamp.formattedString()

            output += "> **\(roleText)** (\(timeText)):\n>\n"
            // 将多行内容中的每一行前加 "> " 前缀，保持 blockquote 格式
            let contentLines = message.content.components(separatedBy: .newlines)
            for line in contentLines {
                output += "> \(line)\n"
            }

            if let attachments = message.attachments, !attachments.isEmpty {
                for attachment in attachments {
                    output += "> \n> [附件: \(attachment.fileName)]\n"
                }
            }

            output += "\n"
        }

        return output
    }

    // MARK: - 导出为长截图（UIImage）

    /// 使用 ImageRenderer 将 SwiftUI 视图渲染为 UIImage（iOS 16+）
    /// - Parameters:
    ///   - view: 需要渲染的 SwiftUI 视图
    ///   - completion: 渲染完成回调，返回 UIImage（可选）
    @MainActor
    func exportToScreenshot<Content: View>(view: Content,
                                           completion: @escaping (UIImage?) -> Void) {
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: view)
            // 优先使用 3.0 缩放以获得清晰图像
            renderer.scale = UIScreen.main.scale
            if let image = renderer.uiImage {
                completion(image)
            } else {
                completion(nil)
            }
        } else {
            // iOS 16 以下不支持 ImageRenderer，返回 nil 由调用方降级
            completion(nil)
        }
    }

    // MARK: - 保存文件

    /// 将字符串内容写入临时文件，返回文件 URL 供分享
    /// - Parameters:
    ///   - content: 需要保存的字符串内容
    ///   - filename: 文件名（不含扩展名时由 type 推断）
    ///   - type: 文件的 UTType（决定扩展名及系统识别）
    /// - Returns: 写入后的文件 URL；失败返回 nil
    func saveFile(_ content: String, filename: String, type: UTType) -> URL? {
        let fileManager = FileManager.default

        do {
            // 1. 获取 Documents 目录
            let documentsDir = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )

            // 2. 在 Documents 下创建 temp 子目录（便于后续清理）
            let tempDir = documentsDir.appendingPathComponent("temp", isDirectory: true)
            if !fileManager.fileExists(atPath: tempDir.path) {
                try fileManager.createDirectory(
                    at: tempDir,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }

            // 3. 构造最终的文件 URL
            let fileExtension = type.preferredFilenameExtension ?? "txt"
            let finalFilename = filename.appendingTimestamp()
            let fileURL = tempDir.appendingPathComponent(finalFilename)
                                    .appendingPathExtension(fileExtension)

            // 4. 写入文件（以 UTF-8 编码）
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("⚠️ 保存文件失败: \(error.localizedDescription)")
            return nil
        }
    }

    /// 保存 UIImage 为 PNG 文件到 temp 目录
    /// - Parameters:
    ///   - image: 需要保存的图像
    ///   - filename: 文件名（不含扩展名）
    /// - Returns: 文件 URL；失败返回 nil
    func saveImage(_ image: UIImage, filename: String) -> URL? {
        let fileManager = FileManager.default

        do {
            let documentsDir = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let tempDir = documentsDir.appendingPathComponent("temp", isDirectory: true)
            if !fileManager.fileExists(atPath: tempDir.path) {
                try fileManager.createDirectory(
                    at: tempDir,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }

            let finalFilename = filename.appendingTimestamp()
            let fileURL = tempDir.appendingPathComponent(finalFilename)
                                    .appendingPathExtension("png")

            if let pngData = image.pngData() {
                try pngData.write(to: fileURL, options: .atomic)
                return fileURL
            } else {
                return nil
            }
        } catch {
            print("⚠️ 保存图像失败: \(error.localizedDescription)")
            return nil
        }
    }
}
