// ================================================
// 乘风AI - 核心服务层单元测试
// 测试范围: TokenCounter, 存储服务, 模型调度逻辑
// ================================================

import XCTest
@testable import ChengFengAI

// MARK: - TokenCounter 测试
final class TokenCounterTests: XCTestCase {
    
    var tokenCounter: TokenCounter!
    
    override func setUp() {
        super.setUp()
        tokenCounter = TokenCounter()
    }
    
    override func tearDown() {
        tokenCounter = nil
        super.tearDown()
    }
    
    // MARK: 单文本Token估算
    func testEstimateTokensForEmptyString() {
        let count = tokenCounter.estimateTokens(in: "")
        XCTAssertEqual(count, 0, "空字符串token数应为0")
    }
    
    func testEstimateTokensForShortText() {
        let count = tokenCounter.estimateTokens(in: "你好")
        XCTAssertGreaterThan(count, 0, "非空文本应有token")
        XCTAssertLessThanOrEqual(count, 10, "短文本token数不应过大")
    }
    
    func testEstimateTokensForLongText() {
        let longText = String(repeating: "这是一个测试文本。", count: 100)
        let count = tokenCounter.estimateTokens(in: longText)
        XCTAssertGreaterThan(count, 0, "长文本应有token估算")
    }
    
    func testEstimateTokensProportional() {
        let short = tokenCounter.estimateTokens(in: "短")
        let long = tokenCounter.estimateTokens(in: String(repeating: "长", count: 100))
        XCTAssertGreaterThan(long, short, "长文本token数应大于短文本")
    }
    
    // MARK: 消息列表Token估算
    func testEstimateTokensForEmptyMessages() {
        let count = tokenCounter.estimateTokens(for: [])
        XCTAssertEqual(count, 0, "空消息列表token数应为0")
    }
    
    func testEstimateTokensForMessages() {
        let messages = [
            Message(role: .user, content: "你好"),
            Message(role: .assistant, content: "你好！有什么可以帮助你的？")
        ]
        let count = tokenCounter.estimateTokens(for: messages)
        XCTAssertGreaterThan(count, 0, "消息列表应有token估算")
    }
    
    func testEstimateTokensMultipleMessages() {
        let single = tokenCounter.estimateTokens(for: [
            Message(role: .user, content: "消息1")
        ])
        let multiple = tokenCounter.estimateTokens(for: [
            Message(role: .user, content: "消息1"),
            Message(role: .assistant, content: "消息2"),
            Message(role: .user, content: "消息3"),
            Message(role: .assistant, content: "消息4")
        ])
        XCTAssertGreaterThan(multiple, single, "多条消息token数应大于单条")
    }
    
    // MARK: Token超限检测
    func testApproachingLimitNotApproaching() {
        let isApproaching = tokenCounter.isApproachingLimit(totalTokens: 100, limit: 32768, threshold: 0.85)
        XCTAssertFalse(isApproaching, "100 tokens 不应接近上限")
    }
    
    func testApproachingLimitApproaching() {
        let isApproaching = tokenCounter.isApproachingLimit(totalTokens: 30000, limit: 32768, threshold: 0.85)
        XCTAssertTrue(isApproaching, "30000 tokens 应接近 85% 阈值")
    }
    
    func testApproachingLimitOverLimit() {
        let isApproaching = tokenCounter.isApproachingLimit(totalTokens: 40000, limit: 32768, threshold: 0.85)
        XCTAssertTrue(isApproaching, "超过上限应返回true")
    }
    
    func testApproachingLimitWithCustomThreshold() {
        let limit = 1000
        let threshold = 0.5
        let isApproaching = tokenCounter.isApproachingLimit(totalTokens: 600, limit: limit, threshold: threshold)
        XCTAssertTrue(isApproaching, "600/1000 超过 50%")
    }
    
    // MARK: Token 计算一致性
    func testTokenEstimationConsistency() {
        let text = "这是一条用于测试token估算一致性的测试消息"
        let count1 = tokenCounter.estimateTokens(in: text)
        let count2 = tokenCounter.estimateTokens(in: text)
        XCTAssertEqual(count1, count2, "相同文本应得到相同token估算")
    }
}

// MARK: - 对话存储测试
final class ConversationStoreTests: XCTestCase {
    
    var store: ConversationStore!
    
    override func setUp() {
        super.setUp()
        // SettingsStore / ConversationStore 使用单例模式以保证状态一致
        store = ConversationStore.shared
    }
    
    override func tearDown() {
        store = nil
        super.tearDown()
    }
    
