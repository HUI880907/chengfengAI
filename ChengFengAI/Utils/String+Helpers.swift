import Foundation

// MARK: - String 辅助方法
// 提供常用的字符串处理扩展：去空白、判断空值、子串截取、时间戳附加

extension String {

    /// 去除首尾空白与换行字符
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 判断字符串去除空白后是否为空
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 通过 NSRange 截取子字符串（便于与 NSAttributedString / UIKit API 配合）
    /// - Parameter range: 需要截取的范围
    /// - Returns: 截取后的子字符串
    func substring(with range: NSRange) -> String {
        (self as NSString).substring(with: range)
    }

    /// 在字符串末尾附加时间戳，格式为 yyyyMMdd_HHmmss
    /// - Returns: 形如 "原字符串_20250701_123045" 的新字符串
    func appendingTimestamp() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        return appending("_").appending(dateFormatter.string(from: Date()))
    }
}
