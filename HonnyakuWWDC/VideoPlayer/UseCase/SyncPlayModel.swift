//  SyncPlayModel.swift

import Foundation

struct SyncPlayModel: Equatable {
    enum SyncState: Equatable {
        case bothRunning
        case videoWaiting
        case speechWaiting
    }

    enum ControllerInfo: Equatable {
        struct SeekInfo: Equatable {
            var seconds: Double
            var inPlaying: Bool
        }

        case playing
        case pausing
        case seeking(seekInfo: SeekInfo)
    }

    private(set) var controllerInfo: ControllerInfo
    private(set) var syncState: SyncState
    private(set) var phraseIndex: Int

    func updatedWith(controllerInfo: ControllerInfo) -> SyncPlayModel {
        return SyncPlayModel(controllerInfo: controllerInfo,
                             syncState: self.syncState,
                             phraseIndex: self.phraseIndex)
    }

    static var zero: SyncPlayModel = SyncPlayModel(controllerInfo: .pausing,
                                                   syncState: .bothRunning,
                                                   phraseIndex: 0)
}
