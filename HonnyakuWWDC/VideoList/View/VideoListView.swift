// VideoListView.swift

import SwiftUI

struct VideoListView: View {
    @State var viewModel: VideoListViewModel
    @State private var selection: VideoEntity?
    @State private var isShowingPopover: Bool = false
    @State private var isShowingSystemSettingPopover: Bool = false

    var body: some View {
        NavigationSplitView {
            VStack {
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                }
                if viewModel.isProcessing {
                    ProgressView()
                        .padding()
                }

                List(viewModel.videoGroups, selection: $selection) { section in
                    let title = viewModel.videoGroupAttributes(id: section.id)?.title ?? "-"
                    Section(header: Text(title)) {
                        ForEach(section.videos) { video in
                            VideoListCell(viewModel: VideoListCellViewModel(video: video, progress: viewModel.progress(of: video)))
                                .tag(video)
                        }
                    }
                }
            }
            .navigationTitle("Videos")
            .searchable(text: $viewModel.searchText)
            .navigationBarItems(
                trailing:
                    Button(action: {
                        isShowingSystemSettingPopover = true
                    }) {
                        Label("More", systemImage: "gearshape")
                    }
                    .sheet(isPresented: $isShowingSystemSettingPopover) {
                        SystemSettingView(viewModel: SystemSettingViewModel()) { action in
                            if action == .close {
                                isShowingSystemSettingPopover = false
                            }
                        }
                    }
            )
        } detail: {
            NavigationStack {
                ViewResolver.resolve(viewDescriptor: viewModel.generateDetailViewDescriptor(from: selection))
            }
        }
        .onAppear() {
            viewModel.onAppear()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        VideoListView(viewModel: VideoListViewModel())
    }
}
