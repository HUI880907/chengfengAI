import Foundation

// MARK: - 对话模型
// 用于描述一次完整的聊天会话，包含多条消息以及对话元数据

/// 对话结构体，作为聊天会话的顶层容器
struct Conversation: Identifiable, Codable {
    // MARK: - 属性
    var id: UUID = UUID()              // 对话唯一标识符
    var title: String = "新对话"        // 对话标题
    var messages: [Message] = []       // 消息列表
    var createdAt: Date = Date()       // 创建时间
    var updatedAt: Date = Date()       // 最后更新时间
    var isArchived: Bool = false       // 是否已归档
    var branchId: String? = nil        // 分支ID（用于对话分叉，可选）
    var totalTokens: Int = 0           // 累计token数
    var tag: String? = nil             // 标签（可选，用于分类）

    // MARK: - 初始化方法
    /// 默认初始化
    init() {}

    /// 便捷初始化方法
    /// - Parameter title: 对话标题
    init(title: String) {
        self.title = title
    }

    // MARK: - 方法

    /// 追加一条消息到对话
    /// - Parameter message: 要追加的消息
    mutating func appendMessage(_ message: Message) {
        messages.append(message)
        updatedAt = Date()  // 更新最后修改时间
    }

    /// 返回对话最后一条消息的文本内容（用于侧边栏预览）
    var lastMessageText: String? {
        messages.last?.content
    }

    /// 重置上下文：返回一个新的Conversation，保留messages但标记为上下文重置
    /// - Returns: 新的对话实例，清空totalTokens并重新生成branchId标识新的上下文
    func resetContext() -> Conversation {
        var newConversation = self
        // 重新生成对话ID，以便与原对话区分
        newConversation.id = UUID()
        // 保留消息列表（用于历史查看）
        // newConversation.messages = self.messages
        // 清空token计数，表示从这里开始新的上下文
        newConversation.totalTokens = 0
        // 生成新的branchId，表示这是一个新的上下文分支
        newConversation.branchId = UUID().uuidString
        // 更新时间
        newConversation.createdAt = Date()
        newConversation.updatedAt = Date()
        // 标题添加"（上下文已重置）"标记
        newConversation.title = title + "（上下文已重置）"
        return newConversation
    }
}
