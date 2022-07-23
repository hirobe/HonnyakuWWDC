//  SpeechPhraseList.swift

import Foundation

class SpeechPhraseList {
    private(set) var phrases: [SpeechPhrase]
    private(set) var currentIndex: Int = 0

    init(phrases: [SpeechPhrase]) {
        self.phrases = phrases
    }

    static let zero: SpeechPhraseList = SpeechPhraseList(phrases: [])

    func nextPhraseIndex() -> Int? {
        guard currentIndex+1 < phrases.count else {
            return nil
        }
        return currentIndex + 1
    }
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

    func isTimeToPlayNext(time: Double) -> Bool {
        if currentIndex+1 < phrases.count,
           time >= phrases[currentIndex+1].at { return true }
        return false
    }

    func nextPhraseStartAt() -> Double? {
        guard currentIndex+1 < phrases.count else {
            return nil
        }
        return phrases[currentIndex+1].at
    }

    func isEnd() -> Bool {
        return currentIndex >= phrases.count
    }

    func currentText() -> String? {
        guard currentIndex < phrases.count else {
            return nil
        }
        return phrases[currentIndex].text

    }
}
