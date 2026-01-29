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
    
    protocol GameDelegate: AnyObject {
        func dismissGame()
    }
    
    
    var body: some View {
        
        if !viewModel.gameStarted {
            StartGameView(gameStarted: $viewModel.gameStarted, scene: $scene)
        } else if viewModel.showGameOver {
            EndGameView(viewModel: viewModel)
        } else {
            ZStack(alignment: .bottomLeading) {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
                    .onAppear {
                        scene.scaleMode = .resizeFill
                        scene.viewModel = viewModel
                    }
                
                if viewModel.controlsAreVisable {
                    VStack {
                        HStack {
                            DrainingHealthBarView(viewModel: viewModel)
                                .padding([.top, .leading], 20) // use 0 if you truly want flush to safe area
                            Spacer()
                        }
                        Spacer()
                    }
                }
                
                if viewModel.controlsAreVisable {
                    
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
                        
                        Spacer()
                        
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
    func createScene() -> SKScene {
        let scene = PredatorGame(size: CGSize(width: 750, height: 1334))
        scene.scaleMode = .aspectFill
        
        scene.dismissAction = {
            withAnimation {
                self.viewModel.gameStarted = false
            }
        }
        return scene
    }
}

#Preview {
    MainGameView(viewModel: MainGameView.ViewModel())
}

