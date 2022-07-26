//  VideoDetailViewModel.swift

import SwiftUI
import Combine

/// VideoDetailViewのViewModel
final class VideoDetailViewModel: ObservableObject {
    private var videoDetailUseCase: VideoDetailUseCase
    private var transferUserCase: TranslateCaseProtocol
    private var progressUseCase: TaskProgressUseCaseProtocol

    @Published var showPlayerIfEnabled: Bool
    @Published private(set) var progressState: ProgressState = .unknwon
    @Published private(set) var errorMessage: String = ""

    @Published private(set) var playerViewModel: PlayerViewModel = .empty

    private(set) var videoId: String
    private(set) var url: URL
    private(set) var title: String

    private var cancellables: [AnyCancellable] = []

    init(videoDetailUseCase: VideoDetailUseCase = VideoDetailUseCase(),
         transferUserCase: TranslateCaseProtocol = TranslateUseCase(),
         progressUseCase: TaskProgressUseCaseProtocol = TaskProgressUseCase(),
         videoId: String, url: URL, title: String,
         showPlayerIfEnabled: Bool = true
    ) {
        self.videoDetailUseCase = videoDetailUseCase
        self.transferUserCase = transferUserCase
        self.progressUseCase = progressUseCase

        self.videoId = videoId
        self.url = url
        self.title = title
        self.showPlayerIfEnabled = showPlayerIfEnabled

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

        $progressState.receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] value in
                guard let self else { return }
                if value == .completed {
                    let detail = self.loadVideoDetailFromVideoId(videoId: self.videoId)
                    self.playerViewModel = PlayerViewModel(videoDetailEntity: detail)
                }
            }
            .store(in: &cancellables)
    }

    /// translate がスレッド待ちですぐに始まらないので、先にprogressStateだけ開始してボタンを非表示にする
    func startTransferStart() {
        transferUserCase.startTranslateVideoDetailState(id: videoId)
    }

    func transfer() async {
        Task.detached {
            do {
                try await self.transferUserCase.translateVideoDetail(id: self.videoId, url: self.url)
            } catch {
                Task { @MainActor in
                    self.errorMessage = error.localizedDescription
                }
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

    func loadVideoDetailFromVideoId(videoId: String) -> VideoDetailEntity? {
        return try? videoDetailUseCase.loadVideoDetailFromVideoId(videoId: videoId)
    }
}
