//  TranscriptTextView.swift
import SwiftUI

struct TranscriptTextView: View {
    @State var viewModel: PlayerViewModel
    var textColor: Color
    var padding: EdgeInsets = EdgeInsets()

    var body: some View {
        // ScrollView(.vertical, showsIndicators: true) {
        viewModel.translatedPhrases.phrases
            .map { phrase in
                var container = AttributeContainer()
                container.link = .init(string: String(phrase.id))
                container.foregroundColor = textColor
                if viewModel.currentPhraseIndex == phrase.id {
                    container.underlineStyle = .single
                    container.underlineColor = .gray
                }

                let attributedString = AttributedString(phrase.text, attributes: container)
                return Text(phrase.isParagraphFirst ? "\n\n　" : " ") +
                    Text(attributedString)
                    .font(.title3)
            }
            .reduce(Text("")) { $0 + $1 }
            .environment(\.openURL, OpenURLAction { url in
                if let index = Int(url.absoluteString) {
                    viewModel.phraseSelected(index: index)
                }
                return .systemAction
            })
            .padding(padding)
        // }
    }
}

struct TranscriptTextView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = PlayerViewModel(videoDetailEntity: VideoDetailEntity.mock)
        TranscriptTextView(viewModel: viewModel, textColor: .white).frame(width: 400, height: 400)
            .previewLayout(.sizeThatFits)
    }
}
