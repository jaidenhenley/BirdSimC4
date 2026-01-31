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
        
        //Matching Nest Game
        // The items the player MUST match
            @Published var challengeSequence: [String] = []
            // The items the player HAS matched so far
            @Published var playerAttempt: [String] = []
            @Published var isMemorizing: Bool = false
            @Published var currentMessageNestGame: String = ""
            @Published var slots: [String?] = [nil, nil, nil] // Stores item names in specific slots
        // Inside ViewModel
        @Published var messageIsLocked: Bool = false
        var onNestSpawned: (() -> Void)?
        


        func showPriorityMessage(_ message: String, duration: TimeInterval = 7.0) {
            self.currentMessage = message
            self.messageIsLocked = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.messageIsLocked = false
            }
        }
        
        var canStartNestGame: Bool {
            let sticks = inventory["stick"] ?? 0
            let leaves = inventory["leaf"] ?? 0
            let webs = inventory["spiderweb"] ?? 0
            
            return sticks >= 1 && leaves >= 1 && webs >= 1
        }
        // Update this in your ViewModel
        func updateSlot(at index: Int, with itemName: String) {
            // 1. Standardize the name
            let cleanName = itemName.lowercased().trimmingCharacters(in: .whitespaces)
            slots[index] = cleanName
            
            // 2. Debugging: Print to the console to see what's happening
            print("Current Slots: \(slots)")
            print("Target Sequence: \(challengeSequence)")
            
            // 3. Check if all slots are filled
            let allFilled = slots.allSatisfy { $0 != nil }
            
            if allFilled {
                // Map the [String?] to [String] to ensure a clean comparison
                let currentAttempt = slots.compactMap { $0 }
                
                if currentAttempt == challengeSequence {
                    print("MATCH FOUND! Transitioning...")
                    completeNestBuild()
                } else {
                    print("NO MATCH. Try again.")
                    // Optional: Reset slots if they get it wrong
                    // slots = [nil, nil, nil]
                }
            }
        }

        private func completeNestBuild() {
            saveWorkItem?.cancel()
            currentMessage = "Nest Built!"
            
            // 1. Trigger the spawn signal BEFORE clearing data
            self.onNestSpawned?()

            self.inventory = ["stick": 0, "leaf": 0, "spiderweb": 0]
            self.collectedItems.removeAll()
            self.slots = [nil, nil, nil]
            self.playerAttempt.removeAll()

            if let gs = gameState {
                gs.inventoryStick = 0
                gs.inventoryLeaf = 0
                gs.inventorySpiderweb = 0
                // Important: Save that the nest is built so it persists!
                // gs.isNestBuilt = true
            }
            
            do {
                try modelContext?.save()
            } catch {
                print("Error saving: \(error)")
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.onChallengeComplete?()
            }
        }
    
        
        // Inside your ViewModel class
        func startNewChallenge() {
            let possibleItems = ["stick", "leaf", "spiderweb"]
            
            // .shuffled() rearranges the original 3 items randomly
            // This ensures you get one of each, with no duplicates.
            challengeSequence = possibleItems.shuffled()
            
            // Reset state for the new game
            slots = [nil, nil, nil]
            playerAttempt = []
            isMemorizing = true
            currentMessageNestGame = "Memorize the order!"
        }
        
        func useItemFromInventory(itemName: String) {
                // Prevent tapping during the "Flash" phase
                guard !challengeSequence.isEmpty && !isMemorizing else { return }
                
                let key = itemName.lowercased()
                playerAttempt.append(key)
                
                let index = playerAttempt.count - 1
                if playerAttempt[index] != challengeSequence[index] {
                    currentMessage = "Wrong! Try again."
                    playerAttempt = []
                    // Optional: restart the flash if they fail
                    startNewChallenge()
                } else if playerAttempt.count == challengeSequence.count {
                    completeNestBuild()
                }
            }
        
        var onChallengeComplete: (() -> Void)?
        
        // Inside your ViewModel
        // In your ViewModel class variables
        var onChallengeFailed: (() -> Void)?

        // Simplified Logic for the Slot-based Nest Game
        func checkWinCondition() {
            // 1. Only check if all 3 slots have an item
            let currentAttempt = slots.compactMap { $0 }
            guard currentAttempt.count == 3 else { return }
            
            // 2. Compare the filled slots to the target sequence
            if currentAttempt == challengeSequence {
                print("MATCH FOUND! Completing nest...")
                completeNestBuild()
            } else {
                print("NO MATCH. Triggering failure...")
                // We delay slightly so the player sees the last item land before being kicked out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.onChallengeFailed?()
                }
            }
        }
        
       
        // End Nest Game
        
        
     
        
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
