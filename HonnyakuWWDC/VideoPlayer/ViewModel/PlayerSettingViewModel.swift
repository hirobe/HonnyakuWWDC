//  PlayerSettingViewModel.swift

import Foundation
import Combine
import UIKit

class PlayerSettingViewModel: ObservableObject {
    @Published var isPresent: Bool = true

    @Published var speechVolume: Double
    @Published var videoVolume: Double
    @Published var showOriginalText: Bool
    @Published var showTransferdText: Bool

    @Published var selectedLanguageId: String = ""
    @Published var selectedVoiceId: String = ""

    private var settings: SettingsUseCase

    private var cancellables: [AnyCancellable] = []

    init(settings: SettingsUseCase = SettingsUseCase.shared) {
        self.settings = settings

        speechVolume = settings.speechVolume
        videoVolume = settings.videoVolume
        showOriginalText = settings.showOriginalText
        showTransferdText = settings.showTransferdText

        selectedLanguageId = settings.languageId
        selectedVoiceId = settings.voiceId
        updateVoiceSelect()

        $speechVolume.sink { [weak self] value in
            self?.settings.speechVolume = value
        }
        .store(in: &cancellables)

        $videoVolume.sink { [weak self] value in
            self?.settings.videoVolume = value
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

    func voices(languageId: String) -> [SpeechPlayer.IdentifiableVoice] {
        guard let code = SettingsUseCase.LanguageDefinition.find(id: languageId)?.voicesKey else { return []}
        let voices = SpeechPlayer.getVoices(languageCode: code)
        return voices
    }

    func updateVoiceSelect() {
        // 値が空の場合、選択状態でも値の設定が通知されない（？）ので強制的に値を設定する
        let voices = voices(languageId: selectedLanguageId)
        if voices.count > 0 && !voices.contains(where: { $0.id == selectedVoiceId}) {
            selectedVoiceId = voices.first?.id ?? ""
        }
    }

    var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

}
