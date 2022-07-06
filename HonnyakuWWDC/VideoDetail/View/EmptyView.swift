//  EmptyView.swift

import SwiftUI

struct EmptyView: View {
    @State var isShowingSystemSettingPopover: Bool = false
    var body: some View {
        Text("Empty")
    }
}

struct EmptyView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}
