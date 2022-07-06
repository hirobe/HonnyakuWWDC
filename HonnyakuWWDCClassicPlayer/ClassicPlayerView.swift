//  ClassicPlayerView.swift

import SwiftUI
import AVKit

struct ClassicPlayerView: View {
    enum ClassicPlayerViewError: Error {
        case pasteError
    }

    @ObservedObject var viewModel: PlayerViewModel
    @State private var showControls = true
    @State var showingPopUp = false

    var body: some View {
        // データがなければ設定画面を表示して貼り付けを促す（Viewerのみ）
        VStack(spacing: 0) {
            HStack {
                Text(viewModel.videoAttributes.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                    .foregroundColor(.black)
                Spacer()
                Button(action: {
                    withAnimation {
                        showingPopUp = true
                    }
                }) {
                    Image(systemName: "gearshape.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.gray)
                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))

                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 44, height: 44, alignment: .topTrailing)
                .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                .sheet(isPresented: $showingPopUp) {
                    ClassicPlayerSettingView(viewModel: PlayerSettingViewModel(), showingPopup: $showingPopUp, action: { command in
                        switch command {
                        case .loadData:
                            viewModel.showDocumentFolder()
                            try viewModel.loadFromVideoId(videoId: viewModel.videoAttributes.id)
                        case .pasteData:
                            guard viewModel.pasteData() else {
                                throw ClassicPlayerViewError.pasteError
                            }
                        }
                    })
                }
            }
            .background(Color.white)
            PlayerView(viewModel: viewModel)
            Spacer()
        }
        .background(Color.black)
    }
}

struct OldPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        ClassicPlayerView(viewModel: PlayerViewModel())
    }
}
