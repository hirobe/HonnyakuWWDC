//
//  DataModel.swift

import SwiftUI
import Combine

/// VideoListのViewModel。VideoListStateという方がSwiftUI的には適切なのかもしれない
final class VideoListViewModel: ObservableObject {
    @Published private(set) var videoGroups: [VideoGroupEntity] = []
    @Published private(set) var isProcessing: Bool = false
    @Published private(set) var errorMessage: String = ""
    @Published var searchText: String = ""
    private var cancellables: [AnyCancellable] = []
    private var videoListUseCase: VideoListUseCase
    private var videoGroupScrapingUseCase: VideoGroupScrapingUseCase
    private var settingsUseCase: SettingsUseCase

    @Published private(set) var progressState: [String: ProgressState] = [:]

    private var progressUseCase: TaskProgressUseCase

    init(videoListUseCase: VideoListUseCase = VideoListUseCase(),
         progressUseCase: TaskProgressUseCase = TaskProgressUseCase(),
         videoGroupScrapingUseCase: VideoGroupScrapingUseCase = VideoGroupScrapingUseCase(),
         settingsUseCase: SettingsUseCase = SettingsUseCase.shared
    ) {
        self.videoListUseCase = videoListUseCase
        self.progressUseCase = progressUseCase
        self.videoGroupScrapingUseCase = videoGroupScrapingUseCase
        self.settingsUseCase = settingsUseCase
        _ = try? videoListUseCase.reload()

        $searchText
            .sink { [weak self] text in
                guard let self = self else { return }
                if text.isEmpty {
                    self.videoGroups = self.videoListUseCase.videoGroups
                } else {
                    self.videoGroups = self.videoListUseCase.search(searchText: text)
                }
            }
            .store(in: &cancellables)

        // isProcessingフラグ
        videoGroupScrapingUseCase.$isProcessing.sink {[weak self] value in
            self?.isProcessing = value
        }
        .store(in: &cancellables)

        // 設定で表示するVideoGroupが変更されるか、VideoGroupのスクレイピングが終了したら、再読み込みする
        settingsUseCase.$videoGroupIds.map { _ in true }
            .merge(with: $isProcessing.filter {$0 == false})
            .debounce(for: 0.5, scheduler: DispatchQueue.main) // 同時に多数発生してしまうのでまとめる
            .sink { _ in
                Task {
                    await self.reload()
                }
            }
            .store(in: &cancellables)

        // 状態監視の初期値を設定
        try? videoListUseCase.setupVideoGroupsCompletedStatus()
        try? videoListUseCase.setupVideoCompletedStatus()
        videoGroupScrapingUseCase.observeProcessing()

    }

    @MainActor private func reload() {
        do {
            videoGroups = try videoListUseCase.reload()
        } catch {
            showError(message: "Fetch list error")
            return
        }
        showError(message: "")
    }

    @MainActor private func showError(message: String) {
        errorMessage = message
    }

    func generateDetailViewDescriptor(from video: VideoEntity?) -> ViewDescriptor {
        guard let video = video else {
            return ViewDescriptor.empty(message: "Empty")
        }
        return ViewDescriptor.videoDetailView(videoId: video.id, url: video.url, title: video.title)
    }

    func progress(of video: VideoEntity) -> ProgressObservable {
        let observabale = progressUseCase.fetchObservable(taskId: video.id)
        return observabale
    }

    func videoGroupAttributes(id: String) -> VideoGroupAttributesEntity? {
        return VideoGroupAttributesEntity.all[id]
    }

    static let mockVideos: [VideoEntity] = [VideoEntity.mock]

}
