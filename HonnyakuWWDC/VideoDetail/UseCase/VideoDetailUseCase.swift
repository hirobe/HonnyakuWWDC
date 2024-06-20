//  VideoDetailUseCase.swift

import Foundation
protocol VideoDetailUseCaseProtocol {
    func loadVideoDetailFromVideoId(videoId: String) throws -> VideoDetailEntity
    func fetchTranscript(id: String, url: URL)  async throws -> TranscriptEntity?

}

final class VideoDetailUseCase: VideoDetailUseCaseProtocol {
    private var settingsUseCase: SettingsUseCase
    private var fileAccessUseCase: FileAccessUseCaseProtocol
    private var networkAccessUseCase: NetworkAccessUseCaseProtocol
    private var parseVideoDetailUseCase: ParseVideoDetailUseCaseProtocol

    init(settingsUseCase: SettingsUseCase = SettingsUseCase.shared,
         fileAccessUseCase: FileAccessUseCaseProtocol = FileAccessUseCase(),
         networkAccessUseCase: NetworkAccessUseCaseProtocol = NetworkAccessUseCase(),
         parseVideoDetailUseCase: ParseVideoDetailUseCaseProtocol = ParseVideoDetailUseCase()
    ) {
        self.settingsUseCase = settingsUseCase
        self.fileAccessUseCase = fileAccessUseCase
        self.networkAccessUseCase = networkAccessUseCase
        self.parseVideoDetailUseCase = parseVideoDetailUseCase
    }

    func loadVideoDetailFromVideoId(videoId: String) throws -> VideoDetailEntity {
        let data = try fileAccessUseCase.loadFileFromDocuments(path: "\(videoId)_\(settingsUseCase.languageShortLower).json")
        let detail = try JSONDecoder().decode(VideoDetailEntity.self, from: data)

        return detail
    }
    
    
    func fetchTranscript(id: String, url: URL)  async throws -> TranscriptEntity? {
        do {
            let jsonEncoder = JSONEncoder()
            
            let html: String = try await networkAccessUseCase.fetchText(url: url) //  try await fetch(url: url)
            print(html)
            // transcriptを抽出して保存
            guard let transcript = try parseVideoDetailUseCase.parseTranscript(text: html) else { return nil }
            // print(transcript)
            return transcript
        } catch {
            print(error)
            throw error
        }

    }
}