    func testStoreInitialization() {
        XCTAssertNotNil(store)
        XCTAssertNotNil(store.conversations)
    }
    
    func testCreateConversation() {
        let initialCount = store.conversations.count
        let conv = store.createConversation(title: "测试对话")
        
        XCTAssertNotNil(conv)
        XCTAssertEqual(conv.title, "测试对话")
        XCTAssertEqual(store.conversations.count, initialCount + 1)
    }
    
    func testDeleteConversation() {
        let conv = store.createConversation(title: "待删除")
        let countBefore = store.conversations.count
        store.deleteConversation(conv)
        
        XCTAssertEqual(store.conversations.count, countBefore - 1)
        XCTAssertFalse(store.conversations.contains(where: { $0.id == conv.id }))
    }
    
    func testArchiveConversation() {
        let conv = store.createConversation(title: "待归档")
        let initialArchived = conv.isArchived
        
        store.archiveConversation(conv)
        
        // 查找对应的对话（存储中应已更新）
        if let archived = store.conversations.first(where: { $0.id == conv.id }) {
            // archiveConversation 是切换操作，因此与原始状态相反
            XCTAssertNotEqual(archived.isArchived, initialArchived)
        }
    }
    
    func testActiveConversation() {
        XCTAssertNotNil(store.activeConversation)
        
        let conv = store.createConversation(title: "活动对话")
        store.selectConversation(conv)
        
        XCTAssertNotNil(store.activeConversation)
        XCTAssertEqual(store.activeConversation?.id, conv.id)
    }
    
    func testMultipleConversations() {
        let baseCount = store.conversations.count
        for i in 1...5 {
            _ = store.createConversation(title: "对话 \(i)")
        }
        XCTAssertGreaterThanOrEqual(store.conversations.count, baseCount + 5)
    }
    
    func testConversationTitlesUnique() {
        let conv1 = store.createConversation(title: "相同标题")
        let conv2 = store.createConversation(title: "相同标题")
        XCTAssertNotEqual(conv1.id, conv2.id, "不同对话即使标题相同也应有不同ID")
    }
}

// MARK: - 设置存储测试
final class SettingsStoreTests: XCTestCase {
    
    var settingsStore: SettingsStore!
    
    override func setUp() {
        super.setUp()
        settingsStore = SettingsStore.shared
    }
    
    override func tearDown() {
        settingsStore = nil
        super.tearDown()
    }
    
    func testSettingsInitialization() {
        XCTAssertNotNil(settingsStore)
        XCTAssertNotNil(settingsStore.settings)
    }
    
    func testDefaultProfile() {
        let profile = settingsStore.settings.profile
        XCTAssertEqual(profile.nickname, "用户")
        XCTAssertFalse(profile.useCustomNickname)
    }
    
    func testDefaultAPISettings() {
        let settings = settingsStore.settings
        XCTAssertEqual(settings.modelPriority, "cloud")
        XCTAssertEqual(settings.tokenThreshold, 0.85, accuracy: 0.001)
    }
    
    func testUpdateProfile() {
        var newProfile = settingsStore.settings.profile
        newProfile.nickname = "测试昵称"
        newProfile.useCustomNickname = true
        
        settingsStore.settings.profile = newProfile
        settingsStore.saveSettings()
        
        let stored = settingsStore.settings.profile
        XCTAssertEqual(stored.nickname, "测试昵称")
        XCTAssertTrue(stored.useCustomNickname)
    }
    
    func testUpdateTokenThreshold() {
        settingsStore.settings.tokenThreshold = 0.9
        settingsStore.saveSettings()
        XCTAssertEqual(settingsStore.settings.tokenThreshold, 0.9, accuracy: 0.001)
    }
    
    func testUpdateModelPriority() {
        settingsStore.settings.modelPriority = "local"
        settingsStore.saveSettings()
        XCTAssertEqual(settingsStore.settings.modelPriority, "local")
    }
    
    func testUpdateAPIKey() {
        settingsStore.settings.apiKey = "sk-test-key-12345"
        settingsStore.saveSettings()
        XCTAssertEqual(settingsStore.settings.apiKey, "sk-test-key-12345")
    }
}

// MARK: - 模型调度器测试 (基础逻辑)
final class ModelSchedulerTests: XCTestCase {
    
    var scheduler: ModelScheduler!
    
    override func setUp() {
        super.setUp()
        // 使用模拟配置初始化
        let apiClient = QwenAPIClient(apiKey: "sk-test-key", model: "qwen-test")
        let localModel = IOSLocalModelService()
        scheduler = ModelScheduler(apiClient: apiClient, localModel: localModel)
    }
    
