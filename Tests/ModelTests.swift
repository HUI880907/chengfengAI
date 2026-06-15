// ================================================
// 乘风AI - 模型层单元测试
// 测试范围: Message, Attachment, Conversation, UserProfile 等核心模型
// ================================================

import XCTest
@testable import ChengFengAI

// MARK: - Message 模型测试
final class MessageTests: XCTestCase {
    
    // MARK: 基础创建测试
    func testMessageInitialization() {
        // 默认初始化
        let message = Message()
        XCTAssertNotNil(message.id)
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "")
        XCTAssertNil(message.attachments)
        XCTAssertNil(message.tokenCount)
    }
    
    // MARK: 带参数初始化
    func testMessageWithRoleAndContent() {
        let userMsg = Message(role: .user, content: "你好")
        XCTAssertEqual(userMsg.role, .user)
        XCTAssertEqual(userMsg.content, "你好")
        
        let assistantMsg = Message(role: .assistant, content: "你好！有什么可以帮助你的？")
        XCTAssertEqual(assistantMsg.role, .assistant)
        XCTAssertEqual(assistantMsg.content, "你好！有什么可以帮助你的？")
        
        let systemMsg = Message(role: .system, content: "系统提示")
        XCTAssertEqual(systemMsg.role, .system)
    }
    
    // MARK: 消息唯一ID测试
    func testMessageUniqueIDs() {
        let msg1 = Message(role: .user, content: "消息1")
        let msg2 = Message(role: .assistant, content: "消息2")
        XCTAssertNotEqual(msg1.id, msg2.id, "两条消息应该有不同的ID")
    }
    
    // MARK: Codable 编码解码测试
    func testMessageCodable() throws {
        let original = Message(role: .user, content: "测试编码")
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Message.self, from: data)
        
        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.role, decoded.role)
        XCTAssertEqual(original.content, decoded.content)
    }
    
    // MARK: 带附件的消息测试
    func testMessageWithAttachments() throws {
        let attachment = Attachment(type: .text, fileName: "test.txt")
        let message = Message(role: .user, content: "请看附件", attachments: [attachment])
        
        XCTAssertNotNil(message.attachments)
        XCTAssertEqual(message.attachments?.count, 1)
        XCTAssertEqual(message.attachments?.first?.fileName, "test.txt")
    }
}

// MARK: - Attachment 模型测试
final class AttachmentTests: XCTestCase {
    
    func testAttachmentInitialization() {
        let attachment = Attachment()
        XCTAssertNotNil(attachment.id)
        XCTAssertEqual(attachment.type, .text)
        XCTAssertEqual(attachment.fileName, "")
    }
    
    func testAttachmentWithType() {
        let text = Attachment(type: .text, fileName: "doc.txt")
        XCTAssertEqual(text.type, .text)
        
        let image = Attachment(type: .image, fileName: "photo.jpg")
        XCTAssertEqual(image.type, .image)
        
        let pdf = Attachment(type: .pdf, fileName: "report.pdf")
        XCTAssertEqual(pdf.type, .pdf)
        
        let doc = Attachment(type: .doc, fileName: "file.docx")
        XCTAssertEqual(doc.type, .doc)
    }
    
    func testAttachmentCodable() throws {
        let original = Attachment(type: .image, fileName: "test.jpg")
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Attachment.self, from: data)
        
        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.type, decoded.type)
        XCTAssertEqual(original.fileName, decoded.fileName)
    }
    
    func testAttachmentEquality() {
        let attach1 = Attachment(type: .text, fileName: "a.txt")
        let attach2 = Attachment(type: .text, fileName: "a.txt")
        XCTAssertNotEqual(attach1, attach2, "不同ID的附件即使内容相同也不应相等")
    }
}

// MARK: - Conversation 模型测试
final class ConversationTests: XCTestCase {
    
    func testConversationInitialization() {
        let conv = Conversation()
        XCTAssertNotNil(conv.id)
        XCTAssertEqual(conv.title, "新对话")
        XCTAssertEqual(conv.messages.count, 0)
        XCTAssertFalse(conv.isArchived)
    }
    
    func testConversationWithTitle() {
        let conv = Conversation(title: "测试对话")
        XCTAssertEqual(conv.title, "测试对话")
        XCTAssertEqual(conv.messages.count, 0)
    }
    
    func testConversationAddMessages() {
        var conv = Conversation()
        let msg1 = Message(role: .user, content: "消息1")
        let msg2 = Message(role: .assistant, content: "消息2")
        
        conv.appendMessage(msg1)
        conv.appendMessage(msg2)
        
        XCTAssertEqual(conv.messages.count, 2)
        XCTAssertEqual(conv.messages.first?.content, "消息1")
        XCTAssertEqual(conv.messages.last?.content, "消息2")
    }
    
    func testConversationCodable() throws {
        var original = Conversation(title: "编码测试")
        original.appendMessage(Message(role: .user, content: "测试"))
        original.appendMessage(Message(role: .assistant, content: "回复"))
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Conversation.self, from: data)
        
        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.title, decoded.title)
        XCTAssertEqual(original.messages.count, 2)
    }
    
    func testConversationArchiving() {
        var conv = Conversation(title: "归档测试")
        XCTAssertFalse(conv.isArchived)
        conv.isArchived = true
        XCTAssertTrue(conv.isArchived)
    }
    
    func testConversationResetContext() {
        var conv = Conversation(title: "重置测试")
        conv.appendMessage(Message(role: .user, content: "旧消息"))
        
        XCTAssertEqual(conv.messages.count, 1)
        
        let reset = conv.resetContext()
        // resetContext 保留消息列表作为历史查看，但生成新 ID、新 branchId
        XCTAssertNotEqual(conv.id, reset.id, "重置后的对话应有新ID")
        XCTAssertNotEqual(conv.branchId, reset.branchId, "重置后的对话应有新branchId")
        XCTAssertEqual(reset.totalTokens, 0, "重置后 totalTokens 应为 0")
    }
    
    func testConversationLastMessage() {
        var conv = Conversation()
        XCTAssertNil(conv.messages.last)
        
        let msg = Message(role: .user, content: "最后一条")
        conv.appendMessage(msg)
        
        XCTAssertNotNil(conv.messages.last)
        XCTAssertEqual(conv.messages.last?.content, "最后一条")
    }
}

