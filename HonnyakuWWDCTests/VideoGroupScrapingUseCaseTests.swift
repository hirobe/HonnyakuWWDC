//  VideoListUseCaseTests.swift

import Testing
@testable import HonnyakuWWDC

struct VideoGroupScrapingUseCaseTests {

    init() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    @Test func example() throws {
        let html = """
<body>
<li class="collection-item hidden" data-released="true">
    <section class="grid">
        <section class="row">
            <section class="column large-4 small-4 no-padding-top no-padding-bottom">
                <a href="/videos/play/wwdc2022/10119/" class="video-image-link">
                    <img class="video-image medium-scale" width="250" src="https://devimages-cdn.apple.com/wwdc-services/images/124/6615/6615_wide_250x141_2x.jpg" data-hires="false" alt="Optimize your use of Core Data and CloudKit">
                    <span class="video-duration">26:21</span>
                </a>
            </section>
            <section class="column large-8 small-8  padding-top-small padding-bottom-small gutter no-padding-top no-padding-bottom">
                    <a href="/videos/play/wwdc2022/10119/">
                        <h4 class="no-margin-bottom video-title">Optimize your use of Core Data and CloudKit</h4>
                    </a>
                    <ul class="video-tags">
                        <li class="video-tag focus"><span class="smaller">iOS, macOS</span></li>
                    </ul>
                    <p class="description">Join us as we explore the three parts of the development cycle that can help you optimize your Core Data and CloudKit implementation. We'll show you how you can analyze your app's architecture and feature set to verify assumptions, explore changes in behavior after ingesting large data sets, and...</p>
                    <span class="hidden keywords"> System Services</span>
            </section>
        </section>
    </section>
</li>
<li class="collection-item hidden" data-released="true">
    <section class="grid">
        <section class="row">
            <section class="column large-4 small-4 no-padding-top no-padding-bottom">
                <a href="/videos/play/wwdc2022/10078/" class="video-image-link">
                    <img class="video-image medium-scale" width="250" src="https://devimages-cdn.apple.com/wwdc-services/images/124/6572/6572_wide_250x141_2x.jpg" data-hires="false" alt="Reduce networking delays for a more responsive app">
                    <span class="video-duration">18:42</span>
                </a>
            </section>
            <section class="column large-8 small-8  padding-top-small padding-bottom-small gutter no-padding-top no-padding-bottom">
                    <a href="/videos/play/wwdc2022/10078/">
                        <h4 class="no-margin-bottom video-title">Reduce networking delays for a more responsive app</h4>
                    </a>
                    <ul class="video-tags">
                        <li class="video-tag focus"><span class="smaller">iOS, macOS</span></li>
                    </ul>
                    <p class="description">Find out how network latency can affect your apps when trying to get full benefit out of modern network throughput rates. Learn about changes you can make in your app and on your server to boost responsiveness, and prepare your app for improvements coming to the Internet that will offer even...</p>
                    <span class="hidden keywords"> System Services</span>
            </section>
        </section>
    </section>
</li>
<li class="collection-item hidden" data-released="true">
    <section class="grid">
        <section class="row">
            <section class="column large-4 small-4 no-padding-top no-padding-bottom">
                <a href="/videos/play/wwdc2022/10115/" class="video-image-link">
                    <img class="video-image medium-scale" width="250" src="https://devimages-cdn.apple.com/wwdc-services/images/124/6611/6611_wide_250x141_2x.jpg" data-hires="false" alt="What’s new in CloudKit Console">
                    <span class="video-duration">7:10</span>
                </a>
            </section>
            <section class="column large-8 small-8  padding-top-small padding-bottom-small gutter no-padding-top no-padding-bottom">
                    <a href="/videos/play/wwdc2022/10115/">
                        <h4 class="no-margin-bottom video-title">What’s new in CloudKit Console</h4>
                    </a>
                    <ul class="video-tags">
                        <li class="video-tag focus"><span class="smaller">iOS, macOS</span></li>
                    </ul>
                    <p class="description">We'll take you through the latest updates to CloudKit Console and discover how you can explore and debug your containers on the web like never before. Learn more about Act as iCloud, which helps you query records and view data from the perspective of another account. Discover how to share zones...</p>
                    <span class="hidden keywords"> System Services</span>
            </section>
        </section>
    </section>
</li>
</body>
"""
        let useCase = VideoGroupScrapingUseCase(settingsUseCase: SettingsUseCase.shared,
                                                taskProgresUseCase: TaskProgressUseCase(),
                                                fileAccessUseCase: FileAccessUseCase(),
                                                networkAccessUseCase: NetworkAccessUseCase())
        let result = useCase.parse(text: html)
        #expect(result.count == 3)
        #expect(result[0].id == "wwdc2022_10119")
        #expect(result[0].title == "Optimize your use of Core Data and CloudKit")
        #expect(result[0].url.absoluteString == "https://developer.apple.com/videos/play/wwdc2022/10119/")
        #expect(result[0].thumbnailUrl.absoluteString == "https://devimages-cdn.apple.com/wwdc-services/images/124/6615/6615_wide_250x141_2x.jpg")
        #expect(result[1].id == "wwdc2022_10078")
        #expect(result[1].title == "Reduce networking delays for a more responsive app")
        #expect(result[2].title == "What’s new in CloudKit Console")

    }
}
