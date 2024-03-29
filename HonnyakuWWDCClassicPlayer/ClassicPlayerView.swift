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
    // @State var showingPopUpText = false

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
                        viewModel.isThmbnailedPlayer.toggle()
                    }
                }) {
                    Image(systemName: "ellipsis.bubble")
                        .font(.system(size: 22))
                        .foregroundColor(.gray)
                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))

                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 44, height: 44, alignment: .topTrailing)
                .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))

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
                    NavigationView {
                        ClassicPlayerSettingView(viewModel: PlayerSettingViewModel(), showingPopup: $showingPopUp, action: { command in
                            switch command {
                            case .loadData:
                                guard viewModel.classicLoadData() else {
                                    throw ClassicPlayerViewError.pasteError
                                }
                            // try viewModel.loadFromVideoId(videoId: viewModel.videoAttributes.id)
                            case .pasteData:
                                guard viewModel.classicPasteData() else {
                                    throw ClassicPlayerViewError.pasteError
                                }
                            }
                        })
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    showingPopUp = false
                                }) {
                                    Label("Close", systemImage: "xmark")
                                }
                            }
                        }
                    }
                }
            }
            .background(Color.white)

            PlayerAndTranscriptView(viewModel: viewModel)
        }
        .background(Color.black)
        .onAppear {
            _ = viewModel.classicLoadData()
        }
    }
}

struct OldPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        ClassicPlayerView(viewModel: PlayerViewModel())
    }
}
