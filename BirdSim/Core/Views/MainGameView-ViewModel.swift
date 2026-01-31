//
//  GameViewModel.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/21/26.
//

import Combine
import SwiftUI
import SpriteKit
import SwiftData


extension MainGameView {
    
    
  
    class ViewModel: ObservableObject {
        @Published var joystickVelocity: CGPoint = .zero
        @Published var pendingScaleDelta: CGFloat = 0
        @Published var isFlying: Bool = false
        @Published var controlsAreVisable: Bool = true
        @Published var savedPlayerPosition: CGPoint?
        @Published var savedCameraPosition: CGPoint?
        @Published var isMapMode: Bool = false
        @Published var mainScene: GameScene?
        @Published var health: CGFloat = 1
        @Published var showInventory: Bool = false
        @Published var inventory: [String: Int] = ["stick": 0, "leaf": 0, "spiderweb": 0]
        @Published var collectedItems: Set<String> = [] { didSet { scheduleSave() } }
        @Published var gameStarted: Bool = false
        @Published var showGameOver: Bool = false
        @Published var showGameWin: Bool = false
        @Published var currentMessage: String = ""
        
        // SwiftData context & model
        private var modelContext: ModelContext?
        private var gameState: GameState?
        private var cancellables = Set<AnyCancellable>()
        private var saveWorkItem: DispatchWorkItem?
        
        init(context: ModelContext) {
            self.modelContext = context

            if let existing = try? context.fetch(FetchDescriptor<GameState>()).first {
                self.gameState = existing
            } else {
                let gs = GameState()
                context.insert(gs)
                self.gameState = gs
                try? context.save()
            }

            if let gs = gameState {
                mapFromModel(gs)
            }

            bindAutoSave()
        }
        
        /// Convenience initializer for previews and legacy code paths that call `ViewModel()`.
        /// Creates an ephemeral ModelContainer and uses its mainContext.
        convenience init() {
            let container = try! ModelContainer(for: GameState.self)
            self.init(context: container.mainContext)
        }
        
        private func bindAutoSave() {
            $health
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $isFlying
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $savedPlayerPosition
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $savedCameraPosition
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $inventory
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $gameStarted
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $controlsAreVisable
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $showGameOver
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $showGameWin
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)
        }

        deinit {
            saveWorkItem?.cancel()
        }
        
        private func mapFromModel(_ m: GameState) {
            DispatchQueue.main.async {
                self.savedPlayerPosition = CGPoint(x: m.playerX, y: m.playerY)
                self.savedCameraPosition = CGPoint(x: m.cameraX, y: m.cameraY)
                self.isFlying = m.isFlying
                self.controlsAreVisable = m.controlsAreVisable
                self.gameStarted = m.gameStarted
                self.showGameOver = m.showGameOver
                self.showGameWin = m.showGameWin
                self.health = CGFloat(m.health)
                self.inventory = ["stick": m.inventoryStick, "leaf": m.inventoryLeaf, "spiderweb": m.inventorySpiderweb]
            }
        }
        
        private func mapToModel() {
            guard let gs = gameState else { return }
            if let p = savedPlayerPosition {
                gs.playerX = Double(p.x)
                gs.playerY = Double(p.y)
            }
            if let c = savedCameraPosition {
                gs.cameraX = Double(c.x)
                gs.cameraY = Double(c.y)
            }
            gs.isFlying = isFlying
            gs.controlsAreVisable = controlsAreVisable
            gs.gameStarted = gameStarted
            gs.showGameOver = showGameOver
            gs.showGameWin = showGameWin
            gs.health = Double(health)
            gs.inventoryStick = inventory["stick"] ?? 0
            gs.inventoryLeaf = inventory["leaf"] ?? 0
            gs.inventorySpiderweb = inventory["spiderweb"] ?? 0
        }
        
        private func scheduleSave() {
            saveWorkItem?.cancel()
            let item = DispatchWorkItem { [weak self] in
                self?.saveState()
            }
            saveWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: item)
        }
        
        func saveState() {
            mapToModel()
            do {
                try modelContext?.save()
            } catch {
                print("Failed to save game state:\(error)")
            }
        }
        
        func collectItem(_ name: String) {
                // Standardize to lowercase to match node names
            collectedItems.insert(name)
                let key = name.lowercased()
                if inventory.keys.contains(key) {
                    inventory[key, default: 0] += 1
                }
            
            scheduleSave()
            }
        
        func attach(gameState: GameState, context: ModelContext) {
            self.modelContext = context
            self.gameState = gameState
            mapFromModel(gameState)
            bindAutoSave()
        }
        
    }
    
}

protocol GameDelegate {
    func dismissGame()
}

extension MainGameView: GameDelegate {
    func dismissGame() {
        viewModel.gameStarted = false
    }
}
