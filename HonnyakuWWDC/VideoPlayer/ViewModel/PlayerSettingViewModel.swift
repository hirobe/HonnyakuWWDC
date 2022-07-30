//  PlayerSettingViewModel.swift

import Foundation
import Combine
import UIKit

final class PlayerSettingViewModel: ObservableObject {
    @Published var isPresent: Bool = true

    @Published var speechVolume: Double
    @Published var speechRate: Float
    @Published var videoVolume: Double
    @Published var videoRate: Float
    @Published var showOriginalText: Bool
    @Published var showTransferdText: Bool

    @Published var selectedLanguageId: String = ""
    @Published var selectedVoiceId: String = ""

    private var settings: SettingsUseCase

    private var cancellables: [AnyCancellable] = []

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

        $speechVolume.sink { [weak self] value in
            self?.settings.speechVolume = value
        }
        .store(in: &cancellables)

        $speechRate.sink { [weak self] value in
            self?.settings.speechRate = value
        }
        .store(in: &cancellables)

        $videoVolume.sink { [weak self] value in
            self?.settings.videoVolume = value
        }
        .store(in: &cancellables)

        $videoRate.sink { [weak self] value in
            self?.settings.videoRate = value
        }
        .store(in: &cancellables)

        $showOriginalText.sink { [weak self] value in
            self?.settings.showOriginalText = value
        }
        .store(in: &cancellables)

        $showTransferdText.sink { [weak self] value in
            self?.settings.showTransferdText = value
        }
        .store(in: &cancellables)

        settings.languageId = ""
        $selectedLanguageId.sink { [weak self] value in
            self?.settings.languageId = value
        }
        .store(in: &cancellables)

        $selectedVoiceId.sink { [weak self] value in
            self?.settings.voiceId = value
        }
        .store(in: &cancellables)

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
