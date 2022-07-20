//
//  PlayerAndTranscriptView.swift
//  HonnyakuWWDC
//
//  Created by Kazuya Horibe on 2022/07/18.
//

import SwiftUI

struct PlayerAndTranscriptView: View {
    @ObservedObject var viewModel: PlayerViewModel
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    PlayerViewController(player: viewModel.videoPlayer.avPlayer)

                    if viewModel.isShowingController {
                        VStack(spacing: 8) {
                            Spacer()
                            ControlBar(viewModel: viewModel)
                                .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                        }
                    }
                }
                .aspectRatio(1920 / CGFloat(1080), contentMode: .fit)
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
