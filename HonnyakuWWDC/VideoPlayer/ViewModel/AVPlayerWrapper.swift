//  AVPlayerWrapper.swift

import Foundation
import AVKit

protocol AVPlayerWrapperProtocol {
    var avPlayer: AVPlayer { get }
    var volume: Float { get set }
    var rate: Float { get set }
    var duration: CMTime { get }
    var timeChanged: ((_ cmTime: CMTime) -> Void)? { get set }

    func generatePlayer(url: URL?) -> AVPlayerWrapperProtocol
    func currentTime() -> CMTime
    func play()
    func pause()
    func seek(to time: CMTime) async -> Bool
    func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime)
    func refreshPlayer(size: CGSize)
}

/// AVPlayerのWrapper。
/// addPeriodicTimeObserverを隠蔽してtimeChangedブロックを呼ぶようにしています
final class AVPlayerWrapper: AVPlayerWrapperProtocol {
    let avPlayer: AVPlayer
    var timeChanged: ((_ cmTime: CMTime) -> Void)?

    private var timeObserverToken: Any?

    init(avPlayer: AVPlayer) {
        self.avPlayer = avPlayer

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] cmTime in
            self?.timeChanged?(cmTime)
        }
    }

    deinit {
        if let token = timeObserverToken {
            avPlayer.removeTimeObserver(token)
        }
    }

    // URLを指定したAVPlayerWrapperを作る。initじゃないのはInjectのため
    func generatePlayer(url: URL?) -> AVPlayerWrapperProtocol {
        if let url = url {
            return AVPlayerWrapper(avPlayer: AVPlayer(url: url))
        }
        return AVPlayerWrapper(avPlayer: AVPlayer())
    }

    var duration: CMTime { return avPlayer.currentItem?.asset.duration ?? CMTime.zero }

    var volume: Float { get { avPlayer.volume } set { avPlayer.volume = newValue }}
    var rate: Float { get { avPlayer.rate } set { avPlayer.rate = newValue }}
    func currentTime() -> CMTime { return avPlayer.currentTime() }
    func play() { avPlayer.play() }
    func pause() { avPlayer.pause() }
    func seek(to time: CMTime) async -> Bool { return await avPlayer.seek(to: time) }
    func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) { avPlayer.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter) }

    func refreshPlayer(size: CGSize) {
        // preferredMaximumResolutionを更新すると、何故か解像度がリフレッシュされるようだ
        avPlayer.currentItem?.preferredMaximumResolution = CGSize(width: size.width * 2.0, height: size.height * 2.0) // 等倍だと若干ボケるので2倍にする
    }
}
