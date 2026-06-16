import SwiftUI
import AVFoundation

// MARK: - 语音朗读控制面板
// 提供语速、音调、音色的调节 UI，参数会同步写入 SpeechSettings 与 SpeechService

/// 语音控制面板
struct SpeechControlsView: View {

    // MARK: - 环境对象

    /// 语音朗读服务
    @EnvironmentObject var speechService: SpeechService

    /// 语音配置
    @EnvironmentObject var speechSettings: SpeechSettings

    // MARK: - 视图主体

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // 语速滑杆
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("语速")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(
                        value: Binding(
                            get: { speechSettings.rate },
                            set: { newValue in
                                speechSettings.rate = newValue
                                speechService.speechRate = newValue
                            }
                        ),
                        in: 0.1...1.0
                    )
                    Text(String(format: "%.1f", speechSettings.rate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }

            // 音调滑杆
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("音调")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(
                        value: Binding(
                            get: { speechSettings.pitch },
                            set: { newValue in
                                speechSettings.pitch = newValue
                                speechService.pitchMultiplier = newValue
                            }
                        ),
                        in: 0.5...2.0
                    )
                    Text(String(format: "%.1f", speechSettings.pitch))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }

            // 音色选择（Menu）
            Menu {
                ForEach(filteredVoices, id: \.identifier) { voice in
                    Button(action: {
                        speechSettings.preferredVoiceIdentifier = voice.identifier
                        speechSettings.save()
                    }) {
                        Text(voice.name)
                    }
                }
            } label: {
                HStack {
                    Text("音色")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(selectedVoiceName)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .contentShape(Rectangle())
            }

            // 自动朗读开关
            Toggle(isOn: Binding(
                get: { speechSettings.autoPlayEnabled },
                set: { newValue in
                    speechSettings.autoPlayEnabled = newValue
                    speechSettings.save()
                }
            )) {
                Text("自动朗读 AI 回复")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .toggleStyle(.switch)

        }
        .padding()
    }

    // MARK: - 辅助计算属性

    /// 根据当前语言过滤后的音色列表
    private var filteredVoices: [AVSpeechSynthesisVoice] {
        speechService.availableVoices().filter { $0.language == speechSettings.language }
    }

    /// 当前选中音色的显示名
    private var selectedVoiceName: String {
        if let identifier = speechSettings.preferredVoiceIdentifier,
           let voice = speechService.availableVoices().first(where: { $0.identifier == identifier }) {
            return voice.name
        }
        return "默认"
    }
}
