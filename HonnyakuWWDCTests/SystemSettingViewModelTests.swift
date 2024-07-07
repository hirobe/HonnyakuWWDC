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
        #expect(viewModel.deepLAuthKey == mockSettings.deepLAuthKey)
        #expect(viewModel.isDeepLPro == mockSettings.isDeepLPro)
        #expect(viewModel.openAIAuthKey == mockSettings.openAIAuthKey)
        #expect(viewModel.selectedLanguageId == mockSettings.languageId)
        #expect(viewModel.selectedVoiceId == mockSettings.voiceId)
    }

    @Test @MainActor func updateSettings() async throws {
        // テスト対象でwithObservationTrackingを使っているので、@MainActorをつけてメインスレッドで実行。また、変更後にTask.yieldを使ってスレッドの完了を待つ。
        #expect(viewModel.openAIAuthKey == mockSettings.openAIAuthKey)

        viewModel.openAIAuthKey = "newOpenAIKey"
        #expect(viewModel.openAIAuthKey == "newOpenAIKey")
        // 更新を待つ
        await Task.yield()
        #expect(mockSettings.openAIAuthKey == "newOpenAIKey")
    }
    @Test @MainActor func updateSettings2() async throws {
        #expect(viewModel.deepLAuthKey == mockSettings.deepLAuthKey)
        viewModel.deepLAuthKey = "newDeepLKey"
        #expect(viewModel.deepLAuthKey == "newDeepLKey")
        
        await Task.yield()
        #expect(mockSettings.deepLAuthKey == "newDeepLKey")
    }
    @Test @MainActor func updateSettings3() async throws {
        #expect(viewModel.isDeepLPro == mockSettings.isDeepLPro)
        #expect(viewModel.selectedLanguageId == mockSettings.languageId)
        #expect(viewModel.selectedVoiceId == mockSettings.voiceId)

        viewModel.isDeepLPro = true
        #expect(viewModel.isDeepLPro)
        await Task.yield()
        #expect(mockSettings.isDeepLPro)
            
        viewModel.selectedLanguageId = "en"
        #expect(viewModel.selectedLanguageId == "en")
        await Task.yield()
        #expect(mockSettings.languageId == "en")
            
        viewModel.selectedVoiceId = "voice2"
        #expect(viewModel.selectedVoiceId == "voice2")
        await Task.yield()
        #expect(mockSettings.voiceId == "voice2")
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

    @Test @MainActor func videoGroupToggle() async {
        let firstGroup = viewModel.videoGroupList[0]
        firstGroup.enabled = true
        await Task.yield()

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
