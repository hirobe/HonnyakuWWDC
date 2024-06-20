import AVFoundation
import Foundation


enum DownloadAudioUserCaseError: Error, LocalizedError {
    case noResourcesError
    case extractAudio

    var errorDescription: String? {
        switch self {
        case .noResourcesError:
            return "noResourcesError"
        case .extractAudio:
            return "extractAudio"
        }
    }
}

class DownloadAudioUserCase : TranslateCaseProtocol {
    struct OpenAITranscript: Codable {
        struct Segment:Codable {
            var start:Double
            var text:String
            
        }
        var segments:[OpenAITranscript.Segment]
    }
    
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
    func makeClipText(id: String) -> String? {
        guard let data = try? fileAccessUseCase.loadFileFromDocuments(path: "\(id)_\(settingsUseCase.languageShortLower).json") else {
            return nil
        }
        return String(data: data, encoding: .utf8)
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

            print(attributes.resources)
            guard let sdUrl = attributes.resources.first(where: {$0.title == "SD Video"})?.url else { throw DownloadAudioUserCaseError.noResourcesError }
            //guard let videoUrl = attributes.videoUrl else { return }
            
            let destinationPath =  FileManager.default.temporaryDirectory.appendingPathComponent(id + "." + sdUrl.pathExtension)
                
            try await downloadFile(from: sdUrl, to: destinationPath)
            
            guard let audioUrl = try await extractAudio(from: destinationPath) else { throw DownloadAudioUserCaseError.extractAudio }

            taskProgresUseCase.setState(taskId: id, state: .processing(progress: 0.6, message: nil))

            let jsonData = try await transcribeAudioFile(url: audioUrl, apiKey: settingsUseCase.openAIAuthKey)
            taskProgresUseCase.setState(taskId: id, state: .processing(progress: 0.7, message: nil))

            guard let transcript = makeTranscriptEntity(data: jsonData) else { return }
            
            // transcriptを抽出して保存
//            guard let transcript = try parseVideoDetailUseCase.parseTranscript(text: html) else { return }
            print(transcript)

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
    
    // ダウンロード用の関数
    func downloadFile(from url: URL, to destinationURL: URL) async throws {
        // URLSessionを使用してデータをダウンロード
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // レスポンスがHTTPレスポンスか確認し、ステータスコードが200であることを確認
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // データを目的地に保存
        try data.write(to: destinationURL)
        print("ファイルが保存されました: \(destinationURL.path)")
    }

    func extractAudio(from videoURL: URL) async throws -> URL? {
        //let outputFileURL = getDocumentsDirectory().appendingPathComponent("wwdc2024-10133_sd.mp4")
        //let asset = AVAsset(url: outputFileURL)
        
        
        
        let asset = AVAsset(url: videoURL)
        
        //do {
            // Await the loading of the tracks key
            try await asset.loadValues(forKeys: ["tracks"])
            
            // Ensure the asset's track information is loaded successfully
            let status = asset.statusOfValue(forKey: "tracks", error: nil)
            
            switch status {
            case .loaded:
                // Tracks are loaded successfully
                let tracks = asset.tracks
                print(tracks)
                
                // Print each track's details
                for track in tracks {
                    print("Track ID: \(track.trackID), Media Type: \(track.mediaType)")
                }
                
//                return await extractAudioSub(baseUrl: videoURL, asset: asset)
                return await saveAudioTrack(baseUrl: videoURL, asset: asset, withCompressionRate: 64_000) // 64 kbpsに圧縮して保存する
            case .failed:
                // Failed to load tracks
                print("Failed to load tracks")
                return nil
                
            case .cancelled:
                // Loading of tracks was cancelled
                print("Loading tracks was cancelled")
                return nil
                
            default:
                // Unknown status
                print("Unknown status while loading tracks")
                return nil
            }
        /*
        } catch {
            // Handle any errors during the load
            print("Error loading tracks: \(error)")
            return nil
        }*/
    }

    func extractAudioSub(baseUrl:URL, asset: AVAsset) async -> URL? {
        //let outputFileURL = getDocumentsDirectory().appendingPathComponent("extractedAudio.m4a")
        let outputFileURL =  baseUrl.deletingPathExtension().appendingPathExtension("m4a")

        // Remove the output file if it already exists
        if FileManager.default.fileExists(atPath: outputFileURL.path) {
            try? FileManager.default.removeItem(at: outputFileURL)
        }
        
        // Check if there are audio tracks in the asset
        let audioTracks = asset.tracks(withMediaType: .audio)
        guard !audioTracks.isEmpty else {
            print("No audio tracks found in the video.")
            return nil
        }
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            print("Failed to create AVAssetExportSession.")
            return nil
        }
        
        exportSession.outputURL = outputFileURL
        exportSession.outputFileType = .m4a
        
        do {
            try await exportSession.export()
            return exportSession.status == .completed ? outputFileURL : nil
        } catch {
            print("Failed to extract audio: \(error.localizedDescription)")
            return nil
        }
    }

    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func saveAudioTrack(baseUrl:URL, asset: AVAsset, withCompressionRate compressionRate: Float) async -> URL? {
        // Check if there are audio tracks in the asset
        let audioTracks = asset.tracks(withMediaType: .audio)
        guard !audioTracks.isEmpty else {
            print("No audio tracks found in the video.")
            return nil
        }
        let outputFileURL =  baseUrl.deletingPathExtension().appendingPathExtension(".m4a")



        // Remove the output file if it already exists
        if FileManager.default.fileExists(atPath: outputFileURL.path) {
            try? FileManager.default.removeItem(at: outputFileURL)
        }
        
        do {
            // Set up an AVAssetReader to read the audio track
            let assetReader = try AVAssetReader(asset: asset)
            //let readerOutput = AVAssetReaderTrackOutput(track: audioTracks[0], outputSettings: nil)
            //assetReader.add(readerOutput)
            // Output settings for AVAssetReaderTrackOutput to uncompress audio samples
            let readerOutputSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM
            ]
            let readerOutput = AVAssetReaderTrackOutput(track: audioTracks[0], outputSettings: readerOutputSettings)
            assetReader.add(readerOutput)

            // Configure audio settings with desired compression rate
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVEncoderBitRateKey: compressionRate,
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2
            ]
            
