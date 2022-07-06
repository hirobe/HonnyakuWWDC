//  VideoGroupAttributesEntity.swift

import Foundation

struct VideoGroupAttributesEntity: Identifiable {
    var id: String
    var title: String
    var fetchUrl: URL

    static var all: [String: VideoGroupAttributesEntity] =
        [
            "wwdc2022": VideoGroupAttributesEntity(id: "wwdc2022", title: "WWDC 2022", fetchUrl: URL(string: "https://developer.apple.com/videos/wwdc2022/")!),
            "wwdc2021": VideoGroupAttributesEntity(id: "wwdc2021", title: "WWDC 2021", fetchUrl: URL(string: "https://developer.apple.com/videos/wwdc2021/")!),
            "wwdc2020": VideoGroupAttributesEntity(id: "wwdc2020", title: "WWDC 2020", fetchUrl: URL(string: "https://developer.apple.com/videos/wwdc2020/")!)
        ]

}
