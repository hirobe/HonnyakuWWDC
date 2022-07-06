//  HonnyakuWWDCClassicPlayerApp.swift

import SwiftUI

@main
struct HonnyakuWWDCClassicPlayerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: PlayerViewModel())
        }
    }
}
