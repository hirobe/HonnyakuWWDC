//  VideoListUseCase.swift

import Foundation

/// VideoListViewModelで使うためのUseCase
class VideoListUseCase {
    private var settingsUseCase: SettingsUseCase
    private var taskProgresUseCase: TaskProgressUseCase
    private var fileAccessUseCase: FileAccessUseCaseProtocol

    init(settingsUseCase: SettingsUseCase = SettingsUseCase.shared,
         taskProgresUseCase: TaskProgressUseCase = TaskProgressUseCase(),
         fileAccessUseCase: FileAccessUseCaseProtocol = FileAccessUseCase()) {
        self.settingsUseCase = settingsUseCase
        self.taskProgresUseCase = taskProgresUseCase
        self.fileAccessUseCase = fileAccessUseCase

        print(fileAccessUseCase.documentDirectoryPath ?? "")
    }

    var videoGroups: [VideoGroupEntity] = []
    func reload() throws -> [VideoGroupEntity] {
        videoGroups = try load()
        return videoGroups
    }

    func search(searchText: String) -> [VideoGroupEntity] {
        var resultGroups: [VideoGroupEntity] = []
        for videoGroup in videoGroups {
            let result = videoGroup.videos.filter({ video in
                video.title.localizedStandardContains(searchText)
            })
            if result.count > 0 {
                resultGroups.append(VideoGroupEntity(id: videoGroup.id, videos: result))
            }
        }
        return resultGroups
    }

    private func load() throws -> [VideoGroupEntity] {
        var videoGroups: [VideoGroupEntity] = []
        print(settingsUseCase.videoGroupIds)
        for id in settingsUseCase.videoGroupIds {
            let json = try fileAccessUseCase.loadFileFromDocuments(path: "\(id)_list.json")
            let videos = try JSONDecoder().decode([VideoEntity].self, from: json)
            videoGroups.append(VideoGroupEntity(id: id, videos: videos))
        }
        return videoGroups
    }

    /// すでにファイルが存在する場合は、状態をcompletedにする
    func setupVideoCompletedStatus() throws {
        let language = settingsUseCase.languageShortLower
        let items = try fileAccessUseCase.documentDirectoryItems(path: "")
        for item in items {
            if item.hasSuffix("_\(language).json") {
                let parts = item.split(separator: "_")
                if parts.count == 3 {
                    let id = "\(parts[0])_\(parts[1])"
                    taskProgresUseCase.setState(taskId: id, state: .completed)
                }
            }
        }
    }

    /// すでにファイルが存在する場合は、状態をcompletedにする
    func setupVideoGroupsCompletedStatus() throws {
        let items = try fileAccessUseCase.documentDirectoryItems(path: "")
        for item in items {
            guard item.hasSuffix("_list.json"),
                  let first = item.split(separator: "_").first else { continue }
            let id = String(first)
            if settingsUseCase.videoGroupIds.contains(id) {
                taskProgresUseCase.setState(taskId: id, state: .completed)

            }
        }
    }

}
