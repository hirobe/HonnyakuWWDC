//  VideoDetail.swift

import SwiftUI

struct VideoDetailView: View {
    enum VideoDetailViewError: Error {
        case copyError
    }

    @StateObject var viewModel: VideoDetailViewModel
    @State var isShowingPopover: Bool = false
    @State var isShowingSystemSettingPopover: Bool = false

    var body: some View {
        VStack {
            if viewModel.progressState == .completed && viewModel.showPlayerIfEnabled && viewModel.playerViewModel != nil {

                PlayerAndTranscriptView(viewModel: viewModel.playerViewModel!)

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
            /*
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
             */
            if viewModel.progressState == .completed && viewModel.showPlayerIfEnabled && viewModel.playerViewModel != nil {
                ToolbarItem(placement: .navigationBarTrailing) {

                    Button(action: {
                        withAnimation {
                            viewModel.playerViewModel!.isThmbnailedPlayer.toggle()
                        }
                    }) {
                        Image(systemName: "ellipsis.bubble")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingPopover = true
                    }) {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                    .popover(isPresented: $isShowingPopover) {
                        PlayerSettingsPopover(viewModel: PlayerSettingViewModel()) { [weak viewModel] action in
                            if action == .copyData {
                                guard viewModel?.copyDataToPasteBoard() ?? false else { throw VideoDetailViewError.copyError }
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
        .onAppear() {
            viewModel.onAppear()
        }
    }
}

struct VideoDetail_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VideoDetailView(viewModel: VideoDetailViewModel( progressUseCase: {
                let pu = TaskProgressUseCase()
                pu.setState(taskId: VideoEntity.mock.id, state: .completed)
                return pu
            }(),
            videoId: VideoEntity.mock.id,
            url: VideoEntity.mock.url,
            title: VideoEntity.mock.title,
            showPlayerIfEnabled: true))
            .previewDevice(PreviewDevice(rawValue: "iPad mini 4"))
            .previewDisplayName("Completed")

            VideoDetailView(viewModel: VideoDetailViewModel(videoId: VideoEntity.mock.id, url: VideoEntity.mock.url, title: VideoEntity.mock.title))
                .previewDevice(PreviewDevice(rawValue: "iPad mini 4"))
                .previewDisplayName("NotTranslated")

        }
    }

}