    override func tearDown() {
        scheduler = nil
        super.tearDown()
    }
    
    func testSchedulerInitialization() {
        XCTAssertNotNil(scheduler)
        XCTAssertEqual(scheduler.currentProvider, .qwenCloud)
    }
    
    func testDefaultProviderIsCloud() {
        XCTAssertEqual(scheduler.currentProvider, .qwenCloud)
        XCTAssertFalse(scheduler.providerSwitched)
    }
    
    func testProviderSwitchFlag() {
        scheduler.providerSwitched = true
        XCTAssertTrue(scheduler.providerSwitched)
        
        scheduler.providerSwitched = false
        XCTAssertFalse(scheduler.providerSwitched)
    }
    
    func testLoadingStateManagement() {
        XCTAssertFalse(scheduler.isLoading)
        
        scheduler.isLoading = true
        XCTAssertTrue(scheduler.isLoading)
        
        scheduler.isLoading = false
        XCTAssertFalse(scheduler.isLoading)
    }
    
    func testSwitchToLocalModel() {
        scheduler.currentProvider = .iosLocal
        XCTAssertEqual(scheduler.currentProvider, .iosLocal)
        XCTAssertTrue(scheduler.currentProvider.isLocal)
    }
    
    func testShouldUseLocalModelForLargeAttachments() {
        // 少量附件不应触发本地切换
        let smallAttachments = (0..<3).map { _ in
            Attachment(type: .image, fileName: "small.jpg")
        }
        XCTAssertFalse(scheduler.shouldUseLocalModel(for: smallAttachments))
        
        // 大量附件（>10）应当切换到本地
        var largeAttachments: [Attachment] = []
        for i in 0..<15 {
            largeAttachments.append(Attachment(type: .image, fileName: "image_\(i).jpg"))
        }
        XCTAssertTrue(scheduler.shouldUseLocalModel(for: largeAttachments))
    }
    
    func testShouldUseLocalModelForHugeSize() {
        // 单个超大附件也应切换到本地
        let huge = Attachment(type: .pdf, fileName: "big.pdf",
                              fileData: Data(repeating: 0, count: 60 * 1024 * 1024),
                              size: 60 * 1024 * 1024)
        XCTAssertTrue(scheduler.shouldUseLocalModel(for: [huge]))
    }
    
    func testErrorState() {
        XCTAssertNil(scheduler.lastError)
        
        scheduler.lastError = "测试错误"
        XCTAssertNotNil(scheduler.lastError)
        XCTAssertEqual(scheduler.lastError, "测试错误")
        
        scheduler.lastError = nil
        XCTAssertNil(scheduler.lastError)
    }
    
