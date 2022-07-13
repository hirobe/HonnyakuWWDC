//  VideoListCell.swift

import SwiftUI

/// Videoのリストのセル
/// 処理中の状態表示も行います
struct VideoListCell: View {
    @StateObject var viewModel: VideoListCellViewModel

    var body: some View {
        switch viewModel.state {
        case .completed:
            NavigationLink("🎉 \(viewModel.video.title)", value: viewModel.video)
                .bold()
        case let .processing(progress, _):
            NavigationLink(value: viewModel.video  ) {
                HStack {
                    Text("\(Image(systemName: "wand.and.rays", variableValue: Double(progress)))  \(viewModel.video.title)")
                        .bold()
                    Spacer()
                    ProgressView(value: progress)
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
        case .unknwon, .notStarted, .failed:
            NavigationLink(viewModel.video.title, value: viewModel.video  )
                .bold()
        }
    }
}

struct VideoListCell_Previews: PreviewProvider {
    static var previews: some View {
        VideoListCell(viewModel: VideoListCellViewModel(video: VideoEntity.mock, progress: ProgressObservable(state: .unknwon)))
    }
}
