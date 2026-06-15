import Foundation
import UIKit
import SwiftUI

// MARK: - 剪贴板监听服务
// 监听 UIPasteboard 变化，提供文本/图片读取、标记已读等能力

/// 剪贴板服务类，供 SwiftUI 环境注入使用
@MainActor
class ClipboardService: ObservableObject {

    // MARK: - 可观察状态

    /// 剪贴板中的文本内容（有新内容时自动填充，读取后由消费者清零）
    @Published var clipboardText: String?

    /// 剪贴板中的图片内容
    @Published var clipboardImage: UIImage?

    /// 是否有新内容尚未被用户处理（用于驱动提示条展示）
    @Published var hasNewContent: Bool = false

    // MARK: - 内部属性

    /// 定时轮询剪贴板的计时器
    private var monitorTimer: Timer?

    /// 上一次检测到的文本哈希，避免将重复内容视为新内容
    private var lastTextHash: Int = 0

    /// 上一次检测到的图片哈希
    private var lastImageHash: Int = 0

    // MARK: - 初始化

    init() {}

    // MARK: - 公开方法

    /// 启动剪贴板监听
    /// 使用 Timer 每 1 秒轮询一次 UIPasteboard
    func startMonitoring() {
        stopMonitoring()
        // 在主线程 RunLoop 中调度，保证 UI 更新安全
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboard()
            }
        }
        if let timer = monitorTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    /// 停止剪贴板监听
    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    /// 检查剪贴板内容，根据变化情况更新 published 状态
    func checkClipboard() {
        let pasteboard = UIPasteboard.general

        // 处理图片（优先图片，避免与文本同时触发重复）
        if pasteboard.hasImages, let image = pasteboard.image {
            let hash = image.hashValue
            if hash != lastImageHash {
                lastImageHash = hash
                clipboardImage = image
                clipboardText = nil
                hasNewContent = true
                return
            }
        }

        // 处理文本
        if pasteboard.hasStrings, let text = pasteboard.string, !text.isEmpty {
            let hash = text.hashValue
            if hash != lastTextHash {
                lastTextHash = hash
                clipboardText = text
                clipboardImage = nil
                hasNewContent = true
                return
            }
        }

        // 剪贴板为空的情况，不主动清除，保持上一次的内容供 UI 读取
    }

    /// 消费并返回剪贴板文本（同时清空内部缓存）
    /// - Returns: 原剪贴板文本内容
    func consumeText() -> String? {
        let text = clipboardText
        clipboardText = nil
        hasNewContent = false
        return text
    }

    /// 消费并返回剪贴板图片（同时清空内部缓存）
    /// - Returns: 原剪贴板图片
    func consumeImage() -> UIImage? {
        let image = clipboardImage
        clipboardImage = nil
        hasNewContent = false
        return image
    }

    /// 标记为已读，用于在用户忽略提示时关闭提示条
    func markAsRead() {
        hasNewContent = false
        // 不清除 clipboardText/clipboardImage，用户可能稍后仍需读取
    }

    deinit {
        stopMonitoring()
    }
}
