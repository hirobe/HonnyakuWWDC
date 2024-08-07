//  VideoGroupScrapingUseCase.swift

import Foundation
import Observation

/// Videoのリストをダウンロード、パースし、ファイルとして保存する
@Observable class VideoGroupScrapingUseCase {
    private var settingsUseCase: SettingsUseCase
    private var taskProgresUseCase: TaskProgressUseCase
    private var fileAccessUseCase: FileAccessUseCaseProtocol
    private var networkAccessUseCase: NetworkAccessUseCaseProtocol
    private(set) var isProcessing: Bool = false

    init(settingsUseCase: SettingsUseCase = SettingsUseCase.shared,
         taskProgresUseCase: TaskProgressUseCase = TaskProgressUseCase(),
         fileAccessUseCase: FileAccessUseCaseProtocol = FileAccessUseCase(),
         networkAccessUseCase: NetworkAccessUseCaseProtocol = NetworkAccessUseCase()) {
        self.settingsUseCase = settingsUseCase
        self.taskProgresUseCase = taskProgresUseCase
        self.fileAccessUseCase = fileAccessUseCase
        self.networkAccessUseCase = networkAccessUseCase
    }

    func fetchList(id: String) async throws {
        // fetch, parse, save
        do {
            taskProgresUseCase.setState(taskId: id, state: .processing(progress: 0.1, message: nil))

            let html: String = try await fetch(id: id)
            let videos = parse(text: html)

            // save
            let json = try JSONEncoder().encode(videos)
            try fileAccessUseCase.saveFileToDocuments(data: json, path: "\(id)_list.json")

            taskProgresUseCase.setState(taskId: id, state: .processing(progress: 1.0, message: nil))
            taskProgresUseCase.setState(taskId: id, state: .completed)
        } catch {
            taskProgresUseCase.setState(taskId: id, state: .failed(message: error.localizedDescription))
            throw error
        }
    }

    private func fetch(id: String) async throws -> String {
        let url: URL = URL(string: "https://developer.apple.com/videos/\(id)/")!
        return try await networkAccessUseCase.fetchText(url: url)
    }

    private static let regexSplit = #/<li class="collection-item (hidden|)" data-released="true">/#
    private static let regexVideoInfo = /<a href="([^\"]+)"[^\"]+\"video-image-link".+<img.+src="(.+)".+alt="(.+)".+<span.+>(.+)<\/span>.+<p class="description">(.+)<\/p>/
    .dotMatchesNewlines()
    .repetitionBehavior(.reluctant)

    private static let regexId = #/(.+)/(.+)//# // "wwdc2022/110339/"
    /// 正規表現でパースしてVideoの情報を抽出
    func parse(text: String) -> [VideoEntity] {
        var videos: [VideoEntity] = []

        // まずvideoが1件ずつ含まれる部分に分割する。html全体からregexVideoInfoで抽出すると非常に時間がかかるため
        var splits = text.split(separator: Self.regexSplit, omittingEmptySubsequences: false)
        splits.removeFirst() // 最初のブロックには情報が含まれないので除去

        // videoの情報を抽出する
        for textBlock in splits {
        guard let match = textBlock.firstMatch(of: Self.regexVideoInfo) else { continue }

        // regexで'/'のエスケープがうまくいかないので、ここで取り除いている
        let urlPath = String(match.output.1).replacingOccurrences(of: "/videos/play/", with: "")
        let idParts = urlPath.split(separator: "/")
        let id = "\(idParts[0])_\(idParts[1])"

        guard let url = URL(string: "https://developer.apple.com/videos/play/" + urlPath),
        let thumbnailUrl = URL(string: String(match.output.2)) else { continue }
        let video = VideoEntity(
            id: id,
            title: String(match.output.3),
            description: String(match.output.5),
            url: url,
            thumbnailUrl: thumbnailUrl,
            dulationText: String(match.output.4))
            videos.append(video)
            // print(video)
        }
        return videos
    }

    func observeProcessing() {
        withObservationTracking { [weak self] in
            for (_, videoGroupAttributesEntity) in VideoGroupAttributesEntity.all {
                _ = self?.taskProgresUseCase.fetchObservable(taskId: videoGroupAttributesEntity.id)
            }
        } onChange: {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isProcessing = false
                for id in settingsUseCase.videoGroupIds {
                    if case .processing = taskProgresUseCase.fetchObservable(taskId: id).state {
                        self.isProcessing = true
                        break
                    }
                }
                self.observeProcessing()
            }
        }
    }
}
