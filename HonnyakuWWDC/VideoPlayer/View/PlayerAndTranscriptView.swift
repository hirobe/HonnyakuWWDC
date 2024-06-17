//  PlayerAndTranscriptView.swift

import SwiftUI

struct PlayerAndTranscriptView: View {
    @ObservedObject var viewModel: PlayerViewModel
    var body: some View {
        ZStack {
            // TranscriptListView(viewModel: viewModel)
            if viewModel.isThmbnailedPlayer {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                        TranscriptTextView(viewModel: viewModel, textColor: .primary,
                                           padding: EdgeInsets(top: 160, leading: 16, bottom: 50, trailing: 16))
                        Spacer()
                    }
                }
                .background(.ultraThinMaterial)

            }

            // PlayerView(viewModel: playerViewModel)
            VStack {
                GeometryReader { geometry in
                    HStack {
                        PlayerView(viewModel: viewModel)
                        if viewModel.isThmbnailedPlayer {
                            Spacer(minLength: geometry.size.width - 320)
                        }
                    }
                    .layoutPriority(1)
                    .onAppear {
                        // Windowのサイズを通知する
                        viewModel.refreshPlayer(size: geometry.size)

                    }
                    .onChange(of: geometry.size.width) { _ in
                        // Windowのサイズ変更時に通知する（サムネイル化時は無視）
                        viewModel.refreshPlayer(size: geometry.size)
                    }

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
