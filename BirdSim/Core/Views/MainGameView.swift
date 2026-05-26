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
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @StateObject var viewModel: ViewModel
    @State private var scene = GameScene()
    var deviceType: Bool {
        UIDevice.current.userInterfaceIdiom == .pad ? true : false
    }

    
    
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
            GeometryReader { geo in
                let isLandscape = geo.size.width > geo.size.height
                
                ZStack(alignment: .bottomLeading) {
                    // rest of your view
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                        .onAppear {
                            scene.scaleMode = .resizeFill
                            scene.viewModel = viewModel
                        }
                    
                    if viewModel.controlsAreVisable {
                        VStack {
                            HStack {
                                VStack(alignment: .leading) {
                                    if !isLandscape {
                                        InventoryView(viewModel: viewModel, isIPad: deviceType)
                                            .padding([.top, .leading], 20)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                    
                                    DrainingHungerBarView(viewModel: viewModel, currentHunger: $viewModel.hunger, isIPad: deviceType)
                                        .padding([.top, .leading], 10)
                                    Spacer().frame(height: 6)
                                    BabyBarView(viewModel: viewModel, currentBabies: $viewModel.currentBabyAmount, isIPad: deviceType)
                                        .padding([.top, .leading], 10)
                                    PredatorBarView(viewModel: viewModel, isIPad: deviceType, currentDanger: $viewModel.predatorProximitySegments)
                                        .padding([.top, .leading], 10)
                                    
                                }
                                Spacer()
                                
                                
                            }
                            
                            HStack {
                                if deviceType {
                                    HelpTextView(viewModel: viewModel)
                                        .padding(20)
                                        .frame(width: 250)
                                }

                                if viewModel.coordinatesOn,
                                   let player = scene.childNode(withName: "userBird") {
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
                        ZStack(alignment: .top) {
                            let topButtonSize: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 80 : 52
                            HStack(alignment: .top) {
                                Spacer()

                                if viewModel.mapIsVisable {
                                    Button {
                                        if viewModel.isMapMode == false {
                                            viewModel.mainScene?.enterMapNode()
                                            viewModel.mainScene?.scene?.isPaused = true
                                        } else {
                                            viewModel.mainScene?.exitMapMode()
                                            viewModel.mainScene?.scene?.isPaused = false
                                        }
                                    } label: {
                                        Image(.compass)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: topButtonSize, height: topButtonSize)
                                            .background(Circle().fill(.black.opacity(0.7)))
                                            .padding()
                                    }
                                    .padding()
                                }

                                Button { onExit() } label: {
                                    Image(.pause)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: topButtonSize, height: topButtonSize)
                                        .padding()
                                }
                                .padding()
                            }

                            if isLandscape {
                                VStack(spacing: 4) {
                                    InventoryView(viewModel: viewModel, isIPad: deviceType)
                                    if !deviceType {
                                        HelpTextView(viewModel: viewModel)
                                    }
                                }
                                .padding(.top, 20)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }

                        Spacer()

                        if viewModel.controlsAreVisable {
                            let isiPad = UIDevice.current.userInterfaceIdiom == .pad
                            HUDControls(viewModel: viewModel)
                                .padding(.horizontal, isiPad ? 60 : 16)
                                .padding(.vertical, isiPad ? 60 : 8)
                        }
                    }
                }
                .animation(.spring, value: viewModel.showInventory)
                .sheet(isPresented: $viewModel.showMiniGameSheet, onDismiss: {
                    viewModel.startPendingMiniGame()
                }) {
                    MinigameOnboardingView(viewModel: viewModel)
                        .onAppear {
                            viewModel.controlsAreVisable = false
                            viewModel.mapIsVisable = false
                        }
                        .presentationDragIndicator(.hidden)
                }
                .sheet(isPresented: $viewModel.showMainInstructionSheet, onDismiss: {
                    viewModel.resumeAfterMainInstruction()
                }) {
                    MainOnboardingView(viewModel: viewModel, type: viewModel.pendingInstructionType!)
                        .presentationDragIndicator(.hidden)
                }
                
                
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
