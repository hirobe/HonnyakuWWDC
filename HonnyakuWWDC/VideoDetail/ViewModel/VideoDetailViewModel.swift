//  VideoDetailViewModel.swift

import SwiftUI
import Observation

/// VideoDetailViewのViewModel
@Observable final class VideoDetailViewModel: ObservableObject {
    private var videoDetailUseCase: VideoDetailUseCase
    private var transferUserCase: TranslateCaseProtocol
    private var downloadAudioUserCase: TranslateCaseProtocol
    private var progressUseCase: TaskProgressUseCaseProtocol
    
    var showPlayerIfEnabled: Bool
    private(set) var progressState: ProgressState = .unknwon
    private(set) var errorMessage: String = ""
    
    private(set) var playerViewModel: PlayerViewModel? = nil
    
    private(set) var videoId: String
    private(set) var url: URL
    private(set) var title: String
    
    init(videoDetailUseCase: VideoDetailUseCase = VideoDetailUseCase(),
         transferUserCase: TranslateCaseProtocol = TranslateUseCase(),
         downloadAudioUserCase: TranslateCaseProtocol = DownloadAudioUserCase(),
         progressUseCase: TaskProgressUseCaseProtocol = TaskProgressUseCase(),
         videoId: String, url: URL, title: String,
         showPlayerIfEnabled: Bool = true
    ) {
        self.videoDetailUseCase = videoDetailUseCase
        self.transferUserCase = transferUserCase
        self.downloadAudioUserCase = downloadAudioUserCase
        self.progressUseCase = progressUseCase
        
        self.videoId = videoId
        self.url = url
        self.title = title
        self.showPlayerIfEnabled = showPlayerIfEnabled
    }
    
    func onAppear() {
        setupObservation()
        onStateChanged()
        
        Task { @MainActor in
            await checkTranscript()
        }
    }
    
    private func setupObservation() {
        withObservationTracking {
            _ = progressUseCase.fetchObservable(taskId: videoId).state
        } onChange: {
            Task { @MainActor [weak self] in
                self?.onStateChanged()
                self?.setupObservation()
            }
        }
    }

    private func onStateChanged() {
        let state = progressUseCase.fetchObservable(taskId: videoId).state
        self.progressState = state
        if state == .unknwon {
            self.progressState = .notStarted
        } else if state == .completed {
            let detail = self.loadVideoDetailFromVideoId(videoId: self.videoId)
            self.playerViewModel = PlayerViewModel(videoDetailEntity: detail)
        } else {
            print(state)
        }

    }

    /// translate がスレッド待ちですぐに始まらないので、先にprogressStateだけ開始してボタンを非表示にする
    func startTransferStart() {
        transferUserCase.startTranslateVideoDetailState(id: videoId)
    }
    
    var transcriptFetchResult:TranscriptFetchResult = .notFetched
    enum TranscriptFetchResult {
        case notFetched
        case noTranscript
        case hasTranscript
    }
    
    func checkTranscript() async {
        do {
            let entity = try await self.videoDetailUseCase.fetchTranscript(id: self.videoId, url: self.url)
            Task { @MainActor  [weak self] in
                guard let self = self else { return }
                if let entity = entity,
                   entity.paragraphs.count > 0 {
                    self.transcriptFetchResult = .hasTranscript
                } else {
                    self.transcriptFetchResult = .noTranscript
                }
            }
        } catch {
        }
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
    
    func downloadAndExtractText() async {
        Task.detached {
            do {
                try await self.downloadAudioUserCase.translateVideoDetail(id: self.videoId, url: self.url)
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
