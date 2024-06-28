import Testing
@testable import HonnyakuWWDC
import AVFoundation
import Observation


final class SystemSettingViewModelTests {
    var viewModel: SystemSettingViewModel!
    var mockSettings: MockSettingsUseCase!
    var mockProgressUseCase: MockTaskProgressUseCase!
    var mockVideoListUseCase: MockVideoListUseCase!
    var mockVideoGroupScrapingUseCase: MockVideoGroupScrapingUseCase!
    //var mockUserDefaults: UserDefaults!

    init() throws {
        // テスト用のUserDefaultsを作成
        let mockUserDefaults = UserDefaults(suiteName: #file)!
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

    deinit {
        viewModel = nil
        mockSettings = nil
        mockProgressUseCase = nil
        mockVideoListUseCase = nil
        mockVideoGroupScrapingUseCase = nil
        //mockUserDefaults = nil
    }

    @Test func initialization() {
        #expect(1 == 2)

        #expect(viewModel.deepLAuthKey == mockSettings.deepLAuthKey)
        #expect(viewModel.isDeepLPro == mockSettings.isDeepLPro)
        #expect(viewModel.openAIAuthKey == mockSettings.openAIAuthKey)
        #expect(viewModel.selectedLanguageId == mockSettings.languageId)
        #expect(viewModel.selectedVoiceId == mockSettings.voiceId)
    }

    @Test func updateSettings() async {
        _ = mockSettings.deepLAuthKey
        viewModel.deepLAuthKey = "newDeepLKey"
        #expect(viewModel.deepLAuthKey == "newDeepLKey")
        
        // Wait for the observation to trigger
        try? await Task.sleep(for: .milliseconds(100))
        _ = try? await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume(returning: true)
            }
        }
        
        #expect(viewModel.deepLAuthKey == "newDeepLKey")

        try? await Task.sleep(for: .milliseconds(1000))
        #expect(mockSettings.deepLAuthKey == "newDeepLKey")

        viewModel.isDeepLPro = true
        #expect(viewModel.isDeepLPro)
        
        try? await Task.sleep(for: .milliseconds(100))
        
        #expect(mockSettings.isDeepLPro)
        //XCTAssertTrue(mockUserDefaults.bool(forKey: "isDeepLPro"))

        viewModel.openAIAuthKey = "newOpenAIKey"
        #expect(viewModel.openAIAuthKey == "newOpenAIKey")
        
        try? await Task.sleep(for: .milliseconds(100))
        
        #expect(mockSettings.openAIAuthKey == "newOpenAIKey")
        //XCTAssertEqual(mockUserDefaults.string(forKey: "openAIAuthKey"), "newOpenAIKey")

        viewModel.selectedLanguageId = "en"
        #expect(viewModel.selectedLanguageId == "en")
        
        try? await Task.sleep(for: .milliseconds(100))
        
        #expect(mockSettings.languageId == "en")
        //XCTAssertEqual(mockUserDefaults.string(forKey: "languageId"), "en")

        viewModel.selectedVoiceId = "voice2"
        #expect(viewModel.selectedVoiceId == "voice2")
        
        try? await Task.sleep(for: .milliseconds(100))
        
        #expect(mockSettings.voiceId == "voice2")
        //XCTAssertEqual(mockUserDefaults.string(forKey: "voiceId"), "voice2")
    }

    @Test func languages() {
        let languages = viewModel.languages()
        #expect(languages.map { $0.id } == SettingsUseCase.LanguageDefinition.all.map { $0.id })
    }

    @Test func voices() {
        // モックの音声リストを設定
        let mockVoices = [
            SpeechPlayer.IdentifiableVoice(voice: AVSpeechSynthesisVoice(language: "ja-JP")!),
            SpeechPlayer.IdentifiableVoice(voice: AVSpeechSynthesisVoice(language: "en-US")!)
        ]
        SpeechPlayer.mockVoices = mockVoices

        let voices = viewModel.voices(languageId: "ja")
        #expect(voices.count == 1)
        #expect(voices.first?.voice.language == "ja-JP")
    }

    @Test func videoGroupListInitialization() {
        #expect(!viewModel.videoGroupList.isEmpty)
        #expect(viewModel.videoGroupList.count == VideoGroupAttributesEntity.all.count)
    }

    @Test func videoGroupToggle() async {
        let firstGroup = viewModel.videoGroupList[0]
        firstGroup.enabled = true
        
        #expect(firstGroup.enabled)
        #expect(mockSettings.videoGroupIds.contains(firstGroup.id))
        //XCTAssertTrue((mockUserDefaults.array(forKey: "videoGroupIds") as? [String] ?? []).contains(firstGroup.id))
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