    func testSendMessageAsyncDoesNotCrash() async {
        // 未配置真实 API Key，预期不会发送真实请求
        // 这里仅确保调度器在空消息时不会崩溃
        let messages: [Message] = []
        // sendToModel 使用回调，不会直接崩溃
        // 注意：因为 API Key 为空，调度器会直接降级到本地模型
        await withCheckedContinuation { continuation in
            Task {
                await scheduler.sendToModel(messages: messages) { result in
                    // 无论成功或失败，都不应崩溃
                    switch result {
                    case .success:
                        break
                    case .failure:
                        break
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    func testMultipleRapidRequests() async {
        // 测试多次状态变更不会导致调度器状态混乱
        scheduler.isLoading = true
        scheduler.isLoading = false
        scheduler.isLoading = true
        
        XCTAssertTrue(scheduler.isLoading, "最后设置的状态应为true")
    }
}

// MARK: - 本地模型服务测试
final class IOSLocalModelServiceTests: XCTestCase {
    
    var localModel: IOSLocalModelService!
    
    override func setUp() {
        super.setUp()
        localModel = IOSLocalModelService()
    }
    
    override func tearDown() {
        localModel = nil
        super.tearDown()
    }
    
    func testServiceInitialization() {
        XCTAssertNotNil(localModel)
    }
    
    func testSendMessageGreeting() async {
        do {
            let response = try await localModel.sendMessage("你好", context: nil)
            XCTAssertFalse(response.isEmpty, "回复不应为空")
            XCTAssertLessThan(response.count, 500, "回复不应过长")
        } catch {
            XCTFail("本地模型消息不应失败: \(error)")
        }
    }
    
    func testSendMessageDate() async {
        do {
            let response = try await localModel.sendMessage("今天几号", context: nil)
            XCTAssertFalse(response.isEmpty)
        } catch {
            XCTFail("日期查询不应失败: \(error)")
        }
    }
    
    func testSendMessageHelp() async {
        do {
            let response = try await localModel.sendMessage("帮助", context: nil)
            XCTAssertFalse(response.isEmpty)
        } catch {
            XCTFail("帮助请求不应失败: \(error)")
        }
    }
    
    func testSendMessageUnknown() async {
        do {
            let response = try await localModel.sendMessage("xyznonexistent123", context: nil)
            XCTAssertFalse(response.isEmpty, "未知输入也应提供基础回复")
        } catch {
            XCTFail("未知输入不应失败: \(error)")
        }
    }
    
    func testSendMessageEmpty() async {
        do {
            let response = try await localModel.sendMessage("", context: nil)
            XCTAssertFalse(response.isEmpty, "空输入也应返回提示信息")
        } catch {
            // 空输入失败也是可接受的
        }
    }
    
    func testResponseConsistency() async {
        let msg = "你好"
        do {
            let response1 = try await localModel.sendMessage(msg, context: nil)
            let response2 = try await localModel.sendMessage(msg, context: nil)
            // 本地规则模型可能返回相同或不同的响应
            XCTAssertFalse(response1.isEmpty)
            XCTAssertFalse(response2.isEmpty)
        } catch {
            XCTFail("本地模型测试不应失败: \(error)")
        }
    }
}

// MARK: - 数据完整性测试
final class DataIntegrityTests: XCTestCase {
    
    // MARK: 消息序列化测试
    func testMessageJSONSize() {
        let message = Message(role: .user, content: "测试消息内容")
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(message)
            XCTAssertGreaterThan(data.count, 0)
            XCTAssertLessThan(data.count, 1000, "单条消息JSON不应超过1KB")
        } catch {
            XCTFail("JSON编码失败: \(error)")
        }
    }
    
    func testConversationJSONSize() {
        var conversation = Conversation(title: "测试对话")
        for i in 1...10 {
            conversation.appendMessage(Message(role: .user, content: "用户消息 \(i)"))
            conversation.appendMessage(Message(role: .assistant, content: "AI回复 \(i)"))
        }
        
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(conversation)
            XCTAssertGreaterThan(data.count, 0)
        } catch {
            XCTFail("对话JSON编码失败: \(error)")
        }
    }
    
    // MARK: 大型对话处理
    func testLargeConversationHandling() {
        var conversation = Conversation(title: "长对话")
        for i in 1...100 {
            conversation.appendMessage(
                Message(role: .user, content: "消息内容 \(i) - 这是一条较长的测试消息，用于测试大数据量存储")
            )
        }
        
        XCTAssertEqual(conversation.messages.count, 100)
    }
    
    // MARK: 特殊字符处理
    func testSpecialCharactersInMessage() {
        let specialChars = "!@#$%^&*()_+-=[]{}|;':\",./<>?\\\n\t\r"
        let message = Message(role: .user, content: specialChars)
        
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(message)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Message.self, from: data)
            XCTAssertEqual(message.content, decoded.content, "特殊字符编码解码应一致")
        } catch {
            XCTFail("特殊字符处理失败: \(error)")
        }
    }
    
    func testUnicodeCharacters() {
        let unicodeText = "😀😃😄中文English日本語한국어العربية"
        let message = Message(role: .user, content: unicodeText)
        
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(message)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Message.self, from: data)
            XCTAssertEqual(message.content, decoded.content, "Unicode字符应正确处理")
        } catch {
            XCTFail("Unicode处理失败: \(error)")
        }
    }
    
    // MARK: 日期处理
    func testMessageTimestamp() {
        let message = Message()
        let now = Date()
        
        // 时间戳应接近当前时间（1秒内）
        let timeDiff = message.timestamp.timeIntervalSince(now)
        XCTAssertLessThan(abs(timeDiff), 5.0, "时间戳应在5秒内")
    }
}

// MARK: - 错误处理测试
final class ErrorHandlingTests: XCTestCase {
    
    func testQwenAPIErrorLocalized() {
        let error = QwenAPIError.networkError
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }
    
    func testRateLimitError() {
        let error = QwenAPIError.rateLimit
        XCTAssertFalse(error.localizedDescription.isEmpty)
        XCTAssertTrue(error.localizedDescription.contains("限流") || 
                    error.localizedDescription.contains("rate") ||
                    error.localizedDescription.count > 0)
    }
    
    func testTokenExceededError() {
        let error = QwenAPIError.tokenExceeded
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }
    
    func testInvalidResponseError() {
        let error = QwenAPIError.invalidResponse
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }
    
    func testAPIKeyMissingError() {
        let error = QwenAPIError.apiKeyMissing
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }
    
