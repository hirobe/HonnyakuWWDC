//  VideoDetailViewModel.swift

import SwiftUI
import Combine

/// VideoDetailViewのViewModel
class VideoDetailViewModel: ObservableObject {
    private var transferUserCase: TranslateCaseProtocol
    private var progressUseCase: TaskProgressUseCaseProtocol

    @Published var showPlayerIfEnabled: Bool = true
    @Published private(set) var progressState: ProgressState = .unknwon
    @Published private(set) var errorMessage: String = ""
    private(set) var videoId: String
    private(set) var url: URL
    private(set) var title: String

    private var cancellables: [AnyCancellable] = []

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

    /// translate がスレッド待ちですぐに始まらないので、先にprogressStateだけ開始してボタンを非表示にする
    func startTransferStart() {
        transferUserCase.startTranslateVideoDetailState(id: videoId)
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