            // Set up an AVAssetWriter to write the audio track to the output file
            let assetWriter = try AVAssetWriter(outputURL: outputFileURL, fileType: .m4a)
            let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            assetWriter.add(writerInput)
            
            // Start reading and writing
            assetReader.startReading()
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: .zero)
            
            // Use a dispatch queue for asynchronous writing
            let dispatchQueue = DispatchQueue(label: "audioWriterQueue")
            writerInput.requestMediaDataWhenReady(on: dispatchQueue) {
                while writerInput.isReadyForMoreMediaData {
                    if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                        writerInput.append(sampleBuffer)
                    } else {
                        writerInput.markAsFinished()
                        assetWriter.finishWriting {
                            print("Finished writing audio to \(outputFileURL)")
                        }
                        break
                    }
                }
            }
            
            // Wait for the writing process to complete
            while assetWriter.status == .writing {
                try await Task.sleep(nanoseconds: 100_000_000) // Sleep for 0.1 seconds
            }
            
            return assetWriter.status == .completed ? outputFileURL : nil
            
        } catch {
            print("Failed to save audio: \(error.localizedDescription)")
            return nil
        }
    }


/*
    
    func extractAudio(from videoURL: URL, completion: @escaping (URL?) -> Void) {
        let outputFileURL = getDocumentsDirectory().appendingPathComponent("wwdc2024-10133_sd.mp4")
        let asset = AVAsset(url:outputFileURL)
        
        //let asset = AVAsset(url: videoURL)
        
        // AVAssetが読み込み可能かどうかを確認し、完了するまで待機する
        asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
            var error: NSError? = nil
            let status = asset.statusOfValue(forKey: "tracks", error: &error)
            
            switch status {
            case .loaded:
                // トラック情報の読み込みに成功した場合
                DispatchQueue.main.async {
                    // main queueに戻ってトラック情報を表示
                    let tracks = asset.tracks
                    print(tracks)
                    
                    // 各トラックの詳細情報を表示
                    for track in tracks {
                        print("Track ID: \(track.trackID), Media Type: \(track.mediaType)")
                    }
                    
                    self.extractAudoSub(asset: asset, completion: completion)
                }
                
            case .failed:
                // トラック情報の読み込みに失敗した場合
                if let error = error {
                    print("Failed to load tracks: \(error.localizedDescription)")
                }
                
            case .cancelled:
                // トラック情報の読み込みがキャンセルされた場合
                print("Loading tracks was cancelled")
                
            default:
                // その他の場合
                print("Unknown status while loading tracks")
            }
        }
    }
    
    func extractAudoSub(asset:AVAsset, completion: @escaping (URL?) -> Void) {
        print(asset.tracks)
        //try? await asset.loadMetadata(for: .iTunesMetadata)
        let outputFileURL = getDocumentsDirectory().appendingPathComponent("extractedAudio.m4a")
        
        // 出力ファイルが既に存在する場合は削除
        if FileManager.default.fileExists(atPath: outputFileURL.path) {
            try? FileManager.default.removeItem(at: outputFileURL)
        }
        // 音声トラックが存在するかを確認
        let audioTracks = asset.tracks(withMediaType: .audio)
        guard !audioTracks.isEmpty else {
            print("No audio tracks found in the video.")
            completion(nil)
            return
        }
    
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        exportSession?.outputURL = outputFileURL
        exportSession?.outputFileType = .m4a
        exportSession?.exportAsynchronously {
            switch exportSession?.status {
            case .completed:
                completion(outputFileURL)
            case .failed, .cancelled:
                print("Failed to extract audio: \(exportSession?.error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            default:
                break
            }
        }
    }
     

    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    */
    func makeTranscriptEntity(data: Data) -> TranscriptEntity? {
        guard //let data = jsonText.data(using: .utf8),
              let openAITranscript = try? JSONDecoder().decode(OpenAITranscript.self, from: data) else { return nil }
        // jsonの文字列からOpenAITranscriptを生成
        
        // 文の途中で切れる事が多いのでつなげる "."で終わるかで判断
        var editedSegments : [OpenAITranscript.Segment] = []
        var at: Double? = nil
        var text: String = ""
        for seg in openAITranscript.segments {
            if at == nil {
                at = seg.start
            }
            text += seg.text
            if seg.text.hasSuffix(".") {
                editedSegments.append(OpenAITranscript.Segment(start: at ?? seg.start, text: text))
                at = nil
                text = ""
            }
        }
        
        
        var ret = TranscriptEntity(language: "EN", paragraphs: [TranscriptEntity.Paragraph(at: 0, sentences: editedSegments.map({ seg in
            return TranscriptEntity.Paragraph.Sentence(at: Int(seg.start), text: seg.text)
        }))])
        return ret
    }
    
    //    import Foundation

    //let apiKey = "YOUR_OPENAI_API_KEY"
    //let fileURL = URL(fileURLWithPath: "path/to/your/file.mp3")
    func transcribeAudioFile(url: URL, apiKey: String) async throws -> Data {
        guard let fileData = try? Data(contentsOf: url) else {
            throw NSError(domain: "Failed to load m4a file.", code: 1, userInfo: nil)
        }
        
        let boundary = UUID().uuidString
        let apiUrl = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // ファイルデータをmultipart/form-dataのフォーマットで追加
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"file.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // モデルを指定
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)

        // response_formatを指定
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("verbose_json\r\n".data(using: .utf8)!)
/*
        // timestamp_granularitiesを指定
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"timestamp_granularities[]\"\r\n\r\n".data(using: .utf8)!)
        body.append("segment\r\n".data(using: .utf8)!)
            */
        // 終端
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // タイムアウト時間を設定するURLSessionConfigurationを作成
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 180.0 // リクエストのタイムアウト時間を180秒に設定
        configuration.timeoutIntervalForResource = 240.0 // リソースのタイムアウト時間を240秒に設定
        
        let session = URLSession(configuration: configuration)
        
        let (data, response) = try await session.data(for: request)
        //let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "OpenAI transcirpt Failed with status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)", code: 2, userInfo: nil)
        }
        /*
        guard let result = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let text = result["text"] as? String else {
            throw NSError(domain: "Failed to parse JSON.", code: 3, userInfo: nil)
        }*/
        
        return data
    }
}