// MARK: - UserProfile 模型测试
final class UserProfileTests: XCTestCase {
    
    func testProfileDefaults() {
        let profile = UserProfile()
        XCTAssertEqual(profile.nickname, "用户")
        XCTAssertFalse(profile.useCustomNickname)
    }
    
    func testProfileCustomNickname() {
        var profile = UserProfile()
        profile.nickname = "测试用户"
        profile.useCustomNickname = true
        XCTAssertEqual(profile.nickname, "测试用户")
        XCTAssertTrue(profile.useCustomNickname)
    }
    
    func testProfileCodable() throws {
        var original = UserProfile()
        original.nickname = "编码用户"
        original.useCustomNickname = true
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserProfile.self, from: data)
        
        XCTAssertEqual(original.nickname, decoded.nickname)
        XCTAssertEqual(original.useCustomNickname, decoded.useCustomNickname)
    }
}

// MARK: - ModelProvider 测试
final class ModelProviderTests: XCTestCase {
    
    func testProviderTypes() {
        let types = ModelProviderType.allCases
        XCTAssertEqual(types.count, 3, "应该有3种模型提供者类型")
        XCTAssertTrue(types.contains(.qwenCloud))
        XCTAssertTrue(types.contains(.iosLocal))
        XCTAssertTrue(types.contains(.customAPI))
    }
    
    func testProviderIsLocal() {
        XCTAssertTrue(ModelProviderType.iosLocal.isLocal)
        XCTAssertFalse(ModelProviderType.qwenCloud.isLocal)
        XCTAssertFalse(ModelProviderType.customAPI.isLocal)
    }
    
    func testProviderDisplayName() {
        XCTAssertFalse(ModelProviderType.qwenCloud.displayName.isEmpty)
        XCTAssertFalse(ModelProviderType.iosLocal.displayName.isEmpty)
        XCTAssertFalse(ModelProviderType.customAPI.displayName.isEmpty)
    }
    
    func testProviderCodable() throws {
        let original: [ModelProviderType] = [.qwenCloud, .iosLocal, .customAPI]
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([ModelProviderType].self, from: data)
        
        XCTAssertEqual(original, decoded)
    }
}

// MARK: - APICredential 测试
final class APICredentialTests: XCTestCase {
    
    func testCredentialInitialization() {
        let cred = APICredential(provider: "qwen", apiKey: "test-key", baseURL: "https://api.example.com", modelName: "qwen-turbo", isActive: true)
        XCTAssertEqual(cred.provider, "qwen")
        XCTAssertEqual(cred.apiKey, "test-key")
        XCTAssertEqual(cred.baseURL, "https://api.example.com")
        XCTAssertEqual(cred.modelName, "qwen-turbo")
        XCTAssertTrue(cred.isActive)
    }
    
    func testCredentialCodable() throws {
        let original = APICredential(provider: "qwen", apiKey: "test-key", baseURL: "https://api.example.com", modelName: "qwen-turbo", isActive: true)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(APICredential.self, from: data)
        
        XCTAssertEqual(original.provider, decoded.provider)
        XCTAssertEqual(original.apiKey, decoded.apiKey)
        XCTAssertEqual(original.baseURL, decoded.baseURL)
    }
}

// MARK: - 执行测试
extension MessageTests {
    static var allTests = [
        ("testMessageInitialization", testMessageInitialization),
        ("testMessageWithRoleAndContent", testMessageWithRoleAndContent),
        ("testMessageUniqueIDs", testMessageUniqueIDs),
        ("testMessageCodable", testMessageCodable),
        ("testMessageWithAttachments", testMessageWithAttachments)
    ]
}

extension AttachmentTests {
    static var allTests = [
        ("testAttachmentInitialization", testAttachmentInitialization),
        ("testAttachmentWithType", testAttachmentWithType),
        ("testAttachmentCodable", testAttachmentCodable),
        ("testAttachmentEquality", testAttachmentEquality)
    ]
}

extension ConversationTests {
    static var allTests = [
        ("testConversationInitialization", testConversationInitialization),
        ("testConversationWithTitle", testConversationWithTitle),
        ("testConversationAddMessages", testConversationAddMessages),
        ("testConversationCodable", testConversationCodable),
        ("testConversationArchiving", testConversationArchiving),
        ("testConversationResetContext", testConversationResetContext),
        ("testConversationLastMessage", testConversationLastMessage)
    ]
}

extension UserProfileTests {
    static var allTests = [
        ("testProfileDefaults", testProfileDefaults),
        ("testProfileCustomNickname", testProfileCustomNickname),
        ("testProfileCodable", testProfileCodable)
    ]
}

extension ModelProviderTests {
    static var allTests = [
        ("testProviderTypes", testProviderTypes),
        ("testProviderIsLocal", testProviderIsLocal),
        ("testProviderDisplayName", testProviderDisplayName),
        ("testProviderCodable", testProviderCodable)
    ]
}

extension APICredentialTests {
    static var allTests = [
        ("testCredentialInitialization", testCredentialInitialization),
        ("testCredentialCodable", testCredentialCodable)
    ]
}
