//  Transcript.swift

import Foundation

struct TranscriptEntity: Hashable, Codable {

    struct Paragraph: Hashable, Codable {
        struct Sentence: Hashable, Codable {
            var at: Int
            var text: String
        }

        var at: Int
        var sentences: [Sentence]
    }

    var language: String
    var paragraphs: [Paragraph]

    static var zero: TranscriptEntity = TranscriptEntity(language: "EN", paragraphs: [])

}
