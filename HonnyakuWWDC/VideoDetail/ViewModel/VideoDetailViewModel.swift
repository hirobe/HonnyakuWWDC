//  VideoDetailViewModel.swift

import SwiftUI
import Combine

/// VideoDetailViewのViewModel
final class VideoDetailViewModel: ObservableObject {
    private var videoDetailUseCase: VideoDetailUseCase
    private var transferUserCase: TranslateCaseProtocol
    private var downloadAudioUserCase: TranslateCaseProtocol
    private var progressUseCase: TaskProgressUseCaseProtocol
    
    @Published var showPlayerIfEnabled: Bool
    @Published private(set) var progressState: ProgressState = .unknwon
    @Published private(set) var errorMessage: String = ""
    
    @Published private(set) var playerViewModel: PlayerViewModel? = nil
    
    private(set) var videoId: String
    private(set) var url: URL
    private(set) var title: String
    
    private var cancellables: [AnyCancellable] = []
    
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
        
        progressUseCase.fetchObservable(taskId: videoId).$state
            .receive(on: DispatchQueue.main)
            .sink {[weak self] state in
                if state == .unknwon {
                    self?.progressState = .notStarted
                } else {
                    print(state)
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
        
        Task {
            await checkTranscript()
        }
    }
    
    
    /// translate がスレッド待ちですぐに始まらないので、先にprogressStateだけ開始してボタンを非表示にする
    func startTransferStart() {
        transferUserCase.startTranslateVideoDetailState(id: videoId)
    }
    
    @Published var transcriptFetchResult:TranscriptFetchResult = .notFetched
    enum TranscriptFetchResult {
        case notFetched
        case noTranscript
        case hasTranscript
    }
    
    func checkTranscript() async {
        do {
            var entity = try await self.videoDetailUseCase.fetchTranscript(id: self.videoId, url: self.url)
            if let entity = entity,
               entity.paragraphs.count > 0 {
                self.transcriptFetchResult = .hasTranscript
            } else {
                self.transcriptFetchResult = .noTranscript
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
                /*
                let detail = self.loadVideoDetailFromVideoId(videoId: self.videoId)
                print(detail?.attributes.relatedVideos)
                guard let sdUrl = detail?.attributes.resources.first(where: {$0.title == "SD Video"})?.url else { return }
                guard let videoUrl = detail?.attributes.videoUrl else { return }
                DownloadSound().extractAudio(from: sdUrl) { url in
                    print(url)
                }
                 */
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
