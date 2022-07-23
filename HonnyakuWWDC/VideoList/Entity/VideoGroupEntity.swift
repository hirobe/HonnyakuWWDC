//  VideoGroupEntity.swift

import Foundation

/*
struct VideoGroupEntity: VideoOutlineNode {

    var id: String
    var children: [any VideoOutlineNode]
//    var children: [VideoEntity]
}
*/
struct VideoOutlineNode: Identifiable {
    enum NodeType {
        case group(title: String)
        case video(entity: VideoEntity)
    }
    var id: String
    var value: NodeType
    var children: [VideoOutlineNode]?
/*
    var title: String {
        switch self.value {
        case let .group(title): return title
        case let .video(entity): return entity.title
        }
    }
*/
}

