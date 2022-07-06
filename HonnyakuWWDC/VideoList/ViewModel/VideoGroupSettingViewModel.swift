//  VideoGroupSettingViewModel.swift

import Foundation
import Combine

class VideoGroupSettingViewModel: ObservableObject, Identifiable {
    var id: String
    var title: String
    var enabled: Bool {
        didSet { // 値変更後に呼ぶためにsinkではなくdidSetを使う
            onChanged?(self)
        }
    }
    @Published var state: ProgressState = .unknwon
    var progress: ProgressObservable
    var onChanged: ((_:VideoGroupSettingViewModel) -> Void)?

    private var cancellables: [AnyCancellable] = []

    init(id: String, title: String, enabled: Bool, progress: ProgressObservable, onChanged: ((_:VideoGroupSettingViewModel) -> Void)?) {
        self.id = id
        self.title = title
        self.enabled = enabled
        self.progress = progress
        self.onChanged = onChanged

        progress
            .$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.state = state
            }
            .store(in: &cancellables)
    }
}
