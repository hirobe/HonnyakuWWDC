//  TransferUseCase.swift

import Foundation

protocol TranslateCaseProtocol {
    func startTranslateVideoDetailState(id: String)
    func translateVideoDetail(id: String, url: URL) async throws
    func makeClipText(id: String) -> String?
}

enum TranslateUseCaseError: Error {
    case fetchError(error: Error?)
}

class TranslateUseCase: TranslateCaseProtocol {
    private var settingsUseCase: SettingsUseCase
    private var taskProgresUseCase: TaskProgressUseCase
    private var fileAccessUseCase: FileAccessUseCaseProtocol
    private var networkAccessUseCase: NetworkAccessUseCaseProtocol
    private var parseVideoDetailUseCase: ParseVideoDetailUseCaseProtocol
    private var deepLUseCase: DeepLUseCaseProtocol

    init(settingsUseCase: SettingsUseCase = SettingsUseCase.shared,
         taskProgresUseCase: TaskProgressUseCase = TaskProgressUseCase(),
         fileAccessUseCase: FileAccessUseCaseProtocol = FileAccessUseCase(),
         networkAccessUseCase: NetworkAccessUseCaseProtocol = NetworkAccessUseCase(),
         parseVideoDetailUseCase: ParseVideoDetailUseCaseProtocol = ParseVideoDetailUseCase(),
         deepLUseCase: DeepLUseCaseProtocol = DeepLUseCase()
    ) {
        self.settingsUseCase = settingsUseCase
        self.taskProgresUseCase = taskProgresUseCase
        self.fileAccessUseCase = fileAccessUseCase
        self.networkAccessUseCase = networkAccessUseCase
        self.parseVideoDetailUseCase = parseVideoDetailUseCase
        self.deepLUseCase = deepLUseCase

    }

    /// translate がスレッド待ちですぐ始まらないので、先にprogressStateだけ開始しておく
    func startTranslateVideoDetailState(id: String) {
        taskProgresUseCase.setState(taskId: id, state: .processing(progress: 0.0, message: nil))
    }

    func translateVideoDetail(id: String, url: URL) async throws {
        do {
            let jsonEncoder = JSONEncoder()

            taskProgresUseCase.setState(taskId: id, state: .processing(progress: 0.1, message: nil))

            let html: String = try await networkAccessUseCase.fetchText(url: url) //  try await fetch(url: url)
            print(html)

            taskProgresUseCase.setState(taskId: id, state: .processing(progress: 0.4, message: nil))

            let attributes = try parseVideoDetailUseCase.parseDetail(text: html, id: id, url: url)

            taskProgresUseCase.setState(taskId: id, state: .processing(progress: 0.5, message: nil))

            // transcriptを抽出して保存
            guard let transcript = try parseVideoDetailUseCase.parseTranscript(text: html) else { return }
            // print(transcript)

            taskProgresUseCase.setState(taskId: id, state: .processing(progress: 0.8, message: nil))

            // 翻訳して保存
            self.deepLUseCase.setup(authKey: settingsUseCase.deepLAuthKey, isProAPI: settingsUseCase.isDeepLPro, language: settingsUseCase.deepLLang) // 設定変更に対応するため、毎回setupし直す
            let translateResult = try await deepLUseCase.translate(transcript: transcript)

            let data = VideoDetailEntity(attributes: attributes, translated: translateResult, baseTranscript: transcript)
            try fileAccessUseCase.saveFileToDocuments(data: try jsonEncoder.encode(data), path: "\(id)_\(settingsUseCase.languageShortLower).json")

            taskProgresUseCase.setState(taskId: id, state: .completed)
        } catch {
            taskProgresUseCase.setState(taskId: id, state: .failed(message: error.localizedDescription))
            print(error)
            throw error
        }
    }

    func makeClipText(id: String) -> String? {
        guard let data = try? fileAccessUseCase.loadFileFromDocuments(path: "\(id)_\(settingsUseCase.languageShortLower).json") else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

}
