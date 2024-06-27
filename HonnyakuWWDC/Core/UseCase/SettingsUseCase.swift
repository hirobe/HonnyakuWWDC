//  SettingsUseCase.swift

import Foundation
import Observation

@Observable class SettingsUseCase {
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

    var speechVolume: Double
    var speechRate: Float
    var videoVolume: Double
    var videoRate: Float
    var showOriginalText: Bool
    var showTransferdText: Bool
    var isDeepLPro: Bool
    var languageId: String
    var voiceId: String
    var deepLAuthKey: String
    var openAIAuthKey: String
    var videoGroupIds: [String]

    init(userDefaults: UserDefaults = .standard) {
        let userDefaults = userDefaults
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

        self.speechVolume = userDefaults.double(forKey: "speechVolume")
        self.speechRate = userDefaults.float(forKey: "speechRate")
        self.videoVolume = userDefaults.double(forKey: "videoVolume")
        self.videoRate = userDefaults.float(forKey: "videoRate")
        self.showOriginalText = userDefaults.bool(forKey: "showOriginalText")
        self.showTransferdText = userDefaults.bool(forKey: "showTransferdText")
        self.deepLAuthKey = userDefaults.string(forKey: "deepLAuthKey") ?? ""
        self.isDeepLPro = userDefaults.bool(forKey: "isDeepLPro")
        self.openAIAuthKey = userDefaults.string(forKey: "openAIAuthKey") ?? ""

        self.languageId = userDefaults.string(forKey: "languageId") ?? ""
        self.voiceId = userDefaults.string(forKey: "voiceId") ?? ""
        self.videoGroupIds = userDefaults.array(forKey: "videoGroupIds") as? [String] ?? []

        if self.languageId.isEmpty {
            self.languageId = LanguageDefinition.all.first?.id ?? ""
        }
        
        Task { @MainActor in
            self.setupObservation()
        }
    }
    private func setupObservation() {
        withObservationTracking {
            _ = self.speechVolume
            _ = self.speechRate
            _ = self.videoVolume
            _ = self.videoRate
            _ = self.showOriginalText
            _ = self.showTransferdText
            _ = self.isDeepLPro
            _ = self.languageId
            _ = self.voiceId
            _ = self.deepLAuthKey
            _ = self.openAIAuthKey
            _ = self.videoGroupIds
        } onChange: {
            Task { @MainActor in
                self.updateAllUserDefaults()
                self.setupObservation()
            }
        }
    }

    private func updateAllUserDefaults() {
        updateUserDefaults("speechVolume", speechVolume)
        updateUserDefaults("speechRate", speechRate)
        updateUserDefaults("videoVolume", videoVolume)
        updateUserDefaults("videoRate", videoRate)
        updateUserDefaults("showOriginalText", showOriginalText)
        updateUserDefaults("showTransferdText", showTransferdText)
        updateUserDefaults("isDeepLPro", isDeepLPro)
        updateUserDefaults("languageId", languageId)
        updateUserDefaults("voiceId", voiceId)
        updateUserDefaults("deepLAuthKey", deepLAuthKey)
        updateUserDefaults("openAIAuthKey", openAIAuthKey)
        updateUserDefaults("videoGroupIds", videoGroupIds)
    }
    func updateUserDefaults(_ key: String, _ value: Any) {
        UserDefaults.standard.set(value, forKey: key)
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
