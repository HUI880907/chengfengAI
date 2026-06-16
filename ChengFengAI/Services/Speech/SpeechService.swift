import Foundation
import AVFoundation
import Combine

// MARK: - 语音朗读服务
// 基于系统 AVSpeechSynthesizer 的文字转语音服务
// 支持：语速/音调调节、按片段朗读、暂停/继续/停止、音色列表查询

/// 语音朗读服务类
class SpeechService: NSObject, ObservableObject {

    // MARK: - 可观察状态

    /// 是否正在朗读
    @Published var isSpeaking: Bool = false

    /// 当前正在朗读的 AVSpeechUtterance（供 UI 绑定进度）
    @Published var currentUtterance: AVSpeechUtterance?

    // MARK: - 可配置属性

    /// 语速（0.0 ~ 1.0，默认 0.5）
    var speechRate: Float = 0.5

    /// 音调倍频（0.5 ~ 2.0，默认 1.0，1.0 表示正常音调）
    var pitchMultiplier: Float = 1.0

    /// 语言代码（默认 zh-CN）
    var voiceLanguage: String = "zh-CN"

    /// 优先音色性别（默认不指定，由系统按语言自动选择）
    var preferredVoiceGender: AVSpeechSynthesisVoiceGender = .unspecified

    // MARK: - 内部属性

    /// 系统语音合成器
    private let synthesizer: AVSpeechSynthesizer

    // MARK: - 初始化

    override init() {
        self.synthesizer = AVSpeechSynthesizer()
        super.init()
        self.synthesizer.delegate = self
    }

    /// 使用自定义合成器初始化（主要用于测试）
    init(synthesizer: AVSpeechSynthesizer) {
        self.synthesizer = synthesizer
        super.init()
        self.synthesizer.delegate = self
    }

    // MARK: - 公开方法

    /// 朗读整段文本
    /// - Parameter text: 需要朗读的文本
    func speak(_ text: String) {
        let utterance = buildUtterance(text: text)
        currentUtterance = utterance
        // 若之前仍在朗读，先停止
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        synthesizer.speak(utterance)
    }

    /// 朗读文本中指定的 NSRange 片段
    /// - Parameters:
    ///   - text: 完整文本
    ///   - range: 要朗读的片段范围
    func speak(_ text: String, from range: NSRange) {
        guard let swiftRange = Range(range, in: text) else { return }
        let substring = String(text[swiftRange])
        speak(substring)
    }

    /// 暂停朗读（可通过 resume 继续）
    func pause() {
        if synthesizer.isSpeaking && !synthesizer.isPaused {
            synthesizer.pauseSpeaking(at: .word)
        }
    }

    /// 继续朗读
    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }

    /// 停止朗读（不可恢复）
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        currentUtterance = nil
    }

    /// 获取当前可用的音色列表
    /// - Returns: AVSpeechSynthesisVoice 数组
    func availableVoices() -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices()
    }

    /// 获取按当前语言过滤后的音色列表
    /// - Returns: 匹配 voiceLanguage 的音色
    func voicesForCurrentLanguage() -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language == voiceLanguage
        }
    }

    // MARK: - 私有辅助

    /// 根据文本及当前配置构建 AVSpeechUtterance
    private func buildUtterance(text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = min(max(speechRate, AVSpeechUtteranceMinimumSpeechRate),
                              AVSpeechUtteranceMaximumSpeechRate)
        utterance.pitchMultiplier = pitchMultiplier

        // 尝试根据语言与性别选择音色；失败则回落到默认
        if let voice = pickVoice() {
            utterance.voice = voice
        }

        // 每个 utterance 前后静音停顿
        utterance.preUtteranceDelay = 0.0
        utterance.postUtteranceDelay = 0.0
        return utterance
    }

    /// 挑选匹配配置的音色
    private func pickVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        // 优先匹配语言 + 性别
        if preferredVoiceGender != .unspecified {
            if let match = voices.first(where: {
                $0.language == voiceLanguage && $0.gender == preferredVoiceGender
            }) {
                return match
            }
        }
        // 仅按语言匹配
        if let match = voices.first(where: { $0.language == voiceLanguage }) {
            return match
        }
        // 退到默认中文音色
        return AVSpeechSynthesisVoice(language: voiceLanguage)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechService: AVSpeechSynthesizerDelegate {

    /// 开始朗读
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didStart utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.isSpeaking = true
        }
    }

    /// 完成朗读（整段读完且没有被中断）
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.isSpeaking = false
            self?.currentUtterance = nil
        }
    }

    /// 取消朗读
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.isSpeaking = false
            self?.currentUtterance = nil
        }
    }

    /// 暂停朗读
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didPause utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.isSpeaking = false
        }
    }

    /// 继续朗读
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.isSpeaking = true
        }
    }
}
