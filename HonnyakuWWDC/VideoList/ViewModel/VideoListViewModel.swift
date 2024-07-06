//
//  DataModel.swift

import SwiftUI
import Observation

/// VideoListのViewModel。VideoListStateという方がSwiftUI的には適切なのかもしれない
@Observable public final class VideoListViewModel {
    @ObservationIgnored private var videoListUseCase: VideoListUseCase
    @ObservationIgnored private var videoGroupScrapingUseCase: VideoGroupScrapingUseCase
    @ObservationIgnored private var settingsUseCase: SettingsUseCase
    @ObservationIgnored private var progressUseCase: TaskProgressUseCase

    private(set) var videoGroups: [VideoGroupEntity] = []
    private(set) var isProcessing: Bool = false
    private(set) var errorMessage: String = ""
    var searchText: String = ""

    private(set) var progressState: [String: ProgressState] = [:]


    init(videoListUseCase: VideoListUseCase = VideoListUseCase(),
         progressUseCase: TaskProgressUseCase = TaskProgressUseCase(),
         videoGroupScrapingUseCase: VideoGroupScrapingUseCase = VideoGroupScrapingUseCase(),
         settingsUseCase: SettingsUseCase = SettingsUseCase.shared
    ) {
        self.videoListUseCase = videoListUseCase
        self.progressUseCase = progressUseCase
        self.videoGroupScrapingUseCase = videoGroupScrapingUseCase
        self.settingsUseCase = settingsUseCase
        
    }
    
    func onAppear() {
        videoGroups = (try? videoListUseCase.reload()) ?? []

        setupSearchTextObservation()
                
        setupReloadObservation()
        
        // 状態監視の初期値を設定
        try? self.videoListUseCase.setupVideoGroupsCompletedStatus()
        try? self.videoListUseCase.setupVideoCompletedStatus()
        self.videoGroupScrapingUseCase.observeProcessing()

    }

    private func setupSearchTextObservation() {
        withObservationTracking { [weak self] in
            _ = self?.searchText
        } onChange: {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.refreshVideoGroups()
                self.setupSearchTextObservation()
            }
        }
    }

    private func setupReloadObservation() {
        // 設定で表示するVideoGroupが変更されるか、VideoGroupのスクレイピングが終了したら、再読み込みする
        withObservationTracking { [weak self] in
            _ = self?.settingsUseCase.videoGroupIds
            _ = self?.videoGroupScrapingUseCase.isProcessing
        } onChange: {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                try? await Task.sleep(for: .milliseconds(500))
                self.reload()
                self.setupReloadObservation()
            }
        }

    }

    // serch text変更時
    @MainActor private func refreshVideoGroups() {
        let text = self.searchText
        if text.isEmpty {
            self.videoGroups = self.videoListUseCase.videoGroups
        } else {
            self.videoGroups = self.videoListUseCase.search(searchText: text)
        }
    }

    // settingsの変更時
    @MainActor private func reload() {
        do {
            videoGroups = try videoListUseCase.reload()
            isProcessing = videoGroupScrapingUseCase.isProcessing
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
