//  ParseVideoDetailUseCaseTests.swift

import XCTest
@testable import HonnyakuWWDC

final class ParseVideoDetailUseCaseTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testParseTranscriptJoinSentence() throws {
        let useCase = ParseVideoDetailUseCase()
        let text = """
        <!-- transcript -->
        <p><span class="sentence"><span data-start="15.0">Today, my colleague Risa and I will be showing you how to use </span></span><span class="sentence"><span data-start="18.0">the Object Capture API and RealityKit </span></span><span class="sentence"><span data-start="21.0">to create 3D models of real-world objects </span></span><span class="sentence"><span data-start="25.0">and bring them into AR. </span></span><span class="sentence"><span data-start="27.0">Let's get started. </span></span></p>
        </li>
        """
        let result = try useCase.parseTranscript(text: text)
        XCTAssertEqual(result?.paragraphs.count, 1)
        XCTAssertEqual(result?.paragraphs[0].at, 15)
        XCTAssertEqual(result?.paragraphs[0].sentences.count, 2)
        XCTAssertEqual(result?.paragraphs[0].sentences[0].text, "Today, my colleague Risa and I will be showing you how to use the Object Capture API and RealityKit to create 3D models of real-world objects and bring them into AR. ")
        XCTAssertEqual(result?.paragraphs[0].sentences[0].at, 15)
        XCTAssertEqual(result?.paragraphs[0].sentences[1].text, "Let's get started. ")
        XCTAssertEqual(result?.paragraphs[0].sentences[1].at, 27)
    }

    func testParseTranscriptFromWrongHtml() throws {
        let useCase = ParseVideoDetailUseCase()
        // No </span> after "You can also show a context menu on an individual item."
        let text = """
        <!-- transcript -->
        <p></span></span><span class="sentence"><span data-start="730.0">You can also show a context menu on an individual item.</p><p></span></span><span class="sentence"><span data-start="735.0">And lastly, you can show a context menu on an empty area, </span></span><span class="sentence"><span data-start="738.0">where there is no content.</p>
        </li>
        """
        let result = try useCase.parseTranscript(text: text)
        XCTAssertEqual(result?.paragraphs.count, 2)
        XCTAssertEqual(result?.paragraphs[0].sentences.count, 1)
        XCTAssertEqual(result?.paragraphs[0].sentences[0].text.hasPrefix("You can also show a context menu on an individual item."), true)
        XCTAssertEqual(result?.paragraphs[1].sentences.count, 1)
        XCTAssertEqual(result?.paragraphs[1].sentences[0].text.hasSuffix("is no content."), true)
    }

    func testParseTranscriptDividByEighthNote() throws {
        let useCase = ParseVideoDetailUseCase()
        // ♪ ♪
        let text = """
        <!-- transcript -->
        <p><span class="sentence"><span data-start="0.0">♪ Mellow instrumental hip-hop music ♪ </span></span><span class="sentence"><span data-start="3.0">♪ </span></span><span class="sentence"><span data-start="9.0">Hello. </span></span></p>
        </li>
        """
        let result = try useCase.parseTranscript(text: text)
        XCTAssertEqual(result?.paragraphs.count, 1)
        XCTAssertEqual(result?.paragraphs[0].sentences.count, 3)
        XCTAssertEqual(result?.paragraphs[0].sentences[0].text, "♪ Mellow instrumental hip-hop music ♪ ")
        XCTAssertEqual(result?.paragraphs[0].sentences[1].text, "♪ ")
        XCTAssertEqual(result?.paragraphs[0].sentences[2].text, "Hello. ")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
