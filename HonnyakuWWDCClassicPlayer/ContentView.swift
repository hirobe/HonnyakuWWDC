//  ContentView.swift

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel: PlayerViewModel

    var body: some View {
        ClassicPlayerView(viewModel: viewModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {

        ContentView(viewModel: PlayerViewModel())
    }
}
