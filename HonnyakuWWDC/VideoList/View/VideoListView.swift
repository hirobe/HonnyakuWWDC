// VideoListView.swift

import SwiftUI

struct VideoListView: View {
    @StateObject var viewModel: VideoListViewModel
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

                List(viewModel.videoGroups, id: \.id, children: \.children, selection: $selection) { item in
                    switch item.value {
                    case let .group(title):
                        Text("\(title)")
                    case let .video(entity):
                        VideoListCell(viewModel: VideoListCellViewModel(video: entity, progress: viewModel.progress(of: entity)))
                            .tag(entity)

                    }
                }
                .listStyle(.sidebar)

/*
//                List(viewModel.videoGroups, selection: $selection) { section in
                List {
                    ForEach(viewModel.videoGroups, id: \.id) { section in
                        
                        Section(header: Text(section.title)) {
                            OutlineGroup(
                                section.children ?? [],
                                id: \.value,
                                children: \.children
                            ) { node in
                                switch node {
                                case let .group(title):
                                    Text(title)
                                case let .video(entity):
                                    VideoListCell(viewModel: VideoListCellViewModel(video: entity, progress: viewModel.progress(of: entity)))
                                        .tag(entity)
                                }
//                                Text(tree.value)
//                                    .font(.subheadline)
                            }
                        }
                    }
                }.listStyle(SidebarListStyle())
*/
/*
                List(viewModel.videoGroups, selection: $selection) { section in
                    let title = viewModel.videoGroupAttributes(id: section.id)?.title ?? "-"
                    Section(header: Text(title)) {
                        ForEach(section.videos) { video in
                            VideoListCell(viewModel: VideoListCellViewModel(video: video, progress: viewModel.progress(of: video)))
                                .tag(video)
                        }
                    }
                }
 */
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        VideoListView(viewModel: VideoListViewModel())
    }
}
