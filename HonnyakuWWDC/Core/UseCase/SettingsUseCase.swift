//  SettingsUseCase.swift

import Foundation
import Combine

class SettingsUseCase: ObservableObject {
    static let shared: SettingsUseCase = SettingsUseCase()

    struct LanguageDefinition: Identifiable {
        var id: String
        var voicesKey: String
        var deepLLanguage: String
        var name: String

        static var all: [LanguageDefinition] = [
            LanguageDefinition(id: "ja", voicesKey: "ja-JP", deepLLanguage: "JA", name: "日本語(Japanese)")
        ]

        static func find(id: String) -> LanguageDefinition? {
            LanguageDefinition.all.first { $0.id == id }
        }
    }

    struct SpeechRateDefinition: Identifiable {
        var id: Float { value }
        var name: String
        var value: Float

        static var all: [SpeechRateDefinition] = [
            SpeechRateDefinition(name: "x0.8", value: 0.8),
            SpeechRateDefinition(name: "x0.9", value: 0.9),
            SpeechRateDefinition(name: "x1.0", value: 1.0),
            SpeechRateDefinition(name: "x1.1", value: 1.1),
            SpeechRateDefinition(name: "x1.2", value: 1.2),
            SpeechRateDefinition(name: "x1.3", value: 1.3),
            SpeechRateDefinition(name: "x1.5", value: 1.5),
            SpeechRateDefinition(name: "x1.8", value: 1.8)
        ]

        static func find(value: Float) -> SpeechRateDefinition? {
            SpeechRateDefinition.all.first { $0.value == value }
        }
    }
    struct VideoRateDefinition: Identifiable {
        var id: Float { value }
        var name: String
        var value: Float

        static var all: [VideoRateDefinition] = [
            VideoRateDefinition(name: "x0.8", value: 0.8),
            VideoRateDefinition(name: "x0.9", value: 0.9),
            VideoRateDefinition(name: "x1.0", value: 1.0),
            VideoRateDefinition(name: "x1.1", value: 1.1),
            VideoRateDefinition(name: "x1.2", value: 1.2),
            VideoRateDefinition(name: "x1.3", value: 1.3),
            VideoRateDefinition(name: "x1.5", value: 1.5),
            VideoRateDefinition(name: "x1.8", value: 1.8)
        ]

        static func find(value: Float) -> VideoRateDefinition? {
            VideoRateDefinition.all.first { $0.value == value }
        }
    }

    @Published var speechVolume: Double
    @Published var speechRate: Float
    @Published var videoVolume: Double
    @Published var videoRate: Float
    @Published var showOriginalText: Bool
    @Published var showTransferdText: Bool

    @Published var languageId: String
    @Published var voiceId: String
    @Published var deepLAuthKey: String
    @Published var isDeepLPro: Bool
    @Published var openAIAuthKey: String

    @Published var videoGroupIds: [String]

    private var cancellables: [AnyCancellable] = []

    private init() {
        let userDefaults = UserDefaults.standard
        userDefaults.register(defaults: [
            "speechVolume": 1.0,
            "speechRate": 1.0,
            "videoVolume": 0.5,
            "videoRate": 1.0,
            "showOriginalText": false,
            "showTransferdText": true,
            "deepLAuthKey": "",
            "isDeepLPro": false,
            "openAIAuthKey": "",
            "languageId": LanguageDefinition.all.first?.id ?? "",
            "voiceId": "",
            "videoGroupIds": []
        ])

        self.speechVolume = UserDefaults.standard.double(forKey: "speechVolume")
        self.speechRate = UserDefaults.standard.float(forKey: "speechRate")
        self.videoVolume = UserDefaults.standard.double(forKey: "videoVolume")
        self.videoRate = UserDefaults.standard.float(forKey: "videoRate")
        self.showOriginalText = UserDefaults.standard.bool(forKey: "showOriginalText")
        self.showTransferdText = UserDefaults.standard.bool(forKey: "showTransferdText")
        self.deepLAuthKey = UserDefaults.standard.string(forKey: "deepLAuthKey") ?? ""
        self.isDeepLPro = UserDefaults.standard.bool(forKey: "isDeepLPro")
        self.openAIAuthKey = UserDefaults.standard.string(forKey: "openAIAuthKey") ?? ""

        self.languageId = UserDefaults.standard.string(forKey: "languageId") ?? ""
        self.voiceId = UserDefaults.standard.string(forKey: "voiceId") ?? ""
        self.videoGroupIds = UserDefaults.standard.array(forKey: "videoGroupIds") as? [String] ?? []

        if self.languageId.isEmpty {
            self.languageId = LanguageDefinition.all.first?.id ?? ""
        }

        $speechVolume.sink { value in
            UserDefaults.standard.setValue(value, forKey: "speechVolume")
        }
        .store(in: &cancellables)
        $speechRate.sink { value in
            UserDefaults.standard.setValue(value, forKey: "speechRate")
        }
        .store(in: &cancellables)
        $videoVolume.sink { value in
            UserDefaults.standard.setValue(value, forKey: "videoVolume")
        }
        .store(in: &cancellables)
        $videoRate.sink { value in
            UserDefaults.standard.setValue(value, forKey: "videoRate")
        }
        .store(in: &cancellables)
        $showOriginalText.sink { value in
            UserDefaults.standard.setValue(value, forKey: "showOriginalText")
        }
        .store(in: &cancellables)
        $showTransferdText.sink { value in
            UserDefaults.standard.setValue(value, forKey: "showTransferdText")
        }
        .store(in: &cancellables)

        $languageId.sink { value in
            UserDefaults.standard.setValue(value, forKey: "languageId")
        }
        .store(in: &cancellables)
        $voiceId.sink { value in
            UserDefaults.standard.setValue(value, forKey: "voiceId")
        }
        .store(in: &cancellables)

        $deepLAuthKey.sink { value in
            UserDefaults.standard.setValue(value, forKey: "deepLAuthKey")
        }
        .store(in: &cancellables)
        $isDeepLPro.sink { value in
            UserDefaults.standard.setValue(value, forKey: "isDeepLPro")
        }
        .store(in: &cancellables)
        $openAIAuthKey.sink { value in
            UserDefaults.standard.setValue(value, forKey: "openAIAuthKey")
        }
        .store(in: &cancellables)
        $videoGroupIds.sink { value in
            UserDefaults.standard.setValue(value, forKey: "videoGroupIds")
        }
        .store(in: &cancellables)
    }

    var languageShortLower: String {
        print(languageId)
        let languageId = LanguageDefinition.find(id: languageId)?.id ?? ""
        return languageId
    }

    var deepLLang: String {
        if let language = LanguageDefinition.find(id: languageId) {
            return language.deepLLanguage
        }
        return ""
    }

}
