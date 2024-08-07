//  DeepLUseCaseTests.swift

import Testing
@testable import HonnyakuWWDC

struct DeepLUseCaseTests {
    typealias Paragraph = TranscriptEntity.Paragraph
    typealias Sentence = TranscriptEntity.Paragraph.Sentence

    init() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    @Test func xmlAndTranscript() throws {
        let deepLUseCase = DeepLUseCase.init()
        let transcript = TranscriptEntity(
            language: "EN",
            paragraphs:
                [Paragraph(at: 0, sentences: [Sentence(at: 0, text: "The first paragraph. "), Sentence(at: 10, text: "The second sentence. ")]),
                 Paragraph(at: 20, sentences: [Sentence(at: 20, text: "The last paragraph. ")])
                ])

        let xml = deepLUseCase.transcriptToXml(transcript: transcript)
        #expect(xml == "<p><s at=\"0\">The first paragraph. </s><s at=\"10\">The second sentence. </s></p>\n<p><s at=\"20\">The last paragraph. </s></p>\n")

        let transcript2 = deepLUseCase.xmlToTranscript(language: "EN", xml: xml)
        #expect(transcript == transcript2)
    }
}
