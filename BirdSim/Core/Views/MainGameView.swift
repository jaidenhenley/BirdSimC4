//
//  GameContainerView.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/21/26.
//

import SpriteKit
import SwiftData
import SwiftUI

struct MainGameView: View {
    let container: ModelContainer
    let newGame: Bool
    let onExit: () -> Void
    @StateObject var viewModel: ViewModel
    @State private var scene = GameScene()
    
    
    init(container: ModelContainer, newGame: Bool, onExit: @escaping () -> Void) {
        self.container = container
        self.newGame = newGame
        self.onExit = onExit
        
        let context = container.mainContext
        
        if newGame {
            Self.resetGameState(in: context)
        }
        _viewModel = StateObject(wrappedValue: ViewModel(context: context))
    }
    
    var body: some View {
        if viewModel.showGameOver {
            EndGameView(viewModel: viewModel, onExit: {
                Self.clearSavedGame(in: container.mainContext)
                onExit()
            })
        } else if viewModel.showGameWin {
            WinGameView(viewModel: viewModel, onExit: {
                Self.clearSavedGame(in: container.mainContext)
                onExit()
            })
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
                            VStack {
                                DrainingHungerBarView(viewModel: viewModel, currentHunger: $viewModel.hunger)
                                    .padding([.top, .leading], 20) // use 0 if you truly want flush to safe area
                                Spacer().frame(height: 6)
                                BabyBarView(viewModel: viewModel, currentBabies: $viewModel.currentBabyAmount)
                                    .padding([.top, .leading], 20) // use 0 if you truly want flush to safe area
                                PredatorBarView(viewModel: viewModel, currentDanger: $viewModel.predatorProximitySegments)
                                    .padding([.top, .leading], 20) // use 0 if you truly want flush to safe area
                                
                            }

                            Spacer()
                            
                        }
                        
                        HStack {
                            HelpTextView(viewModel: viewModel)
                                .padding([.top, .leading], 20)
                            
                            if let player = scene.childNode(withName: "userBird") {
                                let x = Int(player.position.x)
                                let y = Int(player.position.y)
                                Text("x: \(x), y: \(y)")
                                    .font(.system(size: 13, design: .monospaced))
                                    .padding(6)
                                    .background(Color.black.opacity(0.45))
                                    .cornerRadius(6)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                        }
                        Spacer()
                    }
                }
                                    
                VStack {
                ToolbarButtonView(viewModel: viewModel, onExit: onExit)
                    
                    Spacer()
                    
                    
                    if viewModel.controlsAreVisable {
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
            .sheet(isPresented: Binding(get: { viewModel.showMiniGameSheet }, set: { newVal in
                if !newVal { return }
                else { viewModel.controlsAreVisable = false; viewModel.mapIsVisable = false }
            })) {
                MinigameOnboardingView(viewModel: viewModel)
            }
        }
    }
    
    static func resetGameState(in context: ModelContext) {
        if let oldStates = try? context.fetch(FetchDescriptor<GameState>()) {
            for gs in oldStates { context.delete(gs) }
            try? context.save()
        }
    }
    
    static func clearSavedGame(in context: ModelContext) {
        if let oldStates = try? context.fetch(FetchDescriptor<GameState>()) {
            for gs in oldStates { context.delete(gs) }
            try? context.save()
        }
    }
    
    func createScene() -> SKScene {
        let scene = PredatorGame(size: CGSize(width: 750, height: 1334))
        scene.scaleMode = .aspectFill
        
        scene.dismissAction = {
            withAnimation {
                self.onExit()
            }
        }
        return scene
    }
}

