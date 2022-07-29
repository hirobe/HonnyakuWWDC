//  PlayerSettingsPopover.swift

import SwiftUI

struct PopoverItem<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        HStack(content: content)
            .frame(height: 44)
    }
}

struct PlayerSettingsPopover: View {
    enum Action {
        case copyData
        case close
    }

    @StateObject var viewModel: PlayerSettingViewModel
    @State var isShowingAlertForLoad: Bool = false
    @State private var selectedInt: Int = 1
    var action: ((_ action: Action) throws -> Void)?

    var body: some View {
        VStack(spacing: 6) {
            if viewModel.isPhone {
                // iPhoneのLandscapeでシートを閉じる方法がないのでCloseボタンをつける
                HStack {
                    Spacer()
                    Button(action: {
                        Task {
                            try? action?(.close)
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 22))
                            .padding(EdgeInsets(top: 14, leading: 10, bottom: 10, trailing: 6))

                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 44, height: 44, alignment: .center)
                    .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 0))
                }
            }

            PopoverItem {
                Text("Speech Volume")
                Slider(value: $viewModel.speechVolume)

            }
            PopoverItem {
                Text("Speech Speed")
                Spacer()
                Picker("", selection: $viewModel.speechRate) {
                    ForEach(viewModel.speechRates()) { rate in
                        Text("\(rate.name)")
                            .tag(rate.id)
                    }
                }
            }
            .pickerStyle(MenuPickerStyle())

            PopoverItem {
                Text("Video Volume")

                Slider(value: $viewModel.videoVolume)
            }
            PopoverItem {
                Toggle("オリジナルテキストを表示", isOn: $viewModel.showOriginalText)
            }
            PopoverItem {
                Toggle("翻訳テキストを表示", isOn: $viewModel.showTransferdText)
            }
            PopoverItem {
                Button("データをCopy") {
                    Task {
                        do {
                            try action?(.copyData)
                        } catch {
                            isShowingAlertForLoad = true
                            return
                        }
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        .alert(isPresented: $isShowingAlertForLoad) {
            Alert(title: Text("Failed"))
        }

    }
}

struct PlayerSettingsPopover_Previews: PreviewProvider {
    static var previews: some View {
        Button(action: {
        }) {
            Label("More", systemImage: "ellipsis.circle")
        }
        .popover(isPresented: .constant(true)) {
            PlayerSettingsPopover(viewModel: PlayerSettingViewModel())
        }
    }
}
