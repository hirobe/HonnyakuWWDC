//  ControlBarViewModel.swift

import SwiftUI
import AVKit
import Observation

@Observable final class ControlBarViewModel {
    var sliderPosition: Float = 0.0
    var sliderDragging: SliderDraggingInfo = SliderDraggingInfo(isDragging: false, position: 0.0)
    private(set) var isPlaying: Bool = false

    private let timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        return formatter
    }()

    struct SliderDraggingInfo {
        var isDragging: Bool
        var position: Float
    }

    var sliderLeftTime: String = "00:00"
    var sliderRightTime: String = "00:00"

    private var syncPlayUseCase: SyncPlayUseCase

    init(syncPlayUseCase: SyncPlayUseCase = SyncPlayUseCase()) {
        self.syncPlayUseCase = syncPlayUseCase
    }

    func onAppear() {
        startSyncPlayModelObservation()
        startSliderDraggingObservation()
        startCurrentTimeObservation()
        startVideoDurationObservation()
    }

    private func startSyncPlayModelObservation() {
        withObservationTracking {
            _ = syncPlayUseCase.syncPlayModel
        } onChange: {
            Task { @MainActor [weak self] in
                if case .playing = self?.syncPlayUseCase.syncPlayModel.controllerInfo {
                    self?.isPlaying = true
                } else {
                    self?.isPlaying = false
                }
                self?.startSyncPlayModelObservation()
            }
        }
    }
    
    private func startSliderDraggingObservation() {
        withObservationTracking {
            _ = sliderDragging
        } onChange: {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.sliderDragging.isDragging {
                    self.seeking(seconds: self.syncPlayUseCase.videoTime(progress: self.sliderDragging.position))
                    self.sliderPosition = self.sliderDragging.position
                } else {
                    self.finishSeek(seconds: self.syncPlayUseCase.videoTime(progress: self.sliderPosition))
                    self.sliderPosition = self.sliderDragging.position
                }
                self.startSliderDraggingObservation()
            }
        }
    }

    private func startCurrentTimeObservation() {
        withObservationTracking {
            _ = syncPlayUseCase.curerntTime
        } onChange: {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.updateSlider(seconds: self.syncPlayUseCase.curerntTime)
                self.showCurrentTime(seconds: self.syncPlayUseCase.curerntTime)
                self.startCurrentTimeObservation()
            }
        }
    }
    private func startVideoDurationObservation() {
        withObservationTracking {
            _ = syncPlayUseCase.videoDuration
        } onChange: {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.showDuration(duration: self.syncPlayUseCase.videoDuration)
                self.startVideoDurationObservation()
            }
        }
    }


    func playStart() {
        syncPlayUseCase.play()
    }

    func pause() {
        syncPlayUseCase.pause()
    }

    private func seeking(seconds: Double) {
        syncPlayUseCase.seeking(seconds: seconds)
    }

    private func finishSeek(seconds: Double) {
        syncPlayUseCase.finishSeek(seconds: seconds)
    }

    private func showDuration(duration: Double) {
        if duration != 0 {
            self.sliderRightTime = self.createTimeString(time: duration)
        }
    }

    private func showCurrentTime(seconds: Double) {
        self.sliderLeftTime = self.createTimeString(time: seconds)
    }

    private func updateSlider(seconds: Double) {
        if syncPlayUseCase.videoDuration > 0 {
            self.sliderPosition = Float(seconds / syncPlayUseCase.videoDuration)
        }
    }

    private func createTimeString(time: Double) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        return timeRemainingFormatter.string(from: components as DateComponents)!
    }
}
