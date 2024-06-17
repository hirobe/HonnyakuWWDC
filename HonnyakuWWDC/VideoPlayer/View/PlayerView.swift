//  SyncPlayerView.swift

import SwiftUI
import AVKit

struct PlayerView: View {
    @ObservedObject var viewModel: PlayerViewModel

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                PlayerViewController(player: viewModel.videoPlayer.avPlayer)
                    .aspectRatio(1920 / CGFloat(1080), contentMode: .fit)
                if viewModel.isShowingController {
                    VStack(spacing: 8) {
                        Spacer()
                        ControlBar(viewModel: viewModel.controlBarViewModel, isTouching: $viewModel.isTouchingScreen)
                            .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    }
                }
            }
            .aspectRatio(1920 / CGFloat(1080), contentMode: .fit)
            .contentShape(Rectangle()) // 透明部分もTouch反応させる
            .gesture(DragGesture(minimumDistance: 0)
                        .onEnded({ _ in viewModel.isTouchingScreen = false })
                        .onChanged({ _ in viewModel.isTouchingScreen = true})
            )
            .onHover { hovering in
                viewModel.isTouchingScreen = hovering
            }
            .onDisappear {
                viewModel.clearPlayer()
            }

            //Spacer()
            if viewModel.showBaseSentence &&
                !viewModel.isThmbnailedPlayer &&
                !viewModel.baseSentence.isEmpty {
                Text(viewModel.baseSentence)
                    .font(.title)
                    .foregroundColor(.primary)
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
            }
            if viewModel.showSpeechSentence &&
                !viewModel.isThmbnailedPlayer &&
                !viewModel.speechSentence.isEmpty {
                Text(viewModel.speechSentence)
                    .font(.title)
                    .foregroundColor(.primary)
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
            }
        }
        .padding(EdgeInsets(top: 100, leading: 60, bottom: 50, trailing: 60))
    }

}

struct PlayerViewController: UIViewControllerRepresentable {
    let player: AVPlayer

    init(player: AVPlayer) {
        self.player = player
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller =  AVPlayerViewController()
        controller.player = player
        controller.videoGravity = .resizeAspect
        controller.showsPlaybackControls = false
        // controller.allowsPictureInPicturePlayback = true
        return controller
    }

    func updateUIViewController(_ playerController: AVPlayerViewController, context: Context) {
        playerController.player = player
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView(viewModel: PlayerViewModel())
    }
}
