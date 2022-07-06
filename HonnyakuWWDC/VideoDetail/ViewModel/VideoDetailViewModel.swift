//  VideoDetailViewModel.swift

import SwiftUI
import Combine

/// VideoDetailViewのViewModel
class VideoDetailViewModel: ObservableObject {
    var transferUserCase: TranslateCaseProtocol
    var progressUseCase: TaskProgressUseCaseProtocol

    @Published var progressState: ProgressState = .unknwon
    private var cancellables: [AnyCancellable] = []

    @Published var showPlayerIfEnabled: Bool = true
    @Published var errorMessage: String = ""

    var videoId: String
    var url: URL
    var title: String

    init(transferUserCase: TranslateCaseProtocol = TranslateUseCase(),
         progressUseCase: TaskProgressUseCaseProtocol = TaskProgressUseCase(),
         videoId: String, url: URL, title: String
    ) {
        self.transferUserCase = transferUserCase
        self.progressUseCase = progressUseCase

        self.videoId = videoId
        self.url = url
        self.title = title

        progressUseCase.fetchObservable(taskId: videoId).$state
            .receive(on: DispatchQueue.main)
            .sink {[weak self] state in
                if state == .unknwon {
                    self?.progressState = .notStarted
                } else {
                    self?.progressState = state
                }
            }
            .store(in: &cancellables)
    }

    func transfer() async {
        do {
            try await transferUserCase.translateVideoDetail(id: videoId, url: url)
        } catch {
            Task { @MainActor in
                errorMessage = error.localizedDescription
            }
        }
    }

    func copyDataToPasteBoard() -> Bool {
        if let text = transferUserCase.makeClipText(id: videoId) {
            UIPasteboard.general.string = text
            return true
        }
        return false
    }
}
