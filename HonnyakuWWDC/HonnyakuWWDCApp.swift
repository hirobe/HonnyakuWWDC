//  HonnyakuWWDCApp.swift

import SwiftUI

@main
struct HonnyakuWWDCApp: App {
    var body: some Scene {
        WindowGroup {
            VideoListView(viewModel: VideoListViewModel())
        }
    }
}
