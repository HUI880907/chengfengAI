import Foundation

// MARK: - Date 辅助方法
// 提供常用的日期格式化扩展：自定义格式、短时间、短日期

extension Date {

    /// 按照指定格式返回字符串
    /// - Parameter format: 日期格式，默认 "yyyy-MM-dd HH:mm"
    /// - Returns: 格式化后的日期字符串
    func formattedString(format: String = "yyyy-MM-dd HH:mm") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }

    /// 短时间格式（HH:mm），常用于气泡旁时间戳
    var shortTime: String {
        formattedString(format: "HH:mm")
    }

    /// 短日期格式（MM-dd），常用于侧边栏列表
    var shortDate: String {
        formattedString(format: "MM-dd")
    }
}
