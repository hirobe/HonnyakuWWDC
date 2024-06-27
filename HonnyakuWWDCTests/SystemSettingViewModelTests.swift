import XCTest
@testable import HonnyakuWWDC
import AVFoundation

final class SystemSettingViewModelTests: XCTestCase {
    var viewModel: SystemSettingViewModel!
    var mockSettings: MockSettingsUseCase!
    var mockProgressUseCase: MockTaskProgressUseCase!
    var mockVideoListUseCase: MockVideoListUseCase!
    var mockVideoGroupScrapingUseCase: MockVideoGroupScrapingUseCase!
    var mockUserDefaults: UserDefaults!

    override func setUpWithError() throws {
        // テスト用のUserDefaultsを作成
        mockUserDefaults = UserDefaults(suiteName: #file)
        mockUserDefaults.removePersistentDomain(forName: #file)
        
        mockSettings = MockSettingsUseCase(userDefaults: mockUserDefaults)
        mockProgressUseCase = MockTaskProgressUseCase()
        mockVideoListUseCase = MockVideoListUseCase()
        mockVideoGroupScrapingUseCase = MockVideoGroupScrapingUseCase()
        
        viewModel = SystemSettingViewModel(
            settings: mockSettings,
            progressUseCase: mockProgressUseCase,
            videoListUseCase: mockVideoListUseCase,
            videoGroupScrapingUseCase: mockVideoGroupScrapingUseCase
        )
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockSettings = nil
        mockProgressUseCase = nil
        mockVideoListUseCase = nil
        mockVideoGroupScrapingUseCase = nil
        mockUserDefaults = nil
    }

    func testInitialization() {
        XCTAssertEqual(viewModel.deepLAuthKey, mockSettings.deepLAuthKey)
        XCTAssertEqual(viewModel.isDeepLPro, mockSettings.isDeepLPro)
        XCTAssertEqual(viewModel.openAIAuthKey, mockSettings.openAIAuthKey)
        XCTAssertEqual(viewModel.selectedLanguageId, mockSettings.languageId)
        XCTAssertEqual(viewModel.selectedVoiceId, mockSettings.voiceId)
    }

    func testUpdateSettings() {
        viewModel.deepLAuthKey = "newDeepLKey"
        XCTAssertEqual(viewModel.deepLAuthKey, "newDeepLKey")
        XCTAssertEqual(mockSettings.deepLAuthKey, "newDeepLKey")
        XCTAssertEqual(mockUserDefaults.string(forKey: "deepLAuthKey"), "newDeepLKey")

        viewModel.isDeepLPro = true
        XCTAssertTrue(viewModel.isDeepLPro)
        XCTAssertTrue(mockSettings.isDeepLPro)
        XCTAssertTrue(mockUserDefaults.bool(forKey: "isDeepLPro"))

        viewModel.openAIAuthKey = "newOpenAIKey"
        XCTAssertEqual(viewModel.openAIAuthKey, "newOpenAIKey")
        XCTAssertEqual(mockSettings.openAIAuthKey, "newOpenAIKey")
        XCTAssertEqual(mockUserDefaults.string(forKey: "openAIAuthKey"), "newOpenAIKey")

        viewModel.selectedLanguageId = "en"
        XCTAssertEqual(viewModel.selectedLanguageId, "en")
        XCTAssertEqual(mockSettings.languageId, "en")
        XCTAssertEqual(mockUserDefaults.string(forKey: "languageId"), "en")

        viewModel.selectedVoiceId = "voice2"
        XCTAssertEqual(viewModel.selectedVoiceId, "voice2")
        XCTAssertEqual(mockSettings.voiceId, "voice2")
        XCTAssertEqual(mockUserDefaults.string(forKey: "voiceId"), "voice2")
    }

    func testLanguages() {
        let languages = viewModel.languages()
        XCTAssertEqual(languages.map { $0.id }, SettingsUseCase.LanguageDefinition.all.map { $0.id })
    }

    func testVoices() {
        // モックの音声リストを設定
        let mockVoices = [
            SpeechPlayer.IdentifiableVoice(voice: AVSpeechSynthesisVoice(language: "ja-JP")!),
            SpeechPlayer.IdentifiableVoice(voice: AVSpeechSynthesisVoice(language: "en-US")!)
        ]
        SpeechPlayer.mockVoices = mockVoices

        let voices = viewModel.voices(languageId: "ja")
        XCTAssertEqual(voices.count, 1)
        XCTAssertEqual(voices.first?.voice.language, "ja-JP")
    }

    func testVideoGroupListInitialization() {
        XCTAssertFalse(viewModel.videoGroupList.isEmpty)
        XCTAssertEqual(viewModel.videoGroupList.count, VideoGroupAttributesEntity.all.count)
    }

    func testVideoGroupToggle() {
        let firstGroup = viewModel.videoGroupList[0]
        firstGroup.enabled = true
        
        XCTAssertTrue(firstGroup.enabled)
        XCTAssertTrue(mockSettings.videoGroupIds.contains(firstGroup.id))
        XCTAssertTrue((mockUserDefaults.array(forKey: "videoGroupIds") as? [String] ?? []).contains(firstGroup.id))
    }
}

// モッククラスの定義
class MockSettingsUseCase: SettingsUseCase {
    override init(userDefaults: UserDefaults) {
        super.init(userDefaults: userDefaults)
        // モックデータの初期化
        self.deepLAuthKey = "mockDeepLKey"
        self.isDeepLPro = false
        self.openAIAuthKey = "mockOpenAIKey"
        self.languageId = "ja"
        self.voiceId = "voice1"
    }
}

class MockTaskProgressUseCase: TaskProgressUseCase {
    // 必要に応じてメソッドをオーバーライド
}

class MockVideoListUseCase: VideoListUseCase {
    // 必要に応じてメソッドをオーバーライド
}

class MockVideoGroupScrapingUseCase: VideoGroupScrapingUseCase {
    // 必要に応じてメソッドをオーバーライド
}

// SpeechPlayerにモック用のプロパティを追加
extension SpeechPlayer {
    static var mockVoices: [IdentifiableVoice] = []
    
    static func getVoices(languageCode: String) -> [IdentifiableVoice] {
        return mockVoices.filter { $0.voice.language.starts(with: languageCode) }
    }
}
