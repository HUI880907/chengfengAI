import SwiftUI

// MARK: - 模型提供者切换提示条
// 当 ModelScheduler 从云端降级到本地模型时，以橙色横条提醒用户

/// 模型切换提示横幅
struct ProviderSwitchBanner: View {

    // MARK: - 环境对象

    /// 模型调度器
    @EnvironmentObject var modelScheduler: ModelScheduler

    // MARK: - 视图主体

    var body: some View {
        if modelScheduler.providerSwitched {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right.slash")
                    .foregroundColor(.orange)
                Text("当前使用本地模型（云端不可用或网络断开）")
                    .font(.caption)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { modelScheduler.providerSwitched = false }) {
                    Text("知道了")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }
}
