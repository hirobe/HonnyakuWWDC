//  ParseVideoDetailUseCaseTests.swift

import Testing
@testable import HonnyakuWWDC

struct ParseVideoDetailUseCaseTests {

    init() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    @Test func parseTranscriptJoinSentence() throws {
        let useCase = ParseVideoDetailUseCase()
        let text = """
        <!-- transcript -->
        <p><span class="sentence"><span data-start="15.0">Today, my colleague Risa and I will be showing you how to use </span></span><span class="sentence"><span data-start="18.0">the Object Capture API and RealityKit </span></span><span class="sentence"><span data-start="21.0">to create 3D models of real-world objects </span></span><span class="sentence"><span data-start="25.0">and bring them into AR. </span></span><span class="sentence"><span data-start="27.0">Let's get started. </span></span></p>
        </li>
        """
        let result = try useCase.parseTranscript(text: text)
        #expect(result?.paragraphs.count == 1)
        #expect(result?.paragraphs[0].at == 15)
        #expect(result?.paragraphs[0].sentences.count == 2)
        #expect(result?.paragraphs[0].sentences[0].text == "Today, my colleague Risa and I will be showing you how to use the Object Capture API and RealityKit to create 3D models of real-world objects and bring them into AR. ")
        #expect(result?.paragraphs[0].sentences[0].at == 15)
        #expect(result?.paragraphs[0].sentences[1].text == "Let's get started. ")
        #expect(result?.paragraphs[0].sentences[1].at == 27)
    }

    @Test func parseTranscriptFromWrongHtml() throws {
        let useCase = ParseVideoDetailUseCase()
        // No </span> after "You can also show a context menu on an individual item."
        let text = """
        <!-- transcript -->
        <p></span></span><span class="sentence"><span data-start="730.0">You can also show a context menu on an individual item.</p><p></span></span><span class="sentence"><span data-start="735.0">And lastly, you can show a context menu on an empty area, </span></span><span class="sentence"><span data-start="738.0">where there is no content.</p>
        </li>
        """
        let result = try useCase.parseTranscript(text: text)
        #expect(result?.paragraphs.count == 2)
        #expect(result?.paragraphs[0].sentences.count == 1)
        #expect(result?.paragraphs[0].sentences[0].text.hasPrefix("You can also show a context menu on an individual item.") == true)
        #expect(result?.paragraphs[1].sentences.count == 1)
        #expect(result?.paragraphs[1].sentences[0].text.hasSuffix("is no content.") == true)
    }

    @Test func parseTranscriptDividByEighthNote() throws {
        let useCase = ParseVideoDetailUseCase()
        // ♪ ♪
        let text = """
        <!-- transcript -->
        <p><span class="sentence"><span data-start="0.0">♪ Mellow instrumental hip-hop music ♪ </span></span><span class="sentence"><span data-start="3.0">♪ </span></span><span class="sentence"><span data-start="9.0">Hello. </span></span></p>
        </li>
        """
        let result = try useCase.parseTranscript(text: text)
        #expect(result?.paragraphs.count == 1)
        #expect(result?.paragraphs[0].sentences.count == 3)
        #expect(result?.paragraphs[0].sentences[0].text == "♪ Mellow instrumental hip-hop music ♪ ")
        #expect(result?.paragraphs[0].sentences[1].text == "♪ ")
        #expect(result?.paragraphs[0].sentences[2].text == "Hello. ")
    }



}
