//  VideoGroupSettingViewModel.swift

import Foundation
import Observation

@Observable final class VideoGroupSettingViewModel: Identifiable {
    private(set) var id: String
    private(set) var title: String
    var enabled: Bool {
        didSet { // 値変更後に呼ぶためにsinkではなくdidSetを使う
            onChanged?(self)
        }
    }
    private(set) var state: ProgressState = .unknwon
    private(set) var progress: ProgressObservable
    private var onChanged: ((_:VideoGroupSettingViewModel) -> Void)?

    init(id: String, title: String, enabled: Bool, progress: ProgressObservable, onChanged: ((_:VideoGroupSettingViewModel) -> Void)?) {
        self.id = id
        self.title = title
        self.enabled = enabled
        self.progress = progress
        self.onChanged = onChanged

        setupObservation()
    }

    private func setupObservation() {
        withObservationTracking {
            _ = self.progress.state
        } onChange: {
            Task { @MainActor in
                self.state = self.progress.state
                self.setupObservation()
            }
        }
    }
}
