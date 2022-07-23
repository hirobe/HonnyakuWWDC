//  ControlBar.swift

import SwiftUI

private let controlHieght: CGFloat = 44

struct SeekSlider: View {
    @Binding var value: Float
    @Binding var draggInfo: PlayerViewModel.SliderDraggingInfo
    @Binding var isTouching: Bool
    @Binding var leftTimeString: String
    @Binding var rightTimeString: String

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(leftTimeString)
                .font(.system(size: 12))
                .foregroundColor(Color.white).opacity(0.8)
                .foregroundStyle(.ultraThinMaterial)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundColor(Color.white).opacity(0.1)
                        .foregroundStyle(.ultraThinMaterial)
                        .frame(height: 5)
                        .cornerRadius(2)
                    Rectangle()
                        .foregroundColor(Color.white).opacity(0.3)
                        .foregroundStyle(.ultraThinMaterial)
                        .frame(width: geometry.size.width * CGFloat(value), height: 5)
                        .cornerRadius(2)
                    Rectangle()
                        .foregroundColor(Color.white).opacity(0.8)
                        .foregroundStyle(.ultraThinMaterial)
                        .frame(width: 4, height: 18, alignment: .center)
                        .cornerRadius(2)
                        .position(x: geometry.size.width * CGFloat(value) - 2, y: geometry.size.height * 0.5)
                }
                .gesture(DragGesture(minimumDistance: 0)
                    .onEnded({ value in
                        let valueDraged = min(max(0, Float(value.location.x / geometry.size.width )), 1.0)
                        draggInfo = PlayerViewModel.SliderDraggingInfo(isDragging: false, position: valueDraged)
                        isTouching = false
                    })
                    .onChanged({ value in
                        let valueDraged = min(max(0, Float(value.location.x / geometry.size.width )), 1.0)
                        draggInfo = PlayerViewModel.SliderDraggingInfo(isDragging: true, position: valueDraged)
                        isTouching = true
                    })
                )
            }
            .frame(height: controlHieght)
            .contentShape(Rectangle()) // 透明部分もTouch反応させる
            Text(rightTimeString)
                .font(.system(size: 12))
                .foregroundColor(Color.white).opacity(0.8)
                .foregroundStyle(.ultraThinMaterial)
        }
        .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
    }
}

struct ControlBar: View {
    @ObservedObject var viewModel: PlayerViewModel

    var body: some View {
        ZStack(alignment: .center) {
            Rectangle()
                .frame(height: 30, alignment: .center)
                .foregroundColor(.clear)
                .foregroundStyle(.ultraThinMaterial)
                .background(.ultraThinMaterial)
                .cornerRadius(8)

            HStack(alignment: .center, spacing: 0) {
                // Image(systemName: "gobackward.15")
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .frame(width: 44, height: controlHieght)
                .foregroundColor(Color.white).opacity(0.8)
                .gesture(DragGesture(minimumDistance: 0)
                    .onEnded({ _ in viewModel.isTouchingScreen = false })
                    .onChanged({ _ in viewModel.isTouchingScreen = true})
                )
                .simultaneousGesture(TapGesture(count: 1)
                    .onEnded {
                        viewModel.isPlaying.toggle()
                })
                // Image(systemName: "goforward.15")
                SeekSlider(value: $viewModel.sliderPosition,
                           draggInfo: $viewModel.sliderDragging,
                           isTouching: $viewModel.isTouchingScreen,
                           leftTimeString: $viewModel.sliderLeftTime,
                           rightTimeString: $viewModel.sliderRightTime)
            }
            .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
        }
    }
}

struct ControlBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ControlBar(viewModel: PlayerViewModel())
                .frame(width: 400)
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))

        }
        .background(Color.black)
    }
}
