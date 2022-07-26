//  SpeechPhraseList.swift

import Foundation

class SpeechPhraseList {
    private(set) var phrases: [SpeechPhrase]
    private(set) var currentIndex: Int = 0

    init(phrases: [SpeechPhrase]) {
        self.phrases = phrases
    }

    static let zero: SpeechPhraseList = SpeechPhraseList(phrases: [])

    func prefferIndex(at: Double) -> Int {
        for index in (0 ..< phrases.count).reversed() {
            if phrases[index].at <= at {
                return index
            }
        }
        return 0
    }

    func readyToStart(index: Int) {
        guard index < phrases.count else { return }
        currentIndex = index
    }

    func isTimeToPlayNext(index: Int, time: Double) -> Bool {
        if index+1 < phrases.count,
           time >= phrases[index+1].at { return true }
        return false
    }

    func nextPhraseStartAt() -> Double? {
        guard currentIndex+1 < phrases.count else {
            return nil
        }
        return phrases[currentIndex+1].at
    }

    func isEnd(index: Int) -> Bool {
        return index >= phrases.count - 1
    }

    func currentText() -> String? {
        guard currentIndex < phrases.count else {
            return nil
        }
        return phrases[currentIndex].text

    }
}
