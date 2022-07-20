//  TranscriptListView.swift

import SwiftUI

struct TranscriptListView: View {
    struct PrimaryButtonStyle: ButtonStyle {
        let height: CGFloat = 60
        func makeBody(configuration: Self.Configuration) -> some View {
            configuration.label
                .opacity(configuration.isPressed ? 1.0 : 0.8 )
        }
    }

    @ObservedObject var viewModel: PlayerViewModel
    @State var selection: SpeechPhrase?
    @State var highLight: SpeechPhrase?
    @GestureState private var longPressTap = false

    //@State var searchText: String = ""
    var body: some View {
        ScrollViewReader { proxy in
            /*
            Button("Jump to #8") {
                withAnimation {
                    proxy.scrollTo(20, anchor: UnitPoint(x: 0, y: 1))
                }
            }
             */
            List(viewModel.translatedPhrases.phrases) { phrase in
                Button {
                    selection = phrase
                    viewModel.phraseSelected(phrase: phrase)
                } label: {
                    Text(phrase.text)
                        .font(.title3)
                        .foregroundColor(viewModel.currentPhraseIndex == phrase.id ? .white : .gray)
                        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        //.background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PrimaryButtonStyle())
                .listRowSeparator(.hidden)
                .listRowBackground( Color.black)
                .listRowInsets(EdgeInsets(top: phrase.isParagraphFirst ? 32 : 2, leading: 16, bottom: 2, trailing: 16))
            }
            .listStyle(.plain)
            .padding(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
            .onReceive(viewModel.$currentPhraseIndex) { value in
                withAnimation {
                    proxy.scrollTo(value, anchor: UnitPoint(x: 0, y: 0.5))
                }
            }
        }
        .background(Color.black)
    }
}

struct TranscriptListView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = PlayerViewModel(videoDetailEntity: VideoDetailEntity.mock)
        TranscriptListView(viewModel: viewModel)
            .previewLayout(.fixed(width: 400, height: 400))
    }
}
