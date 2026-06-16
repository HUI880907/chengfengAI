import SwiftUI
import UIKit

// MARK: - 分享内容视图
// 将文本内容写入 Documents 临时文件后通过 UIActivityViewController 分享

/// 分享内容视图
struct ShareContentView: View {

    // MARK: - 属性

    /// 需要分享的文本内容
    let content: String

    // MARK: - 环境

    /// SwiftUI 视图关闭环境
    @Environment(\.dismiss) private var dismiss

    // MARK: - 状态

    /// 是否展示 UIActivityViewController
    @State private var showActivityView = false

    /// 写入的临时文件 URL，用于分享
    @State private var fileURL: URL?

    // MARK: - 视图主体

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("分享内容")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 左侧：关闭按钮
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("关闭")
                    }
                }
                // 右侧：分享按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: share) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showActivityView) {
                // UIActivityViewController 包装层
                if let url = fileURL {
                    ActivityView(activityItems: [url])
                } else {
                    ActivityView(activityItems: [content])
                }
            }
        }
    }

    // MARK: - 行为方法

    /// 分享逻辑：先写入临时文件，再弹出系统分享面板
    private func share() {
        do {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "shared-\(Date().timeIntervalSince1970).txt"
            let url = documents.appendingPathComponent(fileName)
            try content.write(to: url, atomically: true, encoding: .utf8)
            fileURL = url
        } catch {
            // 写入失败时回落为纯文本分享
            fileURL = nil
        }
        showActivityView = true
    }
}
