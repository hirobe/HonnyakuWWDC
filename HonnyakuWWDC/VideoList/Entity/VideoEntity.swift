//  Video.swift

import SwiftUI

struct VideoEntity: Hashable, Identifiable, Codable {
    static func == (lhs: VideoEntity, rhs: VideoEntity) -> Bool {
        lhs.id == rhs.id
    }

    var id: String // wwdc2022_110339
    var title: String
    var description: String
    var url: URL
    var thumbnailUrl: URL
    var dulationText: String

}

extension VideoEntity {
    static var mock: VideoEntity {
        VideoEntity(id: "wwdc2022_110929", title: "WWDC22 Day 1 recap", description: "It's time for your Day 1 report from Apple HQ. Check out all the exciting announcements and new technologies unveiled at WWDC22 — and learn more about what's coming tomorrow. ", url: URL(string: "https://developer.apple.com/videos/play/wwdc2022/wwdc2022_110929/")!, thumbnailUrl: URL(string: "https://devimages-cdn.apple.com/wwdc-services/images/124/7323/7323_wide_250x141_2x.jpg")!, dulationText: "3:00")
    }
}
