import SwiftUI

// MARK: - 设置视图
// 管理用户昵称、API Key、模型优先级、token阈值、朗读设置、进阶功能、关于信息
// 所有修改立即持久化（调用 SettingsStore.saveSettings()

/// 设置视图
struct SettingsView: View {

    // MARK: - 环境对象
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.dismiss) private var dismiss

    // MARK: - 视图状态
    /// 是否显示关于页面
    @State private var showAbout: Bool = false

    // MARK: - 主体
    var body: some View {
        NavigationStack {
            Form {
                // 用户信息
                Section("个人信息") {
                    Toggle("使用自定义昵称", isOn: Binding(
                        get: { settingsStore.settings.profile.useCustomNickname },
                        set: { newValue in
                            settingsStore.settings.profile.useCustomNickname = newValue
                            settingsStore.saveSettings()
                        }
                    ))

                    if settingsStore.settings.profile.useCustomNickname {
                        TextField("昵称", text: Binding(
                            get: { settingsStore.settings.profile.nickname },
                            set: { newValue in
                                settingsStore.settings.profile.nickname = newValue
                                settingsStore.saveSettings()
                            }
                        ))
                    }
                }

                // 模型配置
                Section("模型配置") {
                    TextField("千问API Key", text: Binding(
                        get: { settingsStore.settings.apiKey },
                        set: { newValue in
                            settingsStore.settings.apiKey = newValue
                            settingsStore.saveSettings()
                        }
                    ))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                    Picker("模型优先级", selection: Binding(
                        get: { settingsStore.settings.modelPriority },
                        set: { newValue in
                            settingsStore.settings.modelPriority = newValue
                            settingsStore.saveSettings()
                        }
                    )) {
                        Text("云端优先").tag("cloud")
                        Text("本地优先").tag("local")
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Token阈值")
                        Slider(
                            value: Binding(
                                get: { settingsStore.settings.tokenThreshold },
                                set: { newValue in
                                    settingsStore.settings.tokenThreshold = newValue
                                    settingsStore.saveSettings()
                                }
                            ),
                            in: 0.5...0.95
                        )
                        Text(String(format: "%.0f%%", settingsStore.settings.tokenThreshold * 100))
                    }
                }

                // 朗读设置
                Section("朗读设置") {
                    Toggle("自动朗读AI回答", isOn: Binding(
                        get: { settingsStore.settings.profile.speechAutoPlay },
                        set: { newValue in
                            settingsStore.settings.profile.speechAutoPlay = newValue
                            settingsStore.saveSettings()
                        }
                    ))
                }

                // 进阶功能
                Section("进阶功能") {
                    Toggle("启用进阶功能", isOn: Binding(
                        get: { settingsStore.settings.profile.advancedFeaturesEnabled },
                        set: { newValue in
                            settingsStore.settings.profile.advancedFeaturesEnabled = newValue
                            settingsStore.saveSettings()
                        }
                    ))

                    if settingsStore.settings.profile.advancedFeaturesEnabled {
                        Toggle("iCloud备份(预留)", isOn: Binding(
                            get: { settingsStore.settings.profile.icloudBackupEnabled },
                            set: { newValue in
                                settingsStore.settings.profile.icloudBackupEnabled = newValue
                                settingsStore.saveSettings()
                            }
                        ))
                    }
                }

                // 关于
                Section("关于") {
                    Button {
                        showAbout = true
                    } label: {
                        HStack {
                            Text("版本信息")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAbout) {
                Form {
                    Text("乘风AI v1.0.0")
                    Text("使用通义千问 + iOS 本地模型")
                    Text("© 2026 ChengFeng AI")
                }
                .presentationDetents([.medium])
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsStore.shared)
}
