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
            SpeechPhrase(id:0, at: 0, text: "The first phrase. ", isParagraphFirst: true),
            SpeechPhrase(id:0, at: 10, text: "The second phrase. ", isParagraphFirst: false),
            SpeechPhrase(id:0, at: 20, text: "The last phrase. ", isParagraphFirst: false)
        ])

        var lastSyncPlayModel: SyncPlayModel = SyncPlayModel.zero

        let useCase = SyncPlayUseCase()
        useCase.setPhrases(phrases: phrases)
        useCase.isSpeechActive = true

        useCase.$syncPlayModel.sink { model in
            lastSyncPlayModel = model
        }
        .store(in: &cancellables)

        // ?????? @0???
        useCase.play()
        print(lastSyncPlayModel)
        XCTAssertEqual(lastSyncPlayModel, SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 0))

        // @2???
        useCase.timeObserved(cmTime: CMTime(seconds: 2, preferredTimescale: 1))
        // ??????????????????
        XCTAssertEqual(lastSyncPlayModel, SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 0))

        // @4.5??? ??????Speech:0???????????????
        useCase.didFinishPreSpeechPhrase(videoAt: 4.5)  // speech???????????? @4.5
        // speech???wait
        print(lastSyncPlayModel)
        XCTAssertEqual(lastSyncPlayModel, SyncPlayModel(controllerInfo: .playing, syncState: .speechWaiting, phraseIndex: 0))

        useCase.timeObserved(cmTime: CMTime(seconds: 4, preferredTimescale: 1))
        XCTAssertEqual(lastSyncPlayModel, SyncPlayModel(controllerInfo: .playing, syncState: .speechWaiting, phraseIndex: 0))

        // @10????????????Speech:1?????????
        useCase.timeObserved(cmTime: CMTime(seconds: 10, preferredTimescale: 1))
        // speech???wait??????????????????speech?????????
        print(lastSyncPlayModel)
        XCTAssertEqual(lastSyncPlayModel, SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 1))

        phrases.readyToStart(index: 1)

        // @20??? ??????Speech:2??????????????????Speech:1?????????????????????
        useCase.timeObserved(cmTime: CMTime(seconds: 25, preferredTimescale: 1))
        // speech:1????????????????????????video???wait
        print(lastSyncPlayModel)
        XCTAssertEqual(lastSyncPlayModel, SyncPlayModel(controllerInfo: .playing, syncState: .videoWaiting, phraseIndex: 1))

        // @28??? ????????????Speech:1???????????????
        useCase.timeObserved(cmTime: CMTime(seconds: 28, preferredTimescale: 1))
        useCase.didFinishPreSpeechPhrase(videoAt: 28.5) // speech?????????
        // ??????speech:2?????????
        print(lastSyncPlayModel)
        XCTAssertEqual(lastSyncPlayModel, SyncPlayModel(controllerInfo: .playing, syncState: .bothRunning, phraseIndex: 2))

        phrases.readyToStart(index: 2)

        // @35??? Speech:2???????????????
        useCase.timeObserved(cmTime: CMTime(seconds: 34, preferredTimescale: 1))
        useCase.didFinishPreSpeechPhrase(videoAt: 35) // speech?????????
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
