import Foundation
import AVFoundation
import SwiftUI

// MARK: - 语音朗读配置
// 集中管理语速、音调、音量、语言、音色等参数，可一键应用到 SpeechService

/// 语音配置服务类
@MainActor
class SpeechSettings: ObservableObject {

    // MARK: - 可观察状态

    /// 语速（0.0 ~ 1.0，默认 0.5）
    @Published var rate: Float = 0.5

    /// 音调倍数（0.5 ~ 2.0，默认 1.0）
    @Published var pitch: Float = 1.0

    /// 音量（0.0 ~ 1.0，默认 0.8）
    @Published var volume: Float = 0.8

    /// 语言代码，默认中文（zh-CN）
    @Published var language: String = "zh-CN"

    /// 优先使用的音色 ID（为空则由系统按语言自动选择）
    @Published var preferredVoiceIdentifier: String?

    /// 是否自动朗读 AI 回复
    @Published var autoPlayEnabled: Bool = false

    // MARK: - UserDefaults 键名

    private enum Keys {
        static let rate = "speech.rate"
        static let pitch = "speech.pitch"
        static let volume = "speech.volume"
        static let language = "speech.language"
        static let preferredVoiceIdentifier = "speech.preferredVoiceIdentifier"
        static let autoPlayEnabled = "speech.autoPlayEnabled"
    }

    // MARK: - 初始化

    init() {
        load()
    }

    // MARK: - 公开方法

    /// 获取指定语言可用的音色列表
    /// - Parameter language: 语言代码（如 zh-CN、en-US）
    /// - Returns: 匹配的音色数组
    func availableVoices(for language: String) -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == language }
    }

    /// 根据 identifier 查询音色
    /// - Parameter identifier: 音色标识符
    /// - Returns: 对应的音色对象（若找不到则为 nil）
    func voice(with identifier: String) -> AVSpeechSynthesisVoice? {
        return AVSpeechSynthesisVoice.speechVoices().first { $0.identifier == identifier }
    }

    /// 将当前配置应用到 SpeechService
    /// - Parameter service: 要更新的语音服务实例
    func apply(to service: SpeechService) {
        service.speechRate = rate
        service.pitchMultiplier = pitch
        service.voiceLanguage = language
    }

    /// 持久化配置到 UserDefaults
    func save() {
        let defaults = UserDefaults.standard
        defaults.set(rate, forKey: Keys.rate)
        defaults.set(pitch, forKey: Keys.pitch)
        defaults.set(volume, forKey: Keys.volume)
        defaults.set(language, forKey: Keys.language)
        defaults.set(preferredVoiceIdentifier, forKey: Keys.preferredVoiceIdentifier)
        defaults.set(autoPlayEnabled, forKey: Keys.autoPlayEnabled)
    }

    /// 从 UserDefaults 读取配置
    func load() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Keys.rate) != nil {
            rate = defaults.float(forKey: Keys.rate)
        }
        if defaults.object(forKey: Keys.pitch) != nil {
            pitch = defaults.float(forKey: Keys.pitch)
        }
        if defaults.object(forKey: Keys.volume) != nil {
            volume = defaults.float(forKey: Keys.volume)
        }
        if let lang = defaults.string(forKey: Keys.language) {
            language = lang
        }
        preferredVoiceIdentifier = defaults.string(forKey: Keys.preferredVoiceIdentifier)
        autoPlayEnabled = defaults.bool(forKey: Keys.autoPlayEnabled)
    }
}
