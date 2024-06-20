//  SystemSettingsViewModel.swift

import Foundation
import Combine
import AVFoundation

final class SystemSettingViewModel: ObservableObject {
    private var progressUseCase: TaskProgressUseCase
    private var settings: SettingsUseCase
    private var videoListUseCase: VideoListUseCase
    private var videoGroupScrapingUseCase: VideoGroupScrapingUseCase

    @Published private(set) var isPresent: Bool = true

    @Published private(set) var langIndex: Int = 0

    @Published var voiceId: String = ""
    @Published var deepLAuthKey: String = ""
    @Published var isDeepLPro: Bool = false
    @Published var openAIAuthKey: String = ""

    @Published var selectedLanguageId: String = ""
    @Published var selectedVoiceId: String = ""

    @Published private(set) var videoGroupList: [VideoGroupSettingViewModel] = []

    private var cancellables: [AnyCancellable] = []

    init(settings: SettingsUseCase = SettingsUseCase.shared,
         progressUseCase: TaskProgressUseCase = TaskProgressUseCase(),
         videoListUseCase: VideoListUseCase = VideoListUseCase(),
         videoGroupScrapingUseCase: VideoGroupScrapingUseCase = VideoGroupScrapingUseCase()) {
        self.progressUseCase = progressUseCase
        self.videoListUseCase = videoListUseCase
        self.settings = settings
        self.videoGroupScrapingUseCase = VideoGroupScrapingUseCase()

        deepLAuthKey = settings.deepLAuthKey
        isDeepLPro = settings.isDeepLPro
        openAIAuthKey = settings.openAIAuthKey

        selectedLanguageId = settings.languageId
        selectedVoiceId = settings.voiceId
        updateVoiceSelect()

        videoGroupList = VideoGroupAttributesEntity.all.keys.sorted().reversed().compactMap({ key in
            guard let entity: VideoGroupAttributesEntity = VideoGroupAttributesEntity.all[key] else { return nil }
            return VideoGroupSettingViewModel(id: entity.id, title: entity.title, enabled: settings.videoGroupIds.contains(entity.id),
                                       progress: progressUseCase.fetchObservable(taskId: entity.id),
                                       onChanged: { item in self.onGroupChanged(item) })
        })

        $deepLAuthKey.sink { [weak self] value in
            self?.settings.deepLAuthKey = value
        }
        .store(in: &cancellables)
        
        $openAIAuthKey.sink { [weak self] value in
            self?.settings.openAIAuthKey = value
        }
        .store(in: &cancellables)

        $isDeepLPro.sink { [weak self] value in
            self?.settings.isDeepLPro = value
        }
        .store(in: &cancellables)

        $selectedLanguageId.sink { [weak self] value in
            self?.settings.languageId = value
        }
        .store(in: &cancellables)

        $selectedVoiceId.sink { [weak self] value in
            self?.settings.voiceId = value
        }
        .store(in: &cancellables)

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

    func videoGroups() -> [VideoGroupAttributesEntity] {
        return Array(VideoGroupAttributesEntity.all.values)
    }

}
