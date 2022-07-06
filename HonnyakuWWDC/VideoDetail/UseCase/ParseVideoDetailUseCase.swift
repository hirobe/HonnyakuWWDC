//  ParseVideoDetailUseCase.swift

import Foundation

protocol ParseVideoDetailUseCaseProtocol {
    func parseTranscript(text: String) throws -> TranscriptEntity?
    func parseDetail(text: String, id: String, url: URL) throws -> VideoAttributesEntity
}
enum ParseVideoDetailUseCaseError: Error {
    case parseError(error: Error?)
}

class ParseVideoDetailUseCase: ParseVideoDetailUseCaseProtocol {

    private static let regexTranscript = /<!-- transcript -->(.+)<\/li>/
    .dotMatchesNewlines()
    .repetitionBehavior(.reluctant)
    private static let regexTranscriptParagraph = /<p>(.+)<\/p>/
    .dotMatchesNewlines()
    .repetitionBehavior(.reluctant)
    private static let regexTranscriptSentence = /<span data-start="(.+)">(.+)(<\/span>|$)/
    .dotMatchesNewlines()
    .repetitionBehavior(.reluctant)

    private static let regexTranscriptSentenceEnd = #/[\.\!\?♪]"* $/#
        .dotMatchesNewlines()
        .repetitionBehavior(.reluctant)

    /// transcript を抽出
    func parseTranscript(text: String) throws -> TranscriptEntity? {
        func parseSec(startString: String) throws -> Int {
            if let first = startString.split(by: ".").first,
               let sec = Int(first) {
                return sec
            }

            throw ParseVideoDetailUseCaseError.parseError(error: nil)
        }

        // transcript
        if let match = text.firstMatch(of: Self.regexTranscript) {
            var paragraphs: [TranscriptEntity.Paragraph] = []
            let textBlock = String(match.output.1)
            for paragraphMatch in textBlock.matches(of: Self.regexTranscriptParagraph) {
                var sentences: [TranscriptEntity.Paragraph.Sentence] = []
                let sentenceMatches = String(paragraphMatch.output.1).matches(of: Self.regexTranscriptSentence)
                // sentencesを作成する。<span>が文の途中で切れている場合は、次のに結合する
                var start: Int?
                var text: String = ""
                for index in 0..<sentenceMatches.count {
                    let sentenceMatch = sentenceMatches[index]
                    if start == nil {
                        start = try parseSec(startString: String(sentenceMatch.output.1))
                        text = ""
                    }
                    text += String(sentenceMatch.output.2)

                    if text.firstMatch(of: Self.regexTranscriptSentenceEnd) != nil || index == sentenceMatches.count-1 {
                        let sentence = TranscriptEntity.Paragraph.Sentence(at: start!, text: text)
                        sentences.append(sentence)
                        start = nil // clear
                    }
                }

                if sentences.count > 0 {
                    let paragraph = TranscriptEntity.Paragraph(at: sentences[0].at, sentences: sentences)
                    paragraphs.append(paragraph)
                }
            }
            let transcript: TranscriptEntity = TranscriptEntity(language: "base", paragraphs: paragraphs)
            return transcript
        }
        return nil
    }

    private static let regexBlock = #/<!-- video player -->(.+<!-- transcript -->)/#
        .dotMatchesNewlines()
        .repetitionBehavior(.reluctant)
    private static let regexDetails = #/<video.+src="(.+)".+<h1>(.+)</h1>\s*<p>(.+)</p>/#
        .dotMatchesNewlines()
        .repetitionBehavior(.reluctant)
    private static let regexResources = #/<h2>Resources<\/h2>(.+)<h/#
        .dotMatchesNewlines()
        .repetitionBehavior(.reluctant)
    private static let regexResourcesSub = #/<a href="([^"]+)"( target="_blank">|>)([^<]+)</a>/#
        .dotMatchesNewlines()
        .repetitionBehavior(.reluctant)
    private static let regexRelatedVideos = #/<h2>Related Videos</h2>(.+)<!-- transcript -->/#
        .dotMatchesNewlines()
        .repetitionBehavior(.reluctant)
    private static let regexRelatedVideosH4orA = #/(<h4>(.+)<\/h4>|<a href="(.+)">(.+)</a>)/#
        .dotMatchesNewlines()
        .repetitionBehavior(.reluctant)

    func parseDetail(text: String, id: String, url: URL) throws -> VideoAttributesEntity {

        guard let matchBlock = text.firstMatch(of: Self.regexBlock) else {
            throw ParseVideoDetailUseCaseError.parseError(error: nil)
        }
        let textBlock = String(matchBlock.output.1)
        guard let matchDetail = textBlock.firstMatch(of: Self.regexDetails),
              let videoUrl = URL(string: String(matchDetail.output.1)) else {
            throw ParseVideoDetailUseCaseError.parseError(error: nil)
        }
        let title = String(matchDetail.output.2)
        let description = String(matchDetail.output.3)

        // Resources
        var resources: [VideoAttributesEntity.Link] = []
        if let matchResource = textBlock.firstMatch(of: Self.regexResources) {
            let recsourceBlock = String(matchResource.output.1)

            for matchResourceSub in recsourceBlock.matches(of: Self.regexResourcesSub) {
                print(String(matchResourceSub.output.1))
                guard let url = URL(string: String(matchResourceSub.output.1)) else {
                    throw ParseVideoDetailUseCaseError.parseError(error: nil)
                }
                let title = String(matchResourceSub.output.3)
                resources.append(VideoAttributesEntity.Link(title: title, url: url))
            }
        }

        // Related Videos
        var linkGroups: [VideoAttributesEntity.LinkGroup] = []
        if let matchRelatedVideos = textBlock.firstMatch(of: Self.regexRelatedVideos) {
            let relatedVideosSubString = matchRelatedVideos.output.1

            var relatedLinks: [VideoAttributesEntity.Link] = []
            // 親子構造を作るためにリストを逆から見ていく
            for block in relatedVideosSubString.matches(of: Self.regexRelatedVideosH4orA).reversed() {
                if let h4 = block.output.2 {
                    linkGroups.insert(VideoAttributesEntity.LinkGroup(title: String(h4), links: relatedLinks), at: 0)
                    relatedLinks = []
                } else if let urlSubString = block.output.3,
                          let title = block.output.4,
                          let url = URL(string: String(urlSubString)) {
                    relatedLinks.insert(VideoAttributesEntity.Link(title: String(title), url: url), at: 0)
                }
            }
        }

        let videoDetail = VideoAttributesEntity(id: id, title: title, description: description, url: url, videoUrl: videoUrl, resources: resources, relatedVideos: linkGroups)
        return videoDetail
    }

}
