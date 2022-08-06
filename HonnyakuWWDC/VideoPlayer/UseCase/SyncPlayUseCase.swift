//  PlayController.swift

import SwiftUI
import Combine
import AVKit

/// SpeechとVideoを同期して動かすための状態管理クラス
/// このクラスは内部で、syncPlayModel状態変数を持ち、ユーザの操作入力を受けて$syncPlayModelを更新します。
/// 実際のSpeechとVideoの操作はこのクラスでは行いません。View ModelでsyncPlayModelを監視して行います
final class SyncPlayUseCase: ObservableObject {
    typealias SyncState = SyncPlayModel.SyncState
    typealias ControllerInfo = SyncPlayModel.ControllerInfo
    typealias SeekInfo = SyncPlayModel.ControllerInfo.SeekInfo

    @Published private(set) var syncPlayModel: SyncPlayModel = .zero
    @Published private(set) var curerntTime: Double = 0.0
    @Published var videoDuration: Double = 0.0

    private var cancellables: [AnyCancellable] = []
    private var speechPhraseList: SpeechPhraseList!
    var isSpeechActive: Bool = true

    var isPlaying: Bool {
        if case .playing = syncPlayModel.controllerInfo {
            return true
        }
        return false
    }

    func clear() {
        syncPlayModel = .zero
        curerntTime = 0.0
        videoDuration = 0.0
        isSpeechActive = true
    }

    func setPhrases(phrases: SpeechPhraseList) {
        self.speechPhraseList = phrases
    }

    func play() {
        syncPlayModel = syncPlayModel.updatedWith(controllerInfo: .playing)
    }

    func pause() {
        syncPlayModel = syncPlayModel.updatedWith(controllerInfo: .pausing)
    }

    func seeking(seconds: Double) {
        let newControllerInfo: ControllerInfo
        switch syncPlayModel.controllerInfo {
        case .playing:
            newControllerInfo = .seeking(seekInfo: SeekInfo(seconds: seconds, inPlaying: true))
        case .pausing:
            newControllerInfo = .seeking(seekInfo: SeekInfo(seconds: seconds, inPlaying: false))
        case let .seeking(info):
            newControllerInfo = .seeking(seekInfo: SeekInfo(seconds: seconds, inPlaying: info.inPlaying))
        }
        syncPlayModel = syncPlayModel.updatedWith(controllerInfo: newControllerInfo)
    }

    func finishSeek(seconds: Double) {
        switch syncPlayModel.controllerInfo {
        case .playing, .pausing:
            seeking(seconds: seconds) // 一旦seekingにする
        default: break
        }

        guard case let .seeking(seekInfo) = syncPlayModel.controllerInfo else { return }

        let index = self.speechPhraseList.prefferIndex(at: seconds)
        syncPlayModel = SyncPlayModel(controllerInfo: seekInfo.inPlaying ? .playing : .pausing,
                              syncState: .bothRunning,
                              phraseIndex: index)
    }

    /// 前のspeechが終了した
    func didFinishPreSpeechPhrase(videoAt: Double) {
        // videoの時刻と比べる
        if let nextPhraseStartAt = speechPhraseList.nextPhraseStartAt(),
           nextPhraseStartAt - videoAt > 3 {
            // speechが3秒以上先行したらspeechをwait
            syncPlayModel = SyncPlayModel(controllerInfo: syncPlayModel.controllerInfo,
                                          syncState: .speechWaiting,
                                          phraseIndex: syncPlayModel.phraseIndex)
        } else {
            syncPlayModel = SyncPlayModel(controllerInfo: syncPlayModel.controllerInfo,
                                       syncState: .bothRunning,
                                       phraseIndex: syncPlayModel.phraseIndex+1)
        }
    }

    /// videoの再生中0.5秒ごとに呼ばれる
    func timeObserved(cmTime: CMTime) {
        self.curerntTime = cmTime.seconds
        if speechPhraseList.isTimeToPlayNext(index: syncPlayModel.phraseIndex, time: cmTime.seconds) {
            didComeNextPhraseTime(at: cmTime.seconds, nextPhraseIndex: syncPlayModel.phraseIndex+1)
        }
    }

    private func didComeNextPhraseTime(at: Double, nextPhraseIndex: Int) {
        if !isSpeechActive {
            // speechPlayerが無効の場合、時間が来たら強制的に次のフレーズに移動します。
            syncPlayModel = SyncPlayModel(controllerInfo: .playing,
                                       syncState: .bothRunning,
                                       phraseIndex: nextPhraseIndex)

        } else {
            switch syncPlayModel.controllerInfo {
            case .playing:
                if syncPlayModel.syncState == .speechWaiting {
                    // speechが待ちの場合は、待ちを解除して次のフレーズに移動します
                    syncPlayModel = SyncPlayModel(controllerInfo: .playing,
                                               syncState: .bothRunning,
                                               phraseIndex: nextPhraseIndex)

                } else if speechPhraseList.currentIndex < nextPhraseIndex {
                    // speechが遅れているならVideoをwait
                    // (synthesizer.isSpeaking) がfalseなら待つのをやめるべき

                    syncPlayModel = SyncPlayModel(controllerInfo: .playing,
                                               syncState: .videoWaiting,
                                               phraseIndex: syncPlayModel.phraseIndex)
                }
            default:
                break
            }
        }
    }

    func videoTime(progress: Float) -> Double {
        return videoDuration * Double(progress)
    }
}