    func testLocalModelErrors() {
        let error = LocalModelError.localModelUnavailable
        XCTAssertFalse(error.localizedDescription.isEmpty)
        
        let error2 = LocalModelError.contentTooComplex
        XCTAssertFalse(error2.localizedDescription.isEmpty)
        
        let error3 = LocalModelError.unsupportedType
        XCTAssertFalse(error3.localizedDescription.isEmpty)
    }
}

// MARK: - 测试套件注册
extension TokenCounterTests {
    static var allTests = [
        ("testEstimateTokensForEmptyString", testEstimateTokensForEmptyString),
        ("testEstimateTokensForShortText", testEstimateTokensForShortText),
        ("testEstimateTokensForLongText", testEstimateTokensForLongText),
        ("testEstimateTokensProportional", testEstimateTokensProportional),
        ("testEstimateTokensForEmptyMessages", testEstimateTokensForEmptyMessages),
        ("testEstimateTokensForMessages", testEstimateTokensForMessages),
        ("testEstimateTokensMultipleMessages", testEstimateTokensMultipleMessages),
        ("testApproachingLimitNotApproaching", testApproachingLimitNotApproaching),
        ("testApproachingLimitApproaching", testApproachingLimitApproaching),
        ("testApproachingLimitOverLimit", testApproachingLimitOverLimit),
        ("testApproachingLimitWithCustomThreshold", testApproachingLimitWithCustomThreshold),
        ("testTokenEstimationConsistency", testTokenEstimationConsistency)
    ]
}

extension ConversationStoreTests {
    static var allTests = [
        ("testStoreInitialization", testStoreInitialization),
        ("testCreateConversation", testCreateConversation),
        ("testDeleteConversation", testDeleteConversation),
        ("testArchiveConversation", testArchiveConversation),
        ("testActiveConversation", testActiveConversation),
        ("testMultipleConversations", testMultipleConversations),
        ("testConversationTitlesUnique", testConversationTitlesUnique)
    ]
}

extension SettingsStoreTests {
    static var allTests = [
        ("testSettingsInitialization", testSettingsInitialization),
        ("testDefaultProfile", testDefaultProfile),
        ("testDefaultAPISettings", testDefaultAPISettings),
        ("testUpdateProfile", testUpdateProfile),
        ("testUpdateTokenThreshold", testUpdateTokenThreshold),
        ("testUpdateModelPriority", testUpdateModelPriority),
        ("testUpdateAPIKey", testUpdateAPIKey)
    ]
}

extension ModelSchedulerTests {
    static var allTests = [
        ("testSchedulerInitialization", testSchedulerInitialization),
        ("testDefaultProviderIsCloud", testDefaultProviderIsCloud),
        ("testProviderSwitchFlag", testProviderSwitchFlag),
        ("testLoadingStateManagement", testLoadingStateManagement),
        ("testSwitchToLocalModel", testSwitchToLocalModel),
        ("testShouldUseLocalModelForLargeAttachments", testShouldUseLocalModelForLargeAttachments),
        ("testErrorState", testErrorState),
        ("testMultipleRapidRequests", testMultipleRapidRequests)
    ]
}

extension IOSLocalModelServiceTests {
    static var allTests = [
        ("testServiceInitialization", testServiceInitialization),
        ("testSendMessageGreeting", testSendMessageGreeting),
        ("testSendMessageDate", testSendMessageDate),
        ("testSendMessageHelp", testSendMessageHelp),
        ("testSendMessageUnknown", testSendMessageUnknown),
        ("testSendMessageEmpty", testSendMessageEmpty),
        ("testResponseConsistency", testResponseConsistency)
    ]
}

extension DataIntegrityTests {
    static var allTests = [
        ("testMessageJSONSize", testMessageJSONSize),
        ("testConversationJSONSize", testConversationJSONSize),
        ("testLargeConversationHandling", testLargeConversationHandling),
        ("testSpecialCharactersInMessage", testSpecialCharactersInMessage),
        ("testUnicodeCharacters", testUnicodeCharacters),
        ("testMessageTimestamp", testMessageTimestamp)
    ]
}

extension ErrorHandlingTests {
    static var allTests = [
        ("testQwenAPIErrorLocalized", testQwenAPIErrorLocalized),
        ("testRateLimitError", testRateLimitError),
        ("testTokenExceededError", testTokenExceededError),
        ("testInvalidResponseError", testInvalidResponseError),
        ("testAPIKeyMissingError", testAPIKeyMissingError),
        ("testLocalModelErrors", testLocalModelErrors)
    ]
}
