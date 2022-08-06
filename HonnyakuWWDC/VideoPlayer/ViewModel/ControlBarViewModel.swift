//  ControlBarViewModel.swift

import SwiftUI
import Combine
import AVKit

final class ControlBarViewModel: ObservableObject {
    @Published var sliderPosition: Float = 0.0
    @Published var sliderDragging: SliderDraggingInfo = SliderDraggingInfo(isDragging: false, position: 0.0)
    @Published private(set) var isPlaying: Bool = false

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

    @Published var sliderLeftTime: String = "00:00"
    @Published var sliderRightTime: String = "00:00"

    private var syncPlayUseCase: SyncPlayUseCase

    private var cancellables: [AnyCancellable] = []

    init(syncPlayUseCase: SyncPlayUseCase = SyncPlayUseCase()) {

        self.syncPlayUseCase = syncPlayUseCase

        setupBindings()

    }
    private func setupBindings() {
        syncPlayUseCase.$syncPlayModel.sink { [weak self] syncPlayModel in
            if case .playing = syncPlayModel.controllerInfo {
                self?.isPlaying = true
            } else {
                self?.isPlaying = false
            }
        }
        .store(in: &cancellables)

        $sliderDragging.sink { [weak self] value in
            guard let self = self else { return }
            if value.isDragging {
                self.seeking(seconds: self.syncPlayUseCase.videoTime(progress: value.position))
                self.sliderPosition = value.position
            } else if self.sliderDragging.isDragging == true {
                self.finishSeek(seconds: self.syncPlayUseCase.videoTime(progress: value.position))
                self.sliderPosition = value.position
            }
        }
        .store(in: &cancellables)

        syncPlayUseCase.$curerntTime.sink { [weak self] value in
            guard let self = self else { return }
            self.updateSlider(seconds: value)
            self.showCurrentTime(seconds: value)
        }
        .store(in: &cancellables)

        syncPlayUseCase.$videoDuration.sink { [weak self] value in
            self?.showDuration(duration: value)
        }
        .store(in: &cancellables)
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
