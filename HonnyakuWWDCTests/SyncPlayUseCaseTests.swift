//  SyncPlayUseCaseTests.swift

import XCTest
@testable import HonnyakuWWDC
import AVKit
import Combine

final class SyncPlayUseCaseTests: XCTestCase {
    typealias Paragraph = TranscriptEntity.Paragraph
    typealias Sentence = Paragraph.Sentence

    private var cancellables: [AnyCancellable] = []

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
        var volume: Float = 0.0
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
    }
    class SpeechPlayerDumy: SpeechPlayerProtocol {
        var lastCommand: String = ""
        var lastCommandArg: String = ""

        var isActive: Bool = true
        var delegate: SpeakDelegate?
        func setPhrases(phrases: SpeechPhraseList) {}
        func setVoice(voiceId: String) {}
        func setVolume(volume: Float) {}

        func restart() { lastCommand = "restart" }
        func pause() { lastCommand = "pause" }
        func stop() { lastCommand = "stop" }
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSimplePlay() throws {
        let phrases = SpeechPhraseList(phrases: [
            SpeechPhrase(at: 0, text: "The first phrase. "),
            SpeechPhrase(at: 10, text: "The second phrase. "),
            SpeechPhrase(at: 20, text: "The last phrase. ")
        ])

        var lastSyncPlayModel: SyncPlayModel = SyncPlayModel.zero

        let useCase = SyncPlayUseCase()
        useCase.setPhrases(phrases: phrases)
        useCase.isSpeechActive = true

        useCase.$syncPlayModel.sink { model in
            lastSyncPlayModel = model
        }
        .store(in: &cancellables)

        // 開始 @0秒
        useCase.play()
        print(lastSyncPlayModel)
        XCTAssertEqual(lastSyncPlayModel, SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 0))

        // @2秒
        useCase.timeObserved(cmTime: CMTime(seconds: 2, preferredTimescale: 1))
        // 状態変化なし
        XCTAssertEqual(lastSyncPlayModel, SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 0))

        // @4.5秒 先にSpeech:0が終わった
        useCase.didFinishPreSpeechPhrase(videoAt: 4.5)  // speech終わった @4.5
        // speechをwait
        print(lastSyncPlayModel)
        XCTAssertEqual(lastSyncPlayModel, SyncPlayModel(controllerInfo: .playing, syncState: .speechWaiting, phraseIndex: 0))

        useCase.timeObserved(cmTime: CMTime(seconds: 4, preferredTimescale: 1))
        XCTAssertEqual(lastSyncPlayModel, SyncPlayModel(controllerInfo: .playing, syncState: .speechWaiting, phraseIndex: 0))

        // @10秒　次のSpeech:1の時間
        useCase.timeObserved(cmTime: CMTime(seconds: 10, preferredTimescale: 1))
        // speechをwait終了し、次のspeechを開始
        print(lastSyncPlayModel)
        XCTAssertEqual(lastSyncPlayModel, SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 1))

        phrases.readyToStart(index: 1)

        // @20秒 次のSpeech:2の時間。だがSpeech:1が終わってない
        useCase.timeObserved(cmTime: CMTime(seconds: 25, preferredTimescale: 1))
        // speech:1が終わってない。videoをwait
        print(lastSyncPlayModel)
        XCTAssertEqual(lastSyncPlayModel, SyncPlayModel(controllerInfo: .playing, syncState: .videoWaiting, phraseIndex: 1))

        // @28秒 ようやくSpeech:1が終わった
        useCase.timeObserved(cmTime: CMTime(seconds: 28, preferredTimescale: 1))
        useCase.didFinishPreSpeechPhrase(videoAt: 28.5) // speech終わり
        // 次のspeech:2を開始
        print(lastSyncPlayModel)
        XCTAssertEqual(lastSyncPlayModel, SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 2))

        phrases.readyToStart(index: 2)

        // @35秒 Speech:2が終わった
        useCase.timeObserved(cmTime: CMTime(seconds: 34, preferredTimescale: 1))
        useCase.didFinishPreSpeechPhrase(videoAt: 35) // speech終わり
        print(lastSyncPlayModel)
        XCTAssertEqual(lastSyncPlayModel, SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 3))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
