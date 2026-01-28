//
//  HUDControlView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 1/28/26.
//

import SwiftUI

struct HUDControls: View {
    @ObservedObject var viewModel: MainGameViewModel

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let isiPad = UIDevice.current.userInterfaceIdiom == .pad

            let base = min(size.width, size.height)

            let joystickDiameter = max(isiPad ? 140 : 100,
                                       base * (isiPad ? 0.22 : 0.16))
            let buttonSize = max(isiPad ? 64 : 48,
                                 base * (isiPad ? 0.12 : 0.08))

            ZStack {
                VStack {
                    Spacer()

                    HStack {
                        JoystickView(
                            viewModel: viewModel,
                            radius: joystickDiameter / 2
                        )
                        .frame(width: joystickDiameter, height: joystickDiameter)

                        Spacer()

                        FlyButtonView(viewModel: viewModel)
                            .frame(width: buttonSize, height: buttonSize)
                    }
                    .padding(.horizontal, isiPad ? 40 : 24)
                    .padding(.bottom, isiPad ? 32 : 20)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    HUDControls(viewModel: MainGameViewModel())
}
