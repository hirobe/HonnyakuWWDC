//  DeepLUseCase.swift

import Foundation

struct DeepLResult: Codable {
    // {"translations":[{"detected_source_language":"EN","text":"こんにちは、世界よ。"}]}
    struct Detected: Codable {
        enum CodingKeys: String, CodingKey {
            case detectedSourceLanguage = "detected_source_language"
            case text
        }

        var detectedSourceLanguage: String
        var text: String
    }
    var translations: [Detected]
}

protocol DeepLUseCaseProtocol {
    func setup(authKey: String, isProAPI: Bool, language: String)
    func translate(transcript: TranscriptEntity) async throws -> TranscriptEntity
}

enum DeepLUseCaseError: Error, LocalizedError {
    case overFreeLimit

    var errorDescription: String? {
        switch self {
        case .overFreeLimit:
            return "Over free API limit of DeepL !"
        }
    }
}

final class DeepLUseCase: DeepLUseCaseProtocol {
    static var dumy: DeepLUseCase {
        fatalError()
    }
    static var defaults: DeepLUseCase {
        DeepLUseCase()
    }

    private var networkAccessUseCase: NetworkAccessUseCaseProtocol

    private var authKey: String = ""
    private var language: String = ""
    private var isProAPI: Bool = false
    private var urlPrefix: URL {
        isProAPI ? URL(string: "https://api.deepl.com/v2/")! : URL(string: "https://api-free.deepl.com/v2/")!
    }

    init(networkAccessUseCase: NetworkAccessUseCaseProtocol = NetworkAccessUseCase()) {
        self.networkAccessUseCase = networkAccessUseCase
    }

    func setup(authKey: String, isProAPI: Bool, language: String) {
        self.authKey = authKey
        self.isProAPI = isProAPI
        self.language = language
    }

    func translate(transcript: TranscriptEntity) async throws -> TranscriptEntity {
        let transcriptXmlText = transcriptToXml(transcript: transcript)
        print(transcriptXmlText)

        var postFileParams: [String: String] = [:]
        postFileParams["auth_key"]=authKey
        postFileParams["text"]=transcriptXmlText
        postFileParams["target_lang"]=language
        postFileParams["tag_handling"]="xml"
        postFileParams["split_sentences"]="nonewlines"

        do {
            let data = try await networkAccessUseCase.postForm(url: urlPrefix.appending(path: "translate"),
                                                               parameters: postFileParams, files: [])
            let deepLResult = try JSONDecoder().decode(DeepLResult.self, from: data)
            print(deepLResult)

            let transcript = xmlToTranscript(language: language, xml: deepLResult.translations.first?.text ?? "")
            return transcript
        } catch {
            if case let NetworkAccessUseCaseError.postFormError(statusCode) = error,
               statusCode == 456 {
                throw DeepLUseCaseError.overFreeLimit
            } else {
                throw error
            }
        }
    }

    func transcriptToXml(transcript: TranscriptEntity) -> String {
        var xml: String = ""
        for paragraph in transcript.paragraphs {
            xml += "<p>"
            for sentence in paragraph.sentences {
                xml += "<s at=\"\(sentence.at)\">\(sentence.text)</s>"
            }
            xml += "</p>\n"
        }
        return xml
    }

    private static let regexTranscriptSentence = /<s at="(.+)">(.+)<\/s>/
    .dotMatchesNewlines()
    .repetitionBehavior(.reluctant)

    func xmlToTranscript(language: String, xml: String) -> TranscriptEntity {
        func extracts(text: String, pre: some RegexComponent, after: some RegexComponent) -> [Substring] {
            var pres = text.split(separator: pre, omittingEmptySubsequences: false)
            pres.removeFirst()
            let ret = pres.compactMap { $0.split(separator: after).first }
            return ret
        }

        var paragraphs: [TranscriptEntity.Paragraph] = []
        for paragraphMatches in extracts(text: xml, pre: #/<p>/#, after: #/</p>/#) {
            var sentences: [TranscriptEntity.Paragraph.Sentence] = []
            let sentenceMatches = paragraphMatches.matches(of: Self.regexTranscriptSentence)
            for sentence in sentenceMatches {
                guard let start = Int(sentence.output.1) else { fatalError() }
                let text = String(sentence.output.2)
                let sentence = TranscriptEntity.Paragraph.Sentence(at: start, text: text)
                sentences.append(sentence)
            }
            if sentences.count > 0 {
                let paragraph = TranscriptEntity.Paragraph(at: sentences[0].at, sentences: sentences)
                paragraphs.append(paragraph)
            }
        }
        return TranscriptEntity(language: language, paragraphs: paragraphs)
    }
}
