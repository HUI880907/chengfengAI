import Foundation
import UIKit

// MARK: - 快捷启动支持
// 解析 URL Scheme，如 cfeng://ask?text=xxx 或 cfeng://ask?imageData=<base64>

/// 快捷启动解析器
@MainActor
class ShortcutSupport {

    // MARK: - 单例

    static let shared = ShortcutSupport()

    // MARK: - URL Scheme

    /// 支持的 scheme 协议头
    private let supportedScheme = "cfeng"

    /// 支持的 host 入口
    private let supportedHost = "ask"

    // MARK: - 初始化

    private init() {}

    // MARK: - 公开方法

    /// 解析启动 URL，返回文本/图片组合
    /// - Parameter url: 系统传入的 URL
    /// - Returns: 解析后的文本（可能为空字符串）和图片（可能为 nil），不匹配 scheme 时返回 nil
    func processLaunchURL(_ url: URL) -> (text: String, image: UIImage?)? {
        guard url.scheme == supportedScheme, url.host == supportedHost else {
            return nil
        }
        let items = queryItems(from: url)
        var text: String = ""
        var image: UIImage?

        for item in items {
            switch item.name.lowercased() {
            case "text":
                text = item.value ?? ""
            case "imagedata":
                if let base64 = item.value {
                    // 去除可能存在的 data:image/...;base64, 前缀
                    let cleaned = base64.replacingOccurrences(
                        of: #"^data:image[^,]+,"#,
                        with: "",
                        options: .regularExpression
                    )
                    if let data = Data(base64Encoded: cleaned) {
                        image = UIImage(data: data)
                    }
                }
            default:
                break
            }
        }

        return (text, image)
    }

    /// 提取 URL 查询参数列表
    /// - Parameter url: 输入 URL
    /// - Returns: 查询参数数组（空 URL 或无参数时为空数组）
    func queryItems(from url: URL) -> [URLQueryItem] {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return []
        }
        return components.queryItems ?? []
    }
}
