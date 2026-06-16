import Foundation
import UIKit

// MARK: - 分享服务
// 封装 UIActivityViewController，提供文本、文件、图像的分享能力

class ShareService {

    // MARK: - 单例

    static let shared = ShareService()

    private init() {}

    // MARK: - 分享文本

    /// 分享纯文本
    /// - Parameters:
    ///   - text: 需要分享的文本内容
    ///   - viewController: 用于 present 分享面板的源控制器
    func shareText(_ text: String, from viewController: UIViewController) {
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        // iPad 下需要提供 popoverPresentationController 的源位置
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        viewController.present(activityVC, animated: true)
    }

    // MARK: - 分享文件

    /// 分享本地文件（通过文件 URL）
    /// - Parameters:
    ///   - fileURL: 需要分享的文件本地 URL
    ///   - viewController: 用于 present 分享面板的源控制器
    func shareFile(_ fileURL: URL, from viewController: UIViewController) {
        let activityVC = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        viewController.present(activityVC, animated: true)
    }

    // MARK: - 分享图像

    /// 分享 UIImage
    /// - Parameters:
    ///   - image: 需要分享的图像
    ///   - viewController: 用于 present 分享面板的源控制器
    func shareImage(_ image: UIImage, from viewController: UIViewController) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        viewController.present(activityVC, animated: true)
    }
}
