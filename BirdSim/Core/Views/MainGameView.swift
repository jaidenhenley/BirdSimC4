//
//  GameContainerView.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/21/26.
//

import SpriteKit
import SwiftUI
struct MainGameView: View {
    @StateObject var viewModel: ViewModel
    @State private var scene = GameScene()
    @Binding var gameStarted: Bool
    
    
    protocol GameDelegate: AnyObject {
        func dismissGame()
    }

    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .onAppear {
                    scene.scaleMode = .resizeFill
                    scene.viewModel = viewModel
                }
            
         
            
            if viewModel.controlsAreVisable {
                DrainingHealthBarView(viewModel: viewModel)
                    .padding()
                
                VStack {
                    
                    HStack {
                        Spacer()
                        
                        Button{
                            viewModel.showInventory = true
                        } label: {
                            Image(systemName: "bag.fill")
                                .font(.largeTitle)
                                .padding()
                                .background(Circle().fill(.ultraThinMaterial))
                        }
                        .padding()
                    }
                    
                    Spacer ()
                    
                    HUDControls(viewModel: viewModel)
                        .padding(60)
                }
            }
            
            if viewModel.showInventory {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.showInventory = false
                    }
                
                InventoryView(viewModel: viewModel)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring, value: viewModel.showInventory)
    }
}


#Preview {
    MainGameView(viewModel: MainGameView.ViewModel(), gameStarted: .constant(false))
}
