//  PlayerSettingViewModel.swift

import Foundation
import UIKit

@Observable final class PlayerSettingViewModel {
    var isPresent: Bool = true

    var speechVolume: Double
    var speechRate: Float
    var videoVolume: Double
    var videoRate: Float
    var showOriginalText: Bool
    var showTransferdText: Bool

    var selectedLanguageId: String = ""
    var selectedVoiceId: String = ""

    @ObservationIgnored private var settings: SettingsUseCase

    init(settings: SettingsUseCase = SettingsUseCase.shared) {
        self.settings = settings

        speechVolume = settings.speechVolume
        speechRate = settings.speechRate
        videoVolume = settings.videoVolume
        videoRate = settings.videoRate
        showOriginalText = settings.showOriginalText
        showTransferdText = settings.showTransferdText

        selectedLanguageId = settings.languageId
        selectedVoiceId = settings.voiceId
        updateVoiceSelect()
        updateSpeechRate()
        updateVideoRate()

        startObservation()
    }

    private func startObservation() {
        withObservationTracking { [self] in
            _ = self.speechVolume
            _ = self.speechRate
            _ = self.videoVolume
            _ = self.videoRate
            _ = self.showOriginalText
            _ = self.showTransferdText
            _ = self.selectedLanguageId
            _ = self.selectedVoiceId
        } onChange: { [self] in
            Task { @MainActor in
                settings.speechVolume = speechVolume
                settings.speechRate = speechRate
                settings.videoVolume = videoVolume
                settings.videoRate = videoRate
                settings.showOriginalText = showOriginalText
                settings.showTransferdText = showTransferdText
                settings.languageId = selectedLanguageId
                settings.voiceId = selectedVoiceId
                startObservation()
            }
        }
    }

    func languages() -> [SettingsUseCase.LanguageDefinition] {
        SettingsUseCase.LanguageDefinition.all
    }
    func speechRates() -> [SettingsUseCase.SpeechRateDefinition] {
        SettingsUseCase.SpeechRateDefinition.all
    }
    func videoRates() -> [SettingsUseCase.VideoRateDefinition] {
        SettingsUseCase.VideoRateDefinition.all
    }

    func voices(languageId: String) -> [SpeechPlayer.IdentifiableVoice] {
        guard let code = SettingsUseCase.LanguageDefinition.find(id: languageId)?.voicesKey else { return []}
        let voices = SpeechPlayer.getVoices(languageCode: code)
        return voices
    }

    func updateVoiceSelect() {
        // 値が空の場合、選択状態でも値の設定が通知されない（？）ので強制的に値を設定する
        if SettingsUseCase.LanguageDefinition.find(id: selectedLanguageId) == nil {
            selectedLanguageId = SettingsUseCase.LanguageDefinition.all.first?.id ?? ""
        }
        let voices = voices(languageId: selectedLanguageId)
        if voices.count > 0 && !voices.contains(where: { $0.id == selectedVoiceId}) {
            selectedVoiceId = voices.first?.id ?? ""
        }
    }
    func updateSpeechRate() {
        // 値が空の場合、選択状態でも値の設定が通知されない（？）ので強制的に値を設定する
        if SettingsUseCase.SpeechRateDefinition.find(value: speechRate) == nil {
            speechRate = 1.0
        }
    }
    func updateVideoRate() {
        // 値が空の場合、選択状態でも値の設定が通知されない（？）ので強制的に値を設定する
        if SettingsUseCase.VideoRateDefinition.find(value: videoRate) == nil {
            videoRate = 1.0
        }
    }

    var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

}
