//  ClassicPlayerSettingView.swift

import SwiftUI

struct ClassicPlayerSettingView: View {
    enum Action {
        case pasteData
        case loadData
    }

    @StateObject var viewModel: PlayerSettingViewModel
    @Binding var showingPopup: Bool
    @State var isShowingAlertForLoad: Bool = false
    @State private var selectedInt: Int = 1
    var action: ((_ action: Action) throws -> Void)?

    var body: some View {
        //VStack(spacing: 0) {
            /*
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        showingPopup = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 22))
                        //                        .foregroundColor(.gray)
                        .padding(EdgeInsets(top: 20, leading: 10, bottom: 16, trailing: 6))
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 44, height: 56, alignment: .center)
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 15))
            }
            .background(Color(.systemGroupedBackground))
*/
            Form {
                Section {
                    HStack {
                        Text("Speech Volume")
                        Slider(value: $viewModel.speechVolume)
                    }
                    HStack {
                        Text("Video Volume")

                        Slider(value: $viewModel.videoVolume)
                    }
                    HStack {
                        Text("音声")
                    }
                    Toggle("オリジナルテキストを表示", isOn: $viewModel.showOriginalText)
                    Toggle("翻訳テキストを表示", isOn: $viewModel.showTransferdText)
                } header: {
                    Text("再生")
                }

                Section {
                    HStack {
                        Text("言語")
                        Spacer()
                        Picker("", selection: $viewModel.selectedLanguageId) {
                            ForEach(viewModel.languages()) { language in
                                Text("\(language.name)")
                                    .tag(language.id)

                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    HStack {
                        Text("音声")
                        Spacer()
                        let list = viewModel.voices(languageId: viewModel.selectedLanguageId)
                        if list.count > 0 {
                            Picker("", selection: $viewModel.selectedVoiceId) {
                                ForEach(list) { voice in
                                    Text("\(voice.title)")
                                        .tag(voice.id)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        } else {
                            Text("Not found")
                        }
                    }
                }

                Section {
                    Button("データを貼り付ける") {
                        Task {
                            guard (try? action?(.pasteData)) != nil else {
                                isShowingAlertForLoad = true
                                return
                            }
                            withAnimation {
                                showingPopup = false
                            }
                        }
                    }
                    /*
                    Button("データをLoad") {
                        Task {
                            guard (try? action?(.loadData)) != nil else {
                                isShowingAlertForLoad = true
                                return
                            }
                            withAnimation {
                                showingPopup = false
                            }
                        }
                    }
                    .alert(isPresented: $isShowingAlertForLoad) {
                        Alert(title: Text("Failed"))
                    }*/
                }
            //}
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
    }
}

struct OldPlayerSettingView_Previews: PreviewProvider {
    static var previews: some View {
        ClassicPlayerSettingView(viewModel: PlayerSettingViewModel(), showingPopup: .constant(false))
    }
}
