//
//  GameContainerView.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/21/26.
//

import SpriteKit
import SwiftUI
struct MainGameView: View {
    @StateObject var viewModel: MainGameViewModel
    @State private var scene = GameScene()
    
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .onAppear {
                    scene.scaleMode = .resizeFill
                    scene.viewModel = viewModel
                }
            if viewModel.controlsAreVisable {
                HStack {
                    JoystickView(viewModel: viewModel)
                        .padding(.all, 100)
                    
                    Spacer()
                    
                    FlyButtonView(viewModel: viewModel)
                        .padding(.all, 100)
                    }
            } else {
                
                }
            }
        }
    }


#Preview {
    MainGameView(viewModel: MainGameViewModel())
}
