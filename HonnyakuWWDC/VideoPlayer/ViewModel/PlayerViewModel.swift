//  PlayerViewModel.swift

import SwiftUI
import Combine
import AVKit

typealias ControllerInfo = SyncPlayModel.ControllerInfo
typealias SeekInfo = SyncPlayModel.ControllerInfo.SeekInfo
typealias SyncState = SyncPlayModel.SyncState

final class PlayerViewModel: ObservableObject {
    static let empty: PlayerViewModel = PlayerViewModel.init()

    private var speechPlayer: SpeechPlayerProtocol
    var controlBarViewModel: ControlBarViewModel

    @Published private(set) var videoAttributes: VideoAttributesEntity = VideoAttributesEntity.zero
    @Published private(set) var videoPlayer: AVPlayerWrapperProtocol

    @Published private(set) var speechSentence: String = ""
    @Published private(set) var baseSentence: String = ""
    @Published private(set) var showSpeechSentence: Bool = true
    @Published private(set) var showBaseSentence: Bool = true
    @Published private(set) var currentPhraseIndex: Int = 0
    @Published var isThmbnailedPlayer: Bool = false
    private(set) var translatedPhrases: SpeechPhraseList = SpeechPhraseList.zero
    private var basePhrases: SpeechPhraseList = SpeechPhraseList.zero

    // PlayerのController
    @Published private(set) var isShowingController: Bool = true

    @Published var isTouchingScreen: Bool = false // touchが外れてから3秒後にコントロールを隠す
    @Published private(set) var isHoveringScreen: Bool = false // hoverが外れてから3秒後にコントロールを隠す

    private var settingsUseCase: SettingsUseCase
    private var syncPlayUseCase: SyncPlayUseCase
    private var fileAccesUseCase: FileAccessUseCaseProtocol

    private var cancellables: [AnyCancellable] = []

    private let prefferdTimeScale: CMTimeScale = 60

    init(fileAccesUseCase: FileAccessUseCaseProtocol = FileAccessUseCase(),
         settingsUseCase: SettingsUseCase = SettingsUseCase.shared,
         syncPlayUseCase: SyncPlayUseCase = SyncPlayUseCase(),
         videoPlayer: AVPlayerWrapperProtocol = AVPlayerWrapper(avPlayer: AVPlayer()),
         speechPlayer: SpeechPlayerProtocol = SpeechPlayer(voiceId: "", volume: 1.0),
         videoDetailEntity: VideoDetailEntity? = nil) {
        self.settingsUseCase = settingsUseCase
        self.fileAccesUseCase = fileAccesUseCase
        self.videoPlayer = videoPlayer
        self.speechPlayer = speechPlayer

        self.syncPlayUseCase = syncPlayUseCase
        self.syncPlayUseCase.setPhrases(phrases: SpeechPhraseList.zero)

        self.controlBarViewModel = ControlBarViewModel(syncPlayUseCase: self.syncPlayUseCase)

        setupBindings()

        if let videoDetailEntity = videoDetailEntity {
            self.setupPlayer(detail: videoDetailEntity)
        }

        self.speechPlayer.delegate = self
    }

    private func setupBindings() {
        settingsUseCase.$speechVolume.sink { [weak self] value in
            self?.speechPlayer.setVolume(volume: Float(value))
        }
        .store(in: &cancellables)
        settingsUseCase.$speechRate.sink { [weak self] value in
            self?.speechPlayer.setRate(rate: value)
        }
        .store(in: &cancellables)
        settingsUseCase.$videoVolume.sink { [weak self] value in
            self?.videoPlayer.volume = Float(value)
        }
        .store(in: &cancellables)
        settingsUseCase.$videoRate.sink { [weak self] value in
            guard let self = self,
                  self.videoPlayer.rate > 0 else { return } // 停止中はrateを変えない
            self.videoPlayer.rate = Float(value) // rateはplayの直後に再設定する必要がある
        }
        .store(in: &cancellables)
        settingsUseCase.$showOriginalText.sink { [weak self] value in
            self?.showBaseSentence = value
        }
        .store(in: &cancellables)
        settingsUseCase.$showTransferdText.sink { [weak self] value in
            self?.showSpeechSentence = value
        }
        .store(in: &cancellables)

        settingsUseCase.$voiceId.sink { [weak self] voiceId in
            self?.speechPlayer.setVoice(voiceId: voiceId)
            self?.syncPlayUseCase.isSpeechActive = self?.speechPlayer.isActive ?? false
        }
        .store(in: &cancellables)

        // 画面に触ったらボタンを表示し、3秒間触らなければボタンを隠す
        $isTouchingScreen.merge(with: $isHoveringScreen)
            .debounce(for: .seconds(3.0), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.isShowingController = false
            }
            .store(in: &cancellables)
        $isTouchingScreen.merge(with: $isHoveringScreen)
            .filter { $0 }
            .sink { [weak self] _ in
                if self?.isShowingController == false {
                    self?.isShowingController = true
                }
            }
            .store(in: &cancellables)

        // videoPlayerを入れ替えたら、callBackを再設定する
        $videoPlayer.sink { [weak self] newPlayer in
            guard let self = self else { return }
            var player = newPlayer
            player.timeChanged = { cmTime in
                self.syncPlayUseCase.timeObserved(cmTime: cmTime)
            }
            self.syncPlayUseCase.videoDuration = player.duration.seconds
        }
        .store(in: &cancellables)

        syncPlayUseCase.$syncPlayModel.sink { [weak self] newState in
            guard let self = self,
                  self.syncPlayUseCase.syncPlayModel != newState else { return }
            let preState = self.syncPlayUseCase.syncPlayModel
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
                videoPlayer.play()
                videoPlayer.rate = settingsUseCase.videoRate
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
        DispatchQueue.main.async {
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
