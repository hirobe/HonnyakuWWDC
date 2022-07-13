//  ControlBar.swift

import SwiftUI

struct ControlView: View {
    @ObservedObject var viewModel: VideoDetailViewModel
    var showingAlert: String = ""
    @State var isShowingAlert: Bool = false

    var body: some View {
        HStack {
            switch viewModel.progressState {
            case .completed:
                HStack(spacing: 10) {
                    Text("Translation completed. ")

                    Button("Show translated player") {
                        Task {
                            viewModel.showPlayerIfEnabled = true
                        }
                    }
                }
            case let .processing(progress, message):
                HStack(spacing: 10) {
                    ProgressView()
                    VStack {
                        ProgressView("Translating" + (message != nil ? ": \(message!)" : "..."), value: progress)
                    }
                    .frame(width: 200, height: 44, alignment: .leading)
                }
                .frame(width: 240, height: 44, alignment: .leading)
            case .unknwon:
                HStack(spacing: 10) {
                    ProgressView()
                }
            case .notStarted:
                HStack(spacing: 10) {

                    Text("Not translated yet. ")

                    Button("Start Translate") {
                        viewModel.startTransferStart()
                        Task {
                            await viewModel.transfer()
                        }
                    }
                }
            case let .failed(message):
                HStack(spacing: 10) {

                    Text("Translated failed! " + (message ?? "") + " " )

                    Button("Restart Translate") {
                        Task {
                            await viewModel.transfer()
                        }
                    }
                }
            }
        }
    }
}

struct ControlView_Previews: PreviewProvider {
    static var previews: some View {
        ControlView(viewModel: VideoDetailViewModel(videoId: VideoEntity.mock.id, url: VideoEntity.mock.thumbnailUrl, title: VideoEntity.mock.title))
    }
}
