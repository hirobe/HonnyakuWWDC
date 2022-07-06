//  VideoDetail.swift

import SwiftUI

struct VideoDetailView: View {
    enum VideoDetailViewError: Error {
        case copyError
    }

    @ObservedObject var viewModel: VideoDetailViewModel
    @State var isShowingPopover: Bool = false
    @State var isShowingSystemSettingPopover: Bool = false

    var body: some View {
        VStack {
            if viewModel.progressState == .completed && viewModel.showPlayerIfEnabled {
                PlayerView(viewModel: PlayerViewModel(videoId: viewModel.videoId))
            } else {
                VStack {
                    if !viewModel.errorMessage.isEmpty {
                        Text("Error:\(viewModel.errorMessage)")

                    }

                    ControlView(viewModel: viewModel)

                    WebView(url: viewModel.url)
                }
            }
        }
        .toolbar {
            if viewModel.progressState == .completed {
                ToolbarItem(placement: .navigation) {
                    Text(viewModel.title)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showPlayerIfEnabled = !viewModel.showPlayerIfEnabled
                    }) {
                        Label("Change", systemImage: "wand.and.stars")
                    }
                }
            }

            if viewModel.progressState == .completed && viewModel.showPlayerIfEnabled {

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingPopover = true
                    }) {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                    .popover(isPresented: $isShowingPopover) {
                        PlayerSettingsPopover(viewModel: PlayerSettingViewModel()) { action in
                            if action == .copyData {
                                guard viewModel.copyDataToPasteBoard() else { throw VideoDetailViewError.copyError }
                            } else if action == .close {
                                isShowingPopover = false
                            }

                        }
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                    }
                }
            }
        }
    }
}

struct VideoDetail_Previews: PreviewProvider {
    static var previews: some View {
        VideoDetailView(viewModel: VideoDetailViewModel(videoId: VideoEntity.mock.id, url: VideoEntity.mock.url, title: VideoEntity.mock.title))
    }
}
