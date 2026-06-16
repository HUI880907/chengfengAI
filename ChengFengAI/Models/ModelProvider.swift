import Foundation

// MARK: - 模型提供者枚举
// 用于区分不同的AI模型服务来源

/// 模型提供者类型枚举，定义可用的AI服务来源
enum ModelProviderType: String, Codable, CaseIterable {
    case qwenCloud  // 通义千问云端服务
    case iosLocal   // iOS本地大模型
    case customAPI  // 自定义API服务

    // MARK: - 计算属性

    /// 中文显示名称，用于UI展示
    var displayName: String {
        switch self {
        case .qwenCloud:
            return "通义千问（云端）"
        case .iosLocal:
            return "本地模型"
        case .customAPI:
            return "自定义API"
        }
    }

    /// 是否为本地运行模型（区分云端API调用）
    var isLocal: Bool {
        switch self {
        case .iosLocal:
            return true
        case .qwenCloud, .customAPI:
            return false
        }
    }
}
