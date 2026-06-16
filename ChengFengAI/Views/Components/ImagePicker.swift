import SwiftUI
import UIKit

// MARK: - 图片选择器（UIKit 封装）
// 封装 UIImagePickerController，方便在 SwiftUI 中使用
// 通过 onPicked 回调将选到的 UIImage 返回给调用者

/// UIKit 的图片选择器封装
struct ImagePicker: UIViewControllerRepresentable {

    // MARK: - 环境
    @Environment(\.dismiss) private var dismiss

    // MARK: - 输入
    /// 相册来源类型
    let sourceType: UIImagePickerController.SourceType
    /// 图片选中回调
    let onPicked: (UIImage) -> Void

    // MARK: - UIViewControllerRepresentable
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // 无需更新
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    /// 协调器，处理 UIImagePickerControllerDelegate
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onPicked(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
