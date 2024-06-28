//  SystemSettingsViewModel.swift

import Foundation
import Observation
import AVFoundation

@Observable final class SystemSettingViewModel {
    private var progressUseCase: TaskProgressUseCase
    @ObservationIgnored private var settings: SettingsUseCase
    private var videoListUseCase: VideoListUseCase
    private var videoGroupScrapingUseCase: VideoGroupScrapingUseCase

    private(set) var isPresent: Bool = true

    private(set) var langIndex: Int = 0

    var voiceId: String = ""
    var deepLAuthKey: String = ""
    var isDeepLPro: Bool = false
    
    var openAIAuthKey: String = ""

    var selectedLanguageId: String = ""
    var selectedVoiceId: String = ""

    private(set) var videoGroupList: [VideoGroupSettingViewModel] = []

    init(settings: SettingsUseCase = SettingsUseCase.shared,
         progressUseCase: TaskProgressUseCase = TaskProgressUseCase(),
         videoListUseCase: VideoListUseCase = VideoListUseCase(),
         videoGroupScrapingUseCase: VideoGroupScrapingUseCase = VideoGroupScrapingUseCase()) {
        self.progressUseCase = progressUseCase
        self.videoListUseCase = videoListUseCase
        self.settings = settings
        self.videoGroupScrapingUseCase = videoGroupScrapingUseCase

        deepLAuthKey = settings.deepLAuthKey
        isDeepLPro = settings.isDeepLPro
        openAIAuthKey = settings.openAIAuthKey

        selectedLanguageId = settings.languageId
        selectedVoiceId = settings.voiceId
        //updateVoiceSelect()

        videoGroupList = VideoGroupAttributesEntity.all.keys.sorted().reversed().compactMap({ key in
            guard let entity: VideoGroupAttributesEntity = VideoGroupAttributesEntity.all[key] else { return nil }
            return VideoGroupSettingViewModel(id: entity.id, title: entity.title, enabled: settings.videoGroupIds.contains(entity.id),
                                       progress: progressUseCase.fetchObservable(taskId: entity.id),
                                       onChanged: { item in self.onGroupChanged(item) })
        })

        Task { @MainActor in
            self.setupObservation()
        }
    }

    private func setupObservation() {
        
        withObservationTracking {
            _ = self.deepLAuthKey
            _ = self.openAIAuthKey
            _ = self.isDeepLPro
            _ = self.selectedLanguageId
            _ = self.selectedVoiceId
        } onChange: { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                self.settings.deepLAuthKey = self.deepLAuthKey
                self.settings.openAIAuthKey = self.openAIAuthKey
                self.settings.isDeepLPro = self.isDeepLPro
                self.settings.languageId = self.selectedLanguageId
                self.settings.voiceId = self.selectedVoiceId
                self.settings.isDeepLPro = self.isDeepLPro

                self.setupObservation()
            }
        }
    }

    // トグル変更後に呼ばれる
    private func onGroupChanged(_ videoGroupViewModel: VideoGroupSettingViewModel) {
        if videoGroupViewModel.enabled && !settings.videoGroupIds.contains(videoGroupViewModel.id) {
            startFetchList(videoGroupViewModel: videoGroupViewModel)
        }

        settings.videoGroupIds = videoGroupList.filter { $0.enabled == true }.map { $0.id }.sorted().reversed()
    }

    // listのトグルがONになったら、ダウンロードを開始する
    // off->onにしたときファイルが存在しても読み込むのはバグ。loadVideoGroupsComplatedStatusが機能していない？
    private func startFetchList(videoGroupViewModel: VideoGroupSettingViewModel) {
        switch videoGroupViewModel.progress.state {
        case .completed, .processing:
            break // 何もしない
        case .notStarted, .unknwon, .failed:
            Task {
                try? await videoGroupScrapingUseCase.fetchList(id: videoGroupViewModel.id)
            }
        }
    }

    func languages() -> [SettingsUseCase.LanguageDefinition] {
        SettingsUseCase.LanguageDefinition.all
    }

    func voices(languageId: String) -> [SpeechPlayer.IdentifiableVoice] {
        guard let code = SettingsUseCase.LanguageDefinition.find(id: languageId)?.voicesKey else { return [] }
        return SpeechPlayer.getVoices(languageCode: code)
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

    func videoGroups() -> [VideoGroupAttributesEntity] {
        return Array(VideoGroupAttributesEntity.all.values)
    }

}
