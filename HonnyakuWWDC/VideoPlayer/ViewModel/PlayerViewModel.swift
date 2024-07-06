//  PlayerViewModel.swift

import SwiftUI
import AVKit
import Observation
import Combine

typealias ControllerInfo = SyncPlayModel.ControllerInfo
typealias SeekInfo = SyncPlayModel.ControllerInfo.SeekInfo
typealias SyncState = SyncPlayModel.SyncState

@Observable final class PlayerViewModel: ObservableObject {
    //static let empty: PlayerViewModel = PlayerViewModel.init()

    private var speechPlayer: SpeechPlayerProtocol
    var controlBarViewModel: ControlBarViewModel

    private(set) var videoAttributes: VideoAttributesEntity = VideoAttributesEntity.zero
    private(set) var videoPlayer: AVPlayerWrapperProtocol

    private(set) var speechSentence: String = ""
    private(set) var baseSentence: String = ""
    private(set) var showSpeechSentence: Bool = true
    private(set) var showBaseSentence: Bool = true
    private(set) var currentPhraseIndex: Int = 0
    var isThmbnailedPlayer: Bool = false
    private(set) var translatedPhrases: SpeechPhraseList = SpeechPhraseList.zero
    private var basePhrases: SpeechPhraseList = SpeechPhraseList.zero

    // PlayerのController
    private(set) var isShowingController: Bool = true

    var isHoveringScreen: Bool = false

    private var settingsUseCase: SettingsUseCase
    private var syncPlayUseCase: SyncPlayUseCase
    private var fileAccesUseCase: FileAccessUseCaseProtocol

    private var cancellables: [AnyCancellable] = []

    private let prefferdTimeScale: CMTimeScale = 60
    private let videoDetailEntity: VideoDetailEntity?

    init(fileAccesUseCase: FileAccessUseCaseProtocol = FileAccessUseCase(),
         settingsUseCase: SettingsUseCase = SettingsUseCase.shared,
         syncPlayUseCase: SyncPlayUseCase = SyncPlayUseCase(),
         videoPlayer: AVPlayerWrapperProtocol = AVPlayerWrapper(avPlayer: AVPlayer()),
         speechPlayer: SpeechPlayerProtocol = SpeechPlayer(voiceId: "", volume: 1.0),
         videoDetailEntity: VideoDetailEntity? = nil) {
        self.syncPlayUseCase = syncPlayUseCase
        self.controlBarViewModel = ControlBarViewModel(syncPlayUseCase: syncPlayUseCase)
        self.settingsUseCase = settingsUseCase
        self.fileAccesUseCase = fileAccesUseCase
        self.videoPlayer = videoPlayer
        self.speechPlayer = speechPlayer
        self.videoDetailEntity = videoDetailEntity

        self.speechPlayer.delegate = self
    }
    
    func onAppear() {
        startSettingsObservation()
        startIsHoveringScreenObservation()
        startVideoPlayerObservation()
        startSyncPlayModelObservation()

        self.syncPlayUseCase.setPhrases(phrases: SpeechPhraseList.zero)

        if let videoDetailEntity = videoDetailEntity {
            self.setupPlayer(detail: videoDetailEntity)
        }

        setSettings()
    }

    private func startSettingsObservation() {
        withObservationTracking { [weak self] in
            guard let self = self else { return }
            _ = self.settingsUseCase.speechVolume
            _ = self.settingsUseCase.speechRate
            _ = self.settingsUseCase.videoVolume
            _ = self.settingsUseCase.videoRate
            _ = self.settingsUseCase.showOriginalText
            _ = self.settingsUseCase.showTransferdText
            _ = self.settingsUseCase.voiceId
        } onChange: {
            Task { @MainActor in
                self.setSettings()
                self.startSettingsObservation()
            }
        }
    }
    private func setSettings() {
        self.speechPlayer.setVolume(volume: Float(self.settingsUseCase.speechVolume))
        self.speechPlayer.setRate(rate: self.settingsUseCase.speechRate)
        self.videoPlayer.volume = Float(self.settingsUseCase.videoVolume)
        if self.videoPlayer.rate > 0 {
            self.videoPlayer.rate = Float(self.settingsUseCase.videoRate)
        }
        self.showBaseSentence = self.settingsUseCase.showOriginalText
        self.showSpeechSentence = self.settingsUseCase.showTransferdText
        self.speechPlayer.setVoice(voiceId: self.settingsUseCase.voiceId)
    }
    
