import Foundation

// MARK: - 消息模型
// 用于描述单条聊天消息的基本信息，包含角色、内容、时间戳等

/// 消息角色枚举，区分消息发送方
enum Role: String, Codable, CaseIterable {
    case user       // 用户消息
    case assistant  // AI助手消息
    case system     // 系统消息
}

/// 消息结构体，作为聊天的基本单元
struct Message: Identifiable, Codable {
    // MARK: - 属性
    var id: UUID = UUID()                 // 消息唯一标识符，默认自动生成
    var role: Role = .user                // 消息角色，默认为用户
    var content: String = ""              // 消息文本内容
    var timestamp: Date = Date()          // 消息时间戳，默认为当前时间
    var attachments: [Attachment]? = nil  // 附件列表（可选）
    var tokenCount: Int? = nil            // 估算的token数量（可选）

    // MARK: - 初始化方法
    /// 默认初始化（为Codable解码提供默认值）
    init() {}

    /// 便捷初始化方法
    /// - Parameters:
    ///   - role: 消息角色
    ///   - content: 消息内容
    ///   - attachments: 附件列表
    init(role: Role, content: String, attachments: [Attachment]? = nil) {
        self.role = role
        self.content = content
        self.attachments = attachments
    }
}
