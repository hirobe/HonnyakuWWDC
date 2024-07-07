//  VideoListCellViewModel.swift

import SwiftUI
import Observation

@Observable final class VideoListCellViewModel {
    private(set) var video: VideoEntity
    private var progress: ProgressObservable
    private(set) var state: ProgressState

    init(video: VideoEntity, progress: ProgressObservable) {
        self.video = video
        self.progress = progress
        self.state = progress.state

        setupObservation()
    }

    private func setupObservation() {
        withObservationTracking { [weak self] in
            _ = self?.progress.state
        } onChange: {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.state = self.progress.state
                self.setupObservation()
            }
        }
    }
}
