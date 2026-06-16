import Foundation

// MARK: - API凭证模型
// 用于保存自定义API服务的凭证信息

/// API凭证结构体，保存API密钥、服务器地址、模型名称等
struct APICredential: Codable {
    // MARK: - 属性
    var provider: String = ""          // 提供者名称（对应ModelProviderType的rawValue或自定义名称）
    var apiKey: String = ""            // API密钥
    var baseURL: String = ""           // 基础URL
    var modelName: String = ""         // 模型名称（如 "gpt-4"、"qwen-max"）
    var isActive: Bool = false         // 当前是否启用

    // MARK: - 初始化方法
    /// 默认初始化
    init() {}

    /// 便捷初始化方法
    /// - Parameters:
    ///   - provider: 提供者名称
    ///   - apiKey: API密钥
    ///   - baseURL: 基础URL
    ///   - modelName: 模型名称
    ///   - isActive: 是否启用
    init(provider: String, apiKey: String, baseURL: String, modelName: String, isActive: Bool) {
        self.provider = provider
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.modelName = modelName
        self.isActive = isActive
    }
}
