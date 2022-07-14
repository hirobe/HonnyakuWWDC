//  VideoListCellViewModel.swift

import SwiftUI
import Combine

class VideoListCellViewModel: ObservableObject {
    private(set) var video: VideoEntity
    private var progress: ProgressObservable
    @Published private(set) var state: ProgressState = .unknwon

    private var cancellables: [AnyCancellable] = []

    init(video: VideoEntity, progress: ProgressObservable) {
        self.video = video
        self.progress = progress

        progress
            .$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.state = state
            }
            .store(in: &cancellables)
    }

}
