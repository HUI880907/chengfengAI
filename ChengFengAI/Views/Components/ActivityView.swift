import SwiftUI
import UIKit

// MARK: - ActivityView (UIActivityViewController SwiftUI 封装)
// 使用 UIViewControllerRepresentable 将 UIActivityViewController 包装为 SwiftUI 视图

struct ActivityView: UIViewControllerRepresentable {

    // MARK: - 属性

    /// 需要分享的项目列表（文本、URL、UIImage 等）
    let activityItems: [Any]

    /// 自定义应用内活动（可选）
    let applicationActivities: [UIActivity]? = nil

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController,
                                context: Context) {
        // 无额外状态需要更新
    }
}
