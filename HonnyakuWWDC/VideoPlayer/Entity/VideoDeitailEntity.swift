//  VideoDeitailEntity.swift

import Foundation

struct VideoDetailEntity: Hashable, Codable {
    var attributes: VideoAttributesEntity
    var translated: TranscriptEntity
    var baseTranscript: TranscriptEntity

    static var mock = VideoDetailEntity(attributes: VideoAttributesEntity.zero, translated: TranscriptEntity.mock, baseTranscript: TranscriptEntity.zero)
}
