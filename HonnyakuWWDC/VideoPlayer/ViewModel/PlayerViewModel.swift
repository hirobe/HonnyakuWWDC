//  PlayerViewModel.swift

import SwiftUI
import Combine
import AVKit

class PlayerViewModel: ObservableObject {
    typealias ControllerInfo = SyncPlayModel.ControllerInfo
    typealias SeekInfo = SyncPlayModel.ControllerInfo.SeekInfo
    typealias SyncState = SyncPlayModel.SyncState

    @Published private(set) var translated: TranscriptEntity = .zero
    @Published private(set) var baseTranscript: TranscriptEntity = .zero
    @Published private(set) var videoAttributes: VideoAttributesEntity = VideoAttributesEntity.zero
    @Published private(set) var videoPlayer: AVPlayerWrapperProtocol
    private var speechPlayer: SpeechPlayerProtocol

    @Published private(set) var speechSentence: String = ""
    @Published private(set) var baseSentence: String = ""
    @Published private(set) var showSpeechSentence: Bool = true
    @Published private(set) var showBaseSentence: Bool = true

    // PlayerのController
    @Published var isPlaying: Bool = false
    @Published private(set) var isShowingController: Bool = true
    @Published var sliderPosition: Float = 0.0
    @Published var sliderDragging: SliderDraggingInfo = SliderDraggingInfo(isDragging: false, position: 0.0)

    struct SliderDraggingInfo {
        var isDragging: Bool
        var position: Float
    }

    @Published var sliderLeftTime: String = "00:00"
    @Published var sliderRightTime: String = "00:00"

    @Published var isTouchingScreen: Bool = false // touchが外れてから3秒後にコントロールを隠す
    @Published private(set) var isHoveringScreen: Bool = false // hoverが外れてから3秒後にコントロールを隠す

    private var settingsUseCase: SettingsUseCase
    private var syncPlayUseCase: SyncPlayUseCase
    private var fileAccesUseCase: FileAccessUseCaseProtocol

    private var translatedPhrases: SpeechPhraseList = SpeechPhraseList.zero
    private var basePhrases: SpeechPhraseList = SpeechPhraseList.zero

    private var cancellables: [AnyCancellable] = []

    private let prefferdTimeScale: CMTimeScale = 60

    let timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        return formatter
    }()

    init(fileAccesUseCase: FileAccessUseCaseProtocol = FileAccessUseCase(),
         settingsUseCase: SettingsUseCase = SettingsUseCase.shared,
         syncPlayUseCase: SyncPlayUseCase = SyncPlayUseCase(),
         videoPlayer: AVPlayerWrapperProtocol = AVPlayerWrapper(avPlayer: AVPlayer()),
         speechPlayer: SpeechPlayerProtocol = SpeechPlayer(voiceId: "", volume: 1.0),
         videoId: String? = nil) {
        self.settingsUseCase = settingsUseCase
        self.fileAccesUseCase = fileAccesUseCase
        self.videoPlayer = videoPlayer

        self.speechPlayer = speechPlayer

        self.syncPlayUseCase = syncPlayUseCase
        self.syncPlayUseCase.setPhrases(phrases: SpeechPhraseList.zero)

        setupBindings()

        if let videoId = videoId {
            try? loadFromVideoId(videoId: videoId)
        }

        self.speechPlayer.delegate = self
    }

    func setupBindings() {
        settingsUseCase.$speechVolume.sink { [weak self] value in
            self?.speechPlayer.setVolume(volume: Float(value))
        }
        .store(in: &cancellables)
        settingsUseCase.$videoVolume.sink { [weak self] value in
            self?.videoPlayer.volume = Float(value)
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

        $isPlaying.sink { [weak self] playing in
            if playing {
                self?.playStart()
            } else {
                self?.pause()
            }
        }
        .store(in: &cancellables)

        $sliderDragging.sink { [weak self] value in
            guard let self = self else { return }
            if value.isDragging {
                self.seeking(progress: value.position)
                self.sliderPosition = value.position
            } else if self.sliderDragging.isDragging == true {
                self.finishSeek(progress: value.position)
                self.sliderPosition = value.position
            }
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
                self.timeObserved(cmTime: cmTime)
            }
            self.updateDuration(duration: player.duration.seconds)
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

    func loadFromVideoId(videoId: String) throws {
        let data = try fileAccesUseCase.loadFileFromDocuments(path: "\(videoId)_\(settingsUseCase.languageShortLower).json")
        let detail = try JSONDecoder().decode(VideoDetailEntity.self, from: data)

        setupPlayer(detail: detail)
    }

    func showDocumentFolder() {
        print(fileAccesUseCase.documentDirectoryPath ?? "")
    }

    func pasteData() -> Bool {
        guard let text = UIPasteboard.general.string else { return false }
        guard let data = text.data(using: .utf8),
              let detail = try? JSONDecoder().decode(VideoDetailEntity.self, from: data) else { return false }

        setupPlayer(detail: detail)
        return true
    }

    func setupPlayer(detail: VideoDetailEntity) {
        translated = detail.translated
        videoAttributes = detail.attributes
        baseTranscript = detail.baseTranscript

        videoPlayer = videoPlayer.generatePlayer(url: self.videoAttributes.videoUrl)
        videoPlayer.volume = Float(settingsUseCase.videoVolume)

        translatedPhrases = SpeechPhrase.makePhrases(from: self.translated)
        basePhrases = SpeechPhrase.makePhrases(from: baseTranscript)
        speechPlayer.setPhrases(phrases: translatedPhrases)
        syncPlayUseCase.setPhrases(phrases: translatedPhrases)

    }

    func updateDuration(duration: Double) {
        syncPlayUseCase.videoDuration = duration
        // seekBarを更新
        if duration != 0 {
            self.sliderRightTime = self.createTimeString(time: duration)
        }

    }

    func timeObserved(cmTime: CMTime) {
        syncPlayUseCase.timeObserved(cmTime: cmTime)

        // seekBarを更新
        if syncPlayUseCase.videoDuration > 0 {
            self.sliderPosition = Float(cmTime.seconds / syncPlayUseCase.videoDuration)
        }
        self.sliderLeftTime = self.createTimeString(time: cmTime.seconds)
    }

    func playStart() {
        syncPlayUseCase.play()
    }

    func pause() {
        syncPlayUseCase.pause()
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

    func seeking(progress: Float) {
        syncPlayUseCase.seeking(progress: progress)
    }

    func finishSeek(progress: Float) {
        syncPlayUseCase.finishSeek(progress: progress)
    }

    func createTimeString(time: Double) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        return timeRemainingFormatter.string(from: components as DateComponents)!
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
        }
    }
}
