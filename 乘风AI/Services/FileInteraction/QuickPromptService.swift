import Foundation

// MARK: - 快捷提问提示服务
// 根据剪贴板内容自动生成"最合适的提问入口"，减少用户输入成本

/// 快捷提示服务
@MainActor
class QuickPromptService {

    // MARK: - 初始化

    init() {}

    // MARK: - 公开方法

    /// 根据剪贴板文本内容生成快捷提问建议
    /// - Parameter text: 剪贴板中的文本内容
    /// - Returns: 建议的提问字符串
    func promptForClipboardText(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. 识别 URL
        if isValidURL(trimmed) {
            return "帮我分析这个网页内容"
        }

        // 2. 识别代码特征（包含常见关键字或行首缩进）
        if containsCode(trimmed) {
            return "帮我解释这段代码"
        }

        // 3. 长文本（超过 100 个字符）
        if trimmed.count > 100 {
            return "帮我总结这段内容"
        }

        // 4. 默认：短文本
        return "这是什么意思"
    }

    /// 根据剪贴板图片生成快捷提问建议（固定返回"描述这张图片"）
    /// - Returns: 建议的提问字符串
    func promptForImage() -> String {
        return "描述这张图片"
    }

    // MARK: - 私有辅助

    /// 判断字符串是否为合法 URL
    private func isValidURL(_ text: String) -> Bool {
        // 包含常见协议前缀
        let lowercased = text.lowercased()
        if lowercased.hasPrefix("http://") || lowercased.hasPrefix("https://") {
            return true
        }
        // 使用 URLDetector 辅助识别
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let range = NSRange(location: 0, length: text.utf16.count)
            return !detector.matches(in: text, options: [], range: range).isEmpty
        }
        return false
    }

    /// 判断文本是否包含代码特征
    private func containsCode(_ text: String) -> Bool {
        // 常见代码关键字集合
        let codeKeywords = ["func ", "let ", "var ", "class ", "struct ",
                            "import ", "if ", "for ", "while ", "return ",
                            "def ", "class ", "from ", "import ",
                            "{", "}", "=>", "//", "/*", "#include",
                            "async", "await", "@IBOutlet", "@IBAction",
                            "#", "console.log", "print("]
        for keyword in codeKeywords {
            if text.contains(keyword) {
                return true
            }
        }
        // 代码行常以 4 空格缩进，若前 5 行中有 2 行以上以空格开头则判断为代码
        let lines = text.components(separatedBy: .newlines).prefix(5)
        let indentedCount = lines.filter { $0.hasPrefix("    ") || $0.hasPrefix("\t") }.count
        return indentedCount >= 2
    }
}
