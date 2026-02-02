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
            WinGameView(viewModel: viewModel, onExit: onExit)
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
                        
                        HStack {
                            HelpTextView(viewModel: viewModel)
                                .padding([.top, .leading], 20)
                            Spacer()
                        }
                        Spacer()
                    }
                }
                                    
                VStack {
                    HStack {
                        Spacer()
                        if viewModel.controlsAreVisable {
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
                        
                        Button() {
                            if viewModel.isMapMode == false {
                                viewModel.mainScene?.enterMapNode()
                            } else {
                                viewModel.mainScene?.exitMapMode()
                            }
                        } label: {
                            Image(systemName: "map.fill")
                                .font(.largeTitle)
                                .padding()
                                .background(Circle().fill(.ultraThinMaterial))
                        }
                        .padding()
                        
                        Button {
                            onExit()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.largeTitle)
                                .padding()
                                .background(Circle().fill(.ultraThinMaterial))
                        }
                        .padding()
                    }
                    
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

