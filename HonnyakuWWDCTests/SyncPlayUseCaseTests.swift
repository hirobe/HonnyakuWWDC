//  SyncPlayUseCaseTests.swift

import Testing
@testable import HonnyakuWWDC
import AVKit

struct SyncPlayUseCaseTests {
    typealias Paragraph = TranscriptEntity.Paragraph
    typealias Sentence = Paragraph.Sentence
    typealias SeekInfo = SyncPlayModel.ControllerInfo.SeekInfo

    class AVPlayerWrapperDumy: AVPlayerWrapperProtocol {
        var timeChanged: ((CMTime) -> Void)?
        var currentTimeValue: Double = 0 {
            didSet {
                timeChanged?(CMTime(seconds: currentTimeValue, preferredTimescale: 1) )
            }
        }

        var lastCommand: String = ""
        var lastCommandArg: String = ""

        var avPlayer: AVPlayer { fatalError() }
        var volume: Float = 1.0
        var rate: Float = 1.0
        var duration: CMTime = CMTime.zero
        func generatePlayer(url: URL?) -> HonnyakuWWDC.AVPlayerWrapperProtocol {
            return AVPlayerWrapperDumy()
        }
        func currentTime() -> CMTime { CMTime(seconds: currentTimeValue, preferredTimescale: 1) }
        func play() { lastCommand = "play" }
        func pause() { lastCommand = "pause" }
        func seek(to time: CMTime) async -> Bool {
            lastCommand = "seek"
            lastCommandArg = "\(time.seconds)"
            return true
        }
        func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) {
            lastCommand = "seek2"
            lastCommandArg = "\(time.seconds)"
        }
        func refreshPlayer(size: CGSize) {}
    }
    class SpeechPlayerDumy: SpeechPlayerProtocol {
        var lastCommand: String = ""
        var lastCommandArg: String = ""

        var isActive: Bool = true
        var delegate: SpeakDelegate?
        func setPhrases(phrases: SpeechPhraseList) {}
        func setVoice(voiceId: String) {}
        func setVolume(volume: Float) {}
        func setRate(rate: Float) {}

        func restart() { lastCommand = "restart" }
        func pause() { lastCommand = "pause" }
        func stop() { lastCommand = "stop" }
    }

    init() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

    }


    @Test mutating func simplePlay() throws {
        let phrases = SpeechPhraseList(phrases: [
            SpeechPhrase(id: 0, at: 0, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 1, at: 10, text: "The second phrase. ", isParagraphFirst: false),
            SpeechPhrase(id: 2, at: 20, text: "The last phrase. ", isParagraphFirst: false)
        ])

        var lastSyncPlayModel: SyncPlayModel = SyncPlayModel.zero

        let useCase = SyncPlayUseCase()
        useCase.setPhrases(phrases: phrases)
        useCase.isSpeechActive = true

        withObservationTracking {
            lastSyncPlayModel = useCase.syncPlayModel
        } onChange: {
            Task { @MainActor in
                lastSyncPlayModel = useCase.syncPlayModel
            }
        }

        // 開始 @0秒
        useCase.play()
        print(lastSyncPlayModel)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 0))

        // @2秒
        useCase.timeObserved(cmTime: CMTime(seconds: 2, preferredTimescale: 1))
        // 状態変化なし
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 0))

        // @4.5秒 先にSpeech:0が終わった
        useCase.didFinishPreSpeechPhrase(videoAt: 4.5)  // speech終わった @4.5
        // speechをwait
        print(lastSyncPlayModel)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .speechWaiting, phraseIndex: 0))

        useCase.timeObserved(cmTime: CMTime(seconds: 4, preferredTimescale: 1))
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .speechWaiting, phraseIndex: 0))

        // @10秒　次のSpeech:1の時間
        useCase.timeObserved(cmTime: CMTime(seconds: 10, preferredTimescale: 1))
        // speechをwait終了し、次のspeechを開始
        print(lastSyncPlayModel)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 1))

        phrases.readyToStart(index: 1)

        // @20秒 次のSpeech:2の時間。だがSpeech:1が終わってない
        useCase.timeObserved(cmTime: CMTime(seconds: 25, preferredTimescale: 1))
        // speech:1が終わってない。videoをwait
        print(lastSyncPlayModel)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .videoWaiting, phraseIndex: 1))

        // @28秒 ようやくSpeech:1が終わった
        useCase.timeObserved(cmTime: CMTime(seconds: 28, preferredTimescale: 1))
        useCase.didFinishPreSpeechPhrase(videoAt: 28.5) // speech終わり
        // 次のspeech:2を開始
        print(lastSyncPlayModel)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 2))

        phrases.readyToStart(index: 2)

        // @35秒 Speech:2が終わった
        useCase.timeObserved(cmTime: CMTime(seconds: 34, preferredTimescale: 1))
        useCase.didFinishPreSpeechPhrase(videoAt: 35) // speech終わり
        print(lastSyncPlayModel)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 3))
    }

    @Test mutating func pauseOnBothPlaying() throws {
        let phrases = SpeechPhraseList(phrases: [
            SpeechPhrase(id: 0, at: 0, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 1, at: 20, text: "The second phrase. ", isParagraphFirst: false)
        ])

        var lastSyncPlayModel: SyncPlayModel = SyncPlayModel.zero

        let syncPlayUseCase = SyncPlayUseCase()
        syncPlayUseCase.setPhrases(phrases: phrases)
        syncPlayUseCase.isSpeechActive = true

        withObservationTracking {
            lastSyncPlayModel = syncPlayUseCase.syncPlayModel
        } onChange: {
            Task { @MainActor in
                lastSyncPlayModel = syncPlayUseCase.syncPlayModel
            }
        }

        syncPlayUseCase.play()
        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 0, preferredTimescale: 1000000000))

        // 両方再生中ににpause, play
        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 3, preferredTimescale: 1000000000))
        syncPlayUseCase.pause()
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .pausing, syncState: .bothRunning, phraseIndex: 0))

        syncPlayUseCase.play()
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 0))
    }

    @Test mutating func pauseOnSpeechWaiting() throws {
        let phrases = SpeechPhraseList(phrases: [
            SpeechPhrase(id: 0, at: 0, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 1, at: 9, text: "The second phrase. ", isParagraphFirst: false),
            SpeechPhrase(id: 2, at: 18, text: "The 3rd phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 3, at: 22, text: "The 4th phrase. ", isParagraphFirst: false)
        ])

        var lastSyncPlayModel: SyncPlayModel = SyncPlayModel.zero

        let syncPlayUseCase = SyncPlayUseCase()
        syncPlayUseCase.setPhrases(phrases: phrases)
        syncPlayUseCase.isSpeechActive = true

        withObservationTracking {
            lastSyncPlayModel = syncPlayUseCase.syncPlayModel
        } onChange: {
            Task { @MainActor in
                lastSyncPlayModel = syncPlayUseCase.syncPlayModel
            }
        }

        syncPlayUseCase.play()
        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 0, preferredTimescale: 1000000000))
        syncPlayUseCase.didFinishPreSpeechPhrase(videoAt: 1.087414667)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .speechWaiting, phraseIndex: 0))

        // speechがwaiting中にpause, play
        syncPlayUseCase.pause()
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .pausing, syncState: .speechWaiting, phraseIndex: 0))

        // videoがplaying, speechがwaitingになること
        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 4.0526, preferredTimescale: 90000))
        syncPlayUseCase.play()
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .speechWaiting, phraseIndex: 0))

        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 9.001282165, preferredTimescale: 1000000000))
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 1))
        phrases.readyToStart(index: 1)

        syncPlayUseCase.didFinishPreSpeechPhrase(videoAt: 16.354690665)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 2))
        phrases.readyToStart(index: 2)
    }

    @Test mutating func pauseOnVideoWaiting() throws {
        let phrases = SpeechPhraseList(phrases: [
            SpeechPhrase(id: 0, at: 0, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 1, at: 5, text: "The second phrase. ", isParagraphFirst: false)
        ])

        var lastSyncPlayModel: SyncPlayModel = SyncPlayModel.zero

        let syncPlayUseCase = SyncPlayUseCase()
        syncPlayUseCase.setPhrases(phrases: phrases)
        syncPlayUseCase.isSpeechActive = true

        withObservationTracking {
            lastSyncPlayModel = syncPlayUseCase.syncPlayModel
        } onChange: {
            Task { @MainActor in
                lastSyncPlayModel = syncPlayUseCase.syncPlayModel
            }
        }

        syncPlayUseCase.play()
        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 0, preferredTimescale: 1000000000))
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 0))
        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 7, preferredTimescale: 1000000000))
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .videoWaiting, phraseIndex: 0))

        // pause, play
        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 8, preferredTimescale: 1000000000))
        syncPlayUseCase.pause()
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .pausing, syncState: .videoWaiting, phraseIndex: 0))

        syncPlayUseCase.play()
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .videoWaiting, phraseIndex: 0))

        syncPlayUseCase.didFinishPreSpeechPhrase(videoAt: 9)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 1))
        phrases.readyToStart(index: 1)
    }

    @Test mutating func seekOnPlaying() throws {
        let phrases = SpeechPhraseList(phrases: [
            SpeechPhrase(id: 0, at: 0, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 1, at: 9, text: "The second phrase. ", isParagraphFirst: false),
            SpeechPhrase(id: 2, at: 18, text: "The 3rd phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 3, at: 22, text: "The 4th phrase. ", isParagraphFirst: false),
            SpeechPhrase(id: 4, at: 31, text: "The 4th phrase. ", isParagraphFirst: false),
            SpeechPhrase(id: 5, at: 37, text: "The 4th phrase. ", isParagraphFirst: false),
            SpeechPhrase(id: 6, at: 43, text: "The 4th phrase. ", isParagraphFirst: false),
            SpeechPhrase(id: 7, at: 51, text: "The 4th phrase. ", isParagraphFirst: false),
            SpeechPhrase(id: 8, at: 59, text: "The 4th phrase. ", isParagraphFirst: false),

            SpeechPhrase(id: 9, at: 67, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 10, at: 77, text: "The first phrase. ", isParagraphFirst: true),

            SpeechPhrase(id: 11, at: 83, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 12, at: 90, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 13, at: 110, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 14, at: 113, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 15, at: 120, text: "The first phrase. ", isParagraphFirst: true)
        ])

        var lastSyncPlayModel: SyncPlayModel = SyncPlayModel.zero

        let syncPlayUseCase = SyncPlayUseCase()
        syncPlayUseCase.setPhrases(phrases: phrases)
        syncPlayUseCase.isSpeechActive = true

        withObservationTracking {
            lastSyncPlayModel = syncPlayUseCase.syncPlayModel
            phrases.readyToStart(index: lastSyncPlayModel.phraseIndex)
        } onChange: {
            Task { @MainActor in
                lastSyncPlayModel = syncPlayUseCase.syncPlayModel
                phrases.readyToStart(index: lastSyncPlayModel.phraseIndex)
            }
        }

        syncPlayUseCase.play()
        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 0.0, preferredTimescale: 1))
        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 0.500520417, preferredTimescale: 1000000000))

        // 再生中に前方へシーク
        syncPlayUseCase.seeking(seconds: 35.00300821658969)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .seeking(seekInfo: SeekInfo(seconds: 35.00300821658969, inPlaying: true)), syncState: .bothRunning, phraseIndex: 0))
        syncPlayUseCase.finishSeek(seconds: 35.00300821658969)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 4))

        syncPlayUseCase.didFinishPreSpeechPhrase(videoAt: 43.014901375)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 5))

        // 再生中に後方へシーク
        syncPlayUseCase.seeking(seconds: 22.536466129794718)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .seeking(seekInfo: SeekInfo(seconds: 22.536466129794718, inPlaying: true)), syncState: .bothRunning, phraseIndex: 5))
        syncPlayUseCase.finishSeek(seconds: 24.391114990614355)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 3))

        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 21.054366666666667, preferredTimescale: 90000))
        syncPlayUseCase.didFinishPreSpeechPhrase(videoAt: 24.383333333333333)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .speechWaiting, phraseIndex: 3)) // 移動後はSpeechが待ちになることがある // 移動後はSpeechが待ちになることがある
        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 31.000587833, preferredTimescale: 1000000000))
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 4))
    }

    @Test mutating func seekOnPausing() throws {
        let phrases = SpeechPhraseList(phrases: [
            SpeechPhrase(id: 0, at: 0, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 1, at: 9, text: "The second phrase. ", isParagraphFirst: false),
            SpeechPhrase(id: 2, at: 18, text: "The 3rd phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 3, at: 22, text: "The 4th phrase. ", isParagraphFirst: false),
            SpeechPhrase(id: 4, at: 31, text: "The 4th phrase. ", isParagraphFirst: false),
            SpeechPhrase(id: 5, at: 37, text: "The 4th phrase. ", isParagraphFirst: false),
            SpeechPhrase(id: 6, at: 43, text: "The 4th phrase. ", isParagraphFirst: false),
            SpeechPhrase(id: 7, at: 51, text: "The 4th phrase. ", isParagraphFirst: false),
            SpeechPhrase(id: 8, at: 59, text: "The 4th phrase. ", isParagraphFirst: false),
            SpeechPhrase(id: 9, at: 67, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 10, at: 77, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 11, at: 83, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 12, at: 90, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 13, at: 110, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 14, at: 113, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id: 15, at: 120, text: "The first phrase. ", isParagraphFirst: true)
        ])

        var lastSyncPlayModel: SyncPlayModel = SyncPlayModel.zero

        let syncPlayUseCase = SyncPlayUseCase()
        syncPlayUseCase.setPhrases(phrases: phrases)
        syncPlayUseCase.isSpeechActive = true

        withObservationTracking {
            lastSyncPlayModel = syncPlayUseCase.syncPlayModel
            phrases.readyToStart(index: lastSyncPlayModel.phraseIndex)
        } onChange: {
            Task { @MainActor in
                lastSyncPlayModel = syncPlayUseCase.syncPlayModel
                phrases.readyToStart(index: lastSyncPlayModel.phraseIndex)
            }
        }

        syncPlayUseCase.play()
        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 0.500079125, preferredTimescale: 1000000000))
        syncPlayUseCase.pause()
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .pausing, syncState: .bothRunning, phraseIndex: 0))

        // pauseして前方へシーク
        syncPlayUseCase.seeking(seconds: 100.81166086925566)

        syncPlayUseCase.finishSeek(seconds: 102.17250116623939)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .pausing, syncState: .bothRunning, phraseIndex: 12))
        syncPlayUseCase.didFinishPreSpeechPhrase(videoAt: 102.16666666666667)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .pausing, syncState: .speechWaiting, phraseIndex: 12))

        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 102.102, preferredTimescale: 90000))
        syncPlayUseCase.play()
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .speechWaiting, phraseIndex: 12))
        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 110.0008675, preferredTimescale: 1000000000))
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 13))
        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 112.000786709, preferredTimescale: 1000000000))
        syncPlayUseCase.didFinishPreSpeechPhrase(videoAt: 112.407171209)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 14))

        // pauseして後方へシーク
        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 113.000527459, preferredTimescale: 1000000000))
        syncPlayUseCase.pause()
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .pausing, syncState: .bothRunning, phraseIndex: 14))

        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 113.34753333333333, preferredTimescale: 90000))
        syncPlayUseCase.seeking(seconds: 110.53787093667687)
        syncPlayUseCase.finishSeek(seconds: 62.47180666527152)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .pausing, syncState: .bothRunning, phraseIndex: 8))
        syncPlayUseCase.didFinishPreSpeechPhrase(videoAt: 62.46666666666667)
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .pausing, syncState: .speechWaiting, phraseIndex: 8))
        syncPlayUseCase.play()
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .speechWaiting, phraseIndex: 8))
        syncPlayUseCase.timeObserved(cmTime: CMTime(seconds: 67.001141125, preferredTimescale: 1000000000))
        #expect(lastSyncPlayModel == SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 9))
    }
}
