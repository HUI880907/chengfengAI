import Foundation
import SwiftUI
import Combine

// MARK: - 对话存储器
// 负责对话数据的加载/保存/增删改查，使用文件系统存储JSON

@MainActor
class ConversationStore: ObservableObject {
    // MARK: - 单例
    static let shared = ConversationStore()

    // MARK: - @Published属性
    // 使用private(set)限制外部修改，保证只能通过内部方法变更
    @Published private(set) var conversations: [Conversation] = []
    @Published private(set) var activeConversation: Conversation?

    // MARK: - 常量
    private let fileName: String = "conversations.json"  // 存储文件名

    // MARK: - 初始化方法
    private init() {
        loadConversations()
    }

    // MARK: - 文件路径

    /// 返回对话存储文件的URL（Documents目录下）
    /// - Returns: 文件URL
    func fileURL() -> URL {
        // 获取Documents目录路径
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent(fileName)
    }

    // MARK: - 加载与保存

    /// 从Documents目录的JSON文件加载对话列表
    func loadConversations() {
        let url = fileURL()
        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: url.path) else {
            conversations = []
            return
        }
        do {
            // 读取并解码JSON数据
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            // 设置日期解码策略（兼容ISO8601格式）
            decoder.dateDecodingStrategy = .iso8601
            conversations = try decoder.decode([Conversation].self, from: data)
        } catch {
            // 解码失败时打印错误并保持空列表
            print("⚠️ 加载对话失败: \(error.localizedDescription)")
            conversations = []
        }
    }

    /// 将当前对话列表保存到Documents目录的JSON文件
    func saveConversations() {
        let url = fileURL()
        do {
            let encoder = JSONEncoder()
            // 使用ISO8601日期格式，输出美观的JSON
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(conversations)
            try data.write(to: url, options: .atomic)
        } catch {
            print("⚠️ 保存对话失败: \(error.localizedDescription)")
        }
    }

    // MARK: - CRUD操作

    /// 创建一个新对话并加入到对话列表
    /// - Parameter title: 对话标题
    /// - Returns: 新创建的对话实例
    @discardableResult
    func createConversation(title: String) -> Conversation {
        var conversation = Conversation(title: title)
        // 填充默认值
        conversation.id = UUID()
        conversation.createdAt = Date()
        conversation.updatedAt = Date()
        conversations.insert(conversation, at: 0)  // 新对话插入在最前面
        saveConversations()
        return conversation
    }

    /// 删除指定对话
    /// - Parameter conversation: 要删除的对话
    func deleteConversation(_ conversation: Conversation) {
        conversations.removeAll { $0.id == conversation.id }
        // 若正在查看该对话，则清空activeConversation
        if activeConversation?.id == conversation.id {
            activeConversation = nil
        }
        saveConversations()
    }

    /// 归档/取消归档指定对话
    /// - Parameter conversation: 要切换归档状态的对话
    func archiveConversation(_ conversation: Conversation) {
        // 找到对应对话并切换isArchived
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index].isArchived.toggle()
            conversations[index].updatedAt = Date()
            saveConversations()
        }
    }

    /// 更新对话内容（替换旧的对话实例）
    /// - Parameter conversation: 更新后的对话
    func updateConversation(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            var updated = conversation
            updated.updatedAt = Date()
            conversations[index] = updated
            // 同步更新activeConversation
            if activeConversation?.id == conversation.id {
                activeConversation = updated
            }
            saveConversations()
        }
    }

    /// 选择当前激活的对话
    /// - Parameter conversation: 要激活的对话（nil表示不激活任何对话）
    func selectConversation(_ conversation: Conversation?) {
        activeConversation = conversation
    }

    /// 向当前激活对话的最后一条用户消息添加附件；若不存在用户消息则创建新消息
    /// - Parameter attachment: 要添加的附件
    func appendAttachment(_ attachment: Attachment) {
        var conversation = activeConversation ?? createConversation(title: "新对话")

        if let index = conversation.messages.lastIndex(where: { $0.role == .user }) {
            var message = conversation.messages[index]
            if message.attachments == nil {
                message.attachments = [attachment]
            } else {
                message.attachments?.append(attachment)
            }
            conversation.messages[index] = message
        } else {
            conversation.appendMessage(Message(role: .user, content: "", attachments: [attachment]))
        }

        updateConversation(conversation)
    }
}
