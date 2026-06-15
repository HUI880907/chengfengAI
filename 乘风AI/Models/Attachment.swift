import Foundation

// MARK: - 附件模型
// 用于描述消息中的附件信息，支持文本、图片、PDF、文档等多种类型

/// 附件类型枚举，区分附件文件种类
enum AttachmentType: String, Codable, CaseIterable {
    case text   // 纯文本文件
    case image  // 图片文件
    case pdf    // PDF文档
    case doc    // 其他文档
}

/// 附件结构体，用于保存文件元数据及内容
struct Attachment: Identifiable, Codable, Equatable {
    // MARK: - 属性
    var id: UUID = UUID()                 // 附件唯一标识符
    var type: AttachmentType = .text      // 附件类型，默认为text
    var fileName: String = ""             // 文件名
    var fileData: Data? = nil             // 文件二进制数据（可选，用于小文件）
    var fileURL: String? = nil            // 文件本地路径或URL（可选，用于大文件）
    var size: Int64 = 0                   // 文件大小（字节）
    var thumbnailData: Data? = nil        // 缩略图数据（可选，用于图片/PDF）

    // MARK: - 初始化方法
    /// 默认初始化
    init() {}

    /// 便捷初始化方法
    /// - Parameters:
    ///   - type: 附件类型
    ///   - fileName: 文件名
    ///   - fileData: 文件二进制数据
    ///   - size: 文件大小
    init(type: AttachmentType, fileName: String, fileData: Data? = nil, size: Int64 = 0) {
        self.type = type
        self.fileName = fileName
        self.fileData = fileData
        self.size = size
    }
}
