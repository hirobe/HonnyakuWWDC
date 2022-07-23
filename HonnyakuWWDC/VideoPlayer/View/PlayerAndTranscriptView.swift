//  PlayerAndTranscriptView.swift

import SwiftUI

struct PlayerAndTranscriptView: View {
    @ObservedObject var viewModel: PlayerViewModel
    var body: some View {
        ZStack() {
            //TranscriptListView(viewModel: viewModel)
            if viewModel.isThmbnailedPlayer {
                ScrollView(.vertical, showsIndicators: true) {                    VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 160)
                    TranscriptTextView(viewModel: viewModel, textColor: .white)
                    Spacer()
                    Spacer()
                        .frame(height: 50)

                    }
                }
                .background(.ultraThinMaterial)

            }

            //PlayerView(viewModel: playerViewModel)
            VStack() {
                GeometryReader{ geometry in
                    HStack {
                        PlayerView(viewModel: viewModel)
                        if viewModel.isThmbnailedPlayer {
                            Spacer(minLength: geometry.size.width - 320)
                        }
                    }
                    .layoutPriority(1)

                }
                Spacer()
            }


        }

    }
}

struct PlayerAndTranscriptView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerAndTranscriptView(viewModel: PlayerViewModel())
            .previewLayout(.fixed(width: 400, height: 400))
    }
}
