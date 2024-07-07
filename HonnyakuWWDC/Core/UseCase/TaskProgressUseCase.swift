//  TaskProgressUseCase.swift

import Foundation
import Observation

protocol TaskProgressUseCaseProtocol {
    func setState(taskId: String, state: ProgressState)
    func fetchObservable(taskId: String) -> ProgressObservable
}

enum ProgressState: Hashable, Equatable {
    case unknwon
    case notStarted
    case processing(progress: Float, message: String?)
    case completed
    case failed(message: String?)
}

@Observable final class ProgressObservable: ObservableObject {
    var message: String = ""
    var state: ProgressState = .unknwon

    init(state: ProgressState) {
        self.state = state
    }
}

final class ProgressManager {
    static var shared: ProgressManager = ProgressManager()

    private(set) var tasks: [String: ProgressObservable] = [:]

    func setState(taskId: String, state: ProgressState) {
        tasks[taskId] = tasks[taskId] ?? ProgressObservable(state: .unknwon)
        tasks[taskId]?.state = state // 変更を通知
    }
}

/// 処理の進捗状態を保持・通知するためのクラスです。
/// 処理のTask自体は保持しません。IDと進捗だけ。
/// IDから進捗を通知するObsrvableを返すことができます。
/// アプリ開始時に、ファイルから進捗をセットし直す必要があります。
///
class TaskProgressUseCase: TaskProgressUseCaseProtocol {
    private var progressManager: ProgressManager

    init(progressManager: ProgressManager = ProgressManager.shared) {
        self.progressManager = progressManager
    }

    func setState(taskId: String, state: ProgressState) {
        progressManager.setState(taskId: taskId, state: state)
    }

    func fetchObservable(taskId: String) -> ProgressObservable {
        // もし値が存在しなければ、.unknownを作って返す
        if progressManager.tasks[taskId] == nil {
            progressManager.setState(taskId: taskId, state: .unknwon)
        }
        return progressManager.tasks[taskId]!
    }
}
