//  Speak.swift

import Foundation
import AVFoundation
import Combine

protocol SpeakDelegate: AnyObject {
    func didFinishPhase()

    func phraseStarted(phrase: String, index: Int)
}

struct SpeechPhrase {
    var at: Double
    var text: String

    static func makePhrases(from: TranscriptEntity) -> SpeechPhraseList {
        var flatSentences: [SpeechPhrase] = []
        for paragraph in from.paragraphs {
            for sentences in paragraph.sentences {
                flatSentences.append(SpeechPhrase(at: Double(sentences.at), text: sentences.text))
            }
        }
        return SpeechPhraseList(phrases: flatSentences)
    }

}

protocol SpeechPlayerProtocol {
    var isActive: Bool { get }
    var delegate: SpeakDelegate? { get set }
    func setPhrases(phrases: SpeechPhraseList)
    func setVoice(voiceId: String)
    func setVolume(volume: Float)

    func restart()
    func pause()
    func stop()
}

/// 読み上げを行うクラス。Viewではないが、ユーザインターフェースを提供するクラスなのでView層に置きます。
class SpeechPlayer: NSObject, SpeechPlayerProtocol {
    struct IdentifiableVoice: Identifiable {
        var voice: AVSpeechSynthesisVoice
        var id: String { voice.identifier }
        var title: String {
            switch voice.quality {
            case .enhanced:
                return "\(voice.name) (Enhanced)"
            case .premium:
                return "\(voice.name) (Premium)"

            default:
                return "\(voice.name)"
            }
        }

    }

    private var phrases: SpeechPhraseList = SpeechPhraseList(phrases: [])

    private let synthesizer = AVSpeechSynthesizer()
    private var voice: AVSpeechSynthesisVoice?
    private var rate: Float = AVSpeechUtteranceDefaultSpeechRate

    private var volume: Float = 1.0
    private var isPausing: Bool = false

    weak var delegate: SpeakDelegate?

    var isActive: Bool {
        if voice == nil || volume == 0 {
            return false
        }
        return true
    }

    init(voiceId: String, volume: Float) {
        self.volume = volume

        super.init()
        synthesizer.delegate = self

        if let voice = self.makeVoice(voiceId) {
            self.voice = voice
        }
        rate = AVSpeechUtteranceDefaultSpeechRate

        // Volumeが無視される問題の対処
        // see: https://stackoverflow.com/questions/53619027/avspeechsynthesizer-volume-too-low
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
            try audioSession.setMode(AVAudioSession.Mode.default)
            try audioSession.setActive(true)
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        } catch {
            return
        }
    }

    func setPhrases(phrases: SpeechPhraseList) {
        self.phrases = phrases
    }

    func setVoice(voiceId: String) {
        if let voice = self.makeVoice(voiceId) {
            self.voice = voice
        }

    }

    func setVolume(volume: Float) {
        self.volume = volume
    }

    static func getVoices(languageCode: String) -> [IdentifiableVoice] {

        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { voice in
                print(voice)
                return voice.language == languageCode
            }
        return voices.map {IdentifiableVoice(voice: $0)}
    }

    private func makeVoice(_ identifier: String) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        for voice in voices {
            if voice.identifier == identifier {
                return AVSpeechSynthesisVoice.init(identifier: identifier)
            }
        }
        return nil
    }

    private func startPhrase() {
        guard let phrase = phrases.currentText() else {
            return
        }

        if let voice = voice,
           self.isActive {
            let utterance = AVSpeechUtterance(string: phrase)
            utterance.rate = rate
            utterance.voice = voice
            utterance.volume = volume

            print(phrase)
            synthesizer.speak(utterance)

        }
        isPausing = false

        delegate?.phraseStarted(phrase: phrase, index: phrases.currentIndex)
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .immediate)

        isPausing = true
    }

    func restart() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        } else if !synthesizer.isSpeaking {
            startPhrase()
        }

        isPausing = false
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

extension SpeechPlayer: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        guard phrases.nextPhraseIndex() != nil else {
            // 再生終了
            return
        }

        delegate?.didFinishPhase()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        // 普通にスピーチをしていても稀にキャンセルされることがあるようだ
        guard phrases.nextPhraseIndex() != nil else {
            // 再生終了
            return
        }

        delegate?.didFinishPhase()
    }
}