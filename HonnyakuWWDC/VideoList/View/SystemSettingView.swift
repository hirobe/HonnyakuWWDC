//  SystemSettingsView.swift

import SwiftUI

/// 取得するデータのトグルボタン付きのセル
/// 処理中の状態表示を行うために、VideoGroupViewModelを持つ独立したViewにしています
struct VideoGroupSettingView: View {
    @StateObject var viewModel: VideoGroupSettingViewModel

    var body: some View {
        HStack {
            switch viewModel.state {
            case .processing:
                HStack {
                    ProgressView()
                    Toggle(isOn: $viewModel.enabled ) {
                        Text(viewModel.title)
                    }
                }
            default:
                Toggle(isOn: $viewModel.enabled ) {
                    Text(viewModel.title)
                }
            }

        }
    }
}

/// 設定画面のView
struct SystemSettingView: View {

    @StateObject var viewModel: SystemSettingViewModel
    @State var isShowingAlertForLoad: Bool = false
    @State var isShowingInfoPopover: Bool = false

    enum Action {
        case close
    }
    var action: ((_ action: Action) -> Void)?

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Spacer()
                Button(action: {
                    action?(.close)
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 22))
                        .padding(EdgeInsets(top: 20, leading: 10, bottom: 16, trailing: 6))

                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 44, height: 56, alignment: .center)
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 15))
            }
            .background(Color(.systemGroupedBackground))

            Form {

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
                    // Text("言語")
                }

                Section {
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
                            .onAppear {
                            }
                        } else {
                            HStack {
                                Text("Not found")
                                Button(action: {
                                    isShowingInfoPopover = true
                                }) {
                                    Image(systemName: "info.bubble")
                                }
                                .popover(isPresented: $isShowingInfoPopover) {
                                    Text("言語に合った音声が見つかりません。\n設定のアクセシビリティ/読み上げコンテンツ/音から音声をダウンロードしてください。\nSiriは選択できません。\nなお、ベータ版のシミュレータには音声がダウンロードできないようです")
                                        .padding()
                                }

                            }
                        }
                    }
                } header: {
                    Text("読み上げ")
                }

                Section {
                    HStack {
                        Text("DeepL Auth Key: ")
                        Spacer()
                        SecureField("XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXX...", text: $viewModel.deepLAuthKey)
                    }
                    Toggle("DeepL Pro Account", isOn: $viewModel.isDeepLPro)
                } header: {
                    Text("DeepL")
                }

                Section {
                    List(viewModel.videoGroupList) { (group: VideoGroupSettingViewModel) in
                        VideoGroupSettingView(viewModel: group)
                    }
                    /*
                    Button("リストを再取得する") {
                        Task {
                        }
                    }
                     */
                } header: {
                    Text("取得するデータ")
                }

            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
    }
}

struct SystemSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SystemSettingView(viewModel: SystemSettingViewModel())
    }
}
