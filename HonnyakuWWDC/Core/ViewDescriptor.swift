//  ViewDescriptor.swift

import Foundation

enum ViewDescriptor: Hashable, Codable {
    case videoDetailView(videoId: String, url: URL, title: String)
    case empty(message: String)
}
