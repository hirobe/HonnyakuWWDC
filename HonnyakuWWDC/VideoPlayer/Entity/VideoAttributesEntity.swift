//  VideoAttributesEntity.swift

import Foundation

struct VideoAttributesEntity: Hashable, Identifiable, Codable {
    struct Link: Hashable, Codable {
        var title: String
        var url: URL
    }
    struct LinkGroup: Hashable, Codable {
        var title: String
        var links: [Link]
    }
    var id: String
    var title: String
    var description: String
    var url: URL
    var videoUrl: URL
    var resources: [Link]
    var relatedVideos: [LinkGroup]

    static var zero = VideoAttributesEntity(id: "", title: "", description: "", url: URL(string: "http://")!, videoUrl: URL(string: "http://")!, resources: [], relatedVideos: [])

}
