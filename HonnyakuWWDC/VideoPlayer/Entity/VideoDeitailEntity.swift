//  VideoDeitailEntity.swift

import Foundation

struct VideoDetailEntity: Hashable, Codable {
    var attributes: VideoAttributesEntity
    var translated: TranscriptEntity
    var baseTranscript: TranscriptEntity
}
