//  ViewResolver.swift

import SwiftUI
import Combine

/// Viewを返すためのクラス
/// NavitagionのDetailとして表示するViewを返します
final class ViewResolver {
    @ViewBuilder
    static func resolve(viewDescriptor: ViewDescriptor) -> some View {
        switch viewDescriptor {
        case let .videoDetailView(videoId, url, title):
            VideoDetailView(viewModel: VideoDetailViewModel(videoId: videoId, url: url, title: title))
                .id(videoId)
        case .empty:
            EmptyView()
        }
    }
}
