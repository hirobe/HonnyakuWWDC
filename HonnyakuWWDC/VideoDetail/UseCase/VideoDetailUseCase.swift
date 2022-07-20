//  VideoDetailUseCase.swift

import Foundation
protocol VideoDetailUseCaseProtocol {
    func loadVideoDetailFromVideoId(videoId: String) throws -> VideoDetailEntity
}

class VideoDetailUseCase: VideoDetailUseCaseProtocol {
    private var settingsUseCase: SettingsUseCase
    private var fileAccessUseCase: FileAccessUseCaseProtocol

    init(settingsUseCase: SettingsUseCase = SettingsUseCase.shared,
         fileAccessUseCase: FileAccessUseCaseProtocol = FileAccessUseCase()
    ) {
        self.settingsUseCase = settingsUseCase
        self.fileAccessUseCase = fileAccessUseCase
    }

    func loadVideoDetailFromVideoId(videoId: String) throws -> VideoDetailEntity {
        let data = try fileAccessUseCase.loadFileFromDocuments(path: "\(videoId)_\(settingsUseCase.languageShortLower).json")
        let detail = try JSONDecoder().decode(VideoDetailEntity.self, from: data)

        return detail
    }
}