    private func startIsHoveringScreenObservation() {
        withObservationTracking {
            _ = self.isHoveringScreen
        } onChange: {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.isHoveringScreen {
                    self.isShowingController = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    if !self.isHoveringScreen {
                        self.isShowingController = false
                    }
                }
                self.startIsHoveringScreenObservation()
            }
        }
    }
    private func startVideoPlayerObservation() {
        withObservationTracking {
            _ = self.videoPlayer
        } onChange: {
            Task { @MainActor  [weak self] in
                guard let self = self else { return }
                self.videoPlayer.timeChanged = { cmTime in
                    self.syncPlayUseCase.timeObserved(cmTime: cmTime)
                }
                self.syncPlayUseCase.videoDuration = self.videoPlayer.duration.seconds
                self.startVideoPlayerObservation()
            }
        }
    }
    private func startSyncPlayModelObservation() {
        syncPlayUseCase.$syncPlayModel.sink { [weak self] newState in
            guard let self = self,
                  self.syncPlayUseCase.syncPlayModel != newState else { return }
            let preState = self.syncPlayUseCase.syncPlayModel
            print("newState:\(newState) preState:\(preState) speechSentence:\(speechSentence)")
            Task {
                await self.doWithNewState(newState: newState, preState: preState)
            }

        }
        .store(in: &cancellables)
    }

    private func setupPlayer(detail: VideoDetailEntity) {
        videoPlayer.pause()
        speechPlayer.stop()
        syncPlayUseCase.clear()

        let translated = detail.translated
        videoAttributes = detail.attributes
        let baseTranscript = detail.baseTranscript

        videoPlayer = videoPlayer.generatePlayer(url: self.videoAttributes.videoUrl)
        videoPlayer.volume = Float(settingsUseCase.videoVolume)

        translatedPhrases = SpeechPhrase.makePhrases(from: translated)
        basePhrases = SpeechPhrase.makePhrases(from: baseTranscript)
        speechPlayer.setPhrases(phrases: translatedPhrases)
        syncPlayUseCase.setPhrases(phrases: translatedPhrases)

    }
    
    func togglePlay() {
        if controlBarViewModel.isPlaying {
            controlBarViewModel.pause()
        } else {
            controlBarViewModel.playStart()
        }

    }

    func clearPlayer() {
        videoPlayer.pause()
        speechPlayer.stop()
        videoPlayer = videoPlayer.generatePlayer(url: nil)

        translatedPhrases = .zero
        basePhrases = .zero
        speechPlayer.setPhrases(phrases: .zero)
        syncPlayUseCase.setPhrases(phrases: .zero)
    }

    private func cmTime(seconds: Double) -> CMTime {
        CMTime(seconds: seconds, preferredTimescale: prefferdTimeScale)
    }

    @MainActor
    private func doWithNewState(newState: SyncPlayModel, preState: SyncPlayModel) async {

        // Phraseが変更された
        if newState.phraseIndex != preState.phraseIndex {
            speechPlayer.stop()
            speechSentence = ""
            baseSentence = ""
            translatedPhrases.readyToStart(index: newState.phraseIndex)
        }

        switch newState.controllerInfo {
        case .playing:
            if case let .seeking(info) = preState.controllerInfo {
                // スライダー操作が完了した場合
                _ = await videoPlayer.seek(to: cmTime(seconds: info.seconds))
                try? await Task.sleep(nanoseconds: 1000 * 1000) // waitを入れないとうまく再生されない
            }

            if newState.syncState != .videoWaiting {
                if videoPlayer.rate != settingsUseCase.videoRate {
                    videoPlayer.rate = settingsUseCase.videoRate
                }
                if videoPlayer.avPlayer.timeControlStatus != .playing { // 再生中にplay()すると表示が不正になる
                    videoPlayer.play()

                }
            } else {
                videoPlayer.pause()
            }

            if newState.syncState != .speechWaiting {
                speechPlayer.restart()
            } else {
                speechPlayer.pause()
            }

        case .pausing:
            if case let .seeking(info) = preState.controllerInfo {
                // スライダー操作が完了した場合
                _ = await videoPlayer.seek(to: cmTime(seconds: info.seconds))
            }

            videoPlayer.pause()
            speechPlayer.pause()

        case let .seeking(newInfo):
            if case .playing = preState.controllerInfo {
                // スライダーをドラッグ中は動画を停止することで、動画再生中のスライダーの移動との衝突を避けている
                videoPlayer.pause()
                speechPlayer.pause()
            }

            // seek操作中のseekはtoleranceをつけてラフに行う
            videoPlayer.seek(to: cmTime(seconds: newInfo.seconds),
                             toleranceBefore: cmTime(seconds: 1.0),
                             toleranceAfter: cmTime(seconds: 1.0))
        }
    }

    // 画面サイズ変更時に解像度を再設定する
    func refreshPlayer(size: CGSize) {
        videoPlayer.refreshPlayer(size: size)
    }

}

extension PlayerViewModel: SpeakDelegate {
    func didFinishPhase() {
        let videoAt: Double = videoPlayer.currentTime().seconds
        syncPlayUseCase.didFinishPreSpeechPhrase(videoAt: videoAt)
    }

    func phraseStarted(phrase: String, index: Int) {
        Task { @MainActor in
            self.speechSentence = phrase
            self.basePhrases.readyToStart(index: index)
            self.baseSentence = self.basePhrases.currentText() ?? ""
            self.currentPhraseIndex = index
        }
    }
}

extension PlayerViewModel {
    /// for TranscriptTextView

    func phraseSelected(phrase: SpeechPhrase) {
        syncPlayUseCase.finishSeek(seconds: phrase.at)
    }

    func phraseSelected(index: Int) {
        currentPhraseIndex = index
        syncPlayUseCase.finishSeek(seconds: translatedPhrases.phrases[index].at)
    }
}

extension PlayerViewModel {
    /// for classic player

    func showDocumentFolder() {
        print(fileAccesUseCase.documentDirectoryPath ?? "")
    }

    func classicPasteData() -> Bool {
        guard let text = UIPasteboard.general.string else { return false }
        guard let data = text.data(using: .utf8),
              let detail = try? JSONDecoder().decode(VideoDetailEntity.self, from: data) else { return false }

        try? fileAccesUseCase.saveFileToDocuments(data: data, path: "_.json")

        setupPlayer(detail: detail)
        return true
    }

    func classicLoadData() -> Bool {
        guard let data = try? fileAccesUseCase.loadFileFromDocuments(path: "_.json"),
              let detail = try? JSONDecoder().decode(VideoDetailEntity.self, from: data) else { return false }

        setupPlayer(detail: detail)
        return true
    }
}
