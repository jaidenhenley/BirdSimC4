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
        @Published var mapIsVisable: Bool = true
        @Published var savedPlayerPosition: CGPoint?
        @Published var savedCameraPosition: CGPoint?
        @Published var isMapMode: Bool = false
        @Published var mainScene: GameScene?
        @Published var hunger = 1
        @Published var predatorProximitySegments: Int = 0
        @Published var showInventory: Bool = false
        @Published var inventory: [String: Int] = ["stick": 0, "leaf": 0, "spiderweb": 0, "dandelion": 0]
        @Published var collectedItems: Set<String> = [] { didSet { scheduleSave() } }
        @Published var gameStarted: Bool = false
        @Published var showGameOver: Bool = false
        @Published var showGameWin: Bool = false
        @Published var currentMessage: String = ""
        @Published var currentBabyAmount: Int = 0
        @Published var currentDanger: Int = 0
        
        // SwiftData context & model
        private var modelContext: ModelContext?
        private var gameState: GameState?
        private var cancellables = Set<AnyCancellable>()
        private var saveWorkItem: DispatchWorkItem?
        
        // babybirdnestgame//
        // Add these inside class ViewModel, near your other @Published vars
        @Published var hasFoundMale: Bool = false
        @Published var hasPlayedBabyGame: Bool = false
        @Published var isBabyReadyToGrow: Bool = false
        // Inside MainGameView.ViewModel
        // Inside MainGameView.ViewModel
        @Published var activeNestNode: SKNode?
        @Published var pendingNestWorldPosition: CGPoint?
        @Published var pendingNestAnchorTreeName: String?

        // Inside your ViewModel
        
        
        @Published var nestPosition: CGPoint?
        // Inside MainGameView.ViewModel
        @Published var scoreAnimating: Bool = false

        @Published var highScore: Int = UserDefaults.standard.integer(forKey: "highScore")
        @Published var isNewRecord: Bool = false

        // Update your userScore property to include this logic:
        @Published var userScore: Int = 0 {
            didSet {
                // Trigger Animation Flag
                scoreAnimating = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.scoreAnimating = false
                }

                // High Score Logic
                if userScore > highScore {
                    highScore = userScore
                    UserDefaults.standard.set(highScore, forKey: "highScore")
                    isNewRecord = true
                }
            }
        }
        
        func incrementFeedingForCurrentNest() {
            // 1. Identify WHICH nest we are interacting with
            guard let nest = activeNestNode else { return }
            
            // 2. Update ONLY that nest's local data
            if let data = nest.userData as? NSMutableDictionary {
                // This resets the "timer" for just this one bird
                data["spawnDate"] = Date()
                
                // This increments the "score" for just this one bird
                let currentFed = (data["fedCount"] as? Int) ?? 0
                data["fedCount"] = currentFed + 1
                
                print("DEBUG: Refilled hunger for specific nest. Total feeds: \(currentFed + 1)")
            }
        }

        
        
        //end baby bird game//
        
        
        
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
        @Published var hasNest: Bool = false
        @Published var hasBaby: Bool = false
        @Published var babyRaisingProgress: Double = 0.0 // 0.0 to 1.0 (1.0 = 2 minutes)
        @Published var isRaisingBaby: Bool = false

        func startFeedingTimer() {
            isRaisingBaby = true
            // We increment this in the background or during the mini-game
        }
            
            func startMatingPhase() {
                self.hasNest = true
                self.currentMessage = "Nest Complete! Find a male bird to start your family."
                
                // This reaches into the main GameScene to drop the CPU bird
                self.mainScene?.spawnMaleBird()
            }
        


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
            let dandelions = inventory["dandelion"] ?? 0

            
            
            return sticks >= 1 && leaves >= 1 && webs >= 1 && dandelions >= 1        }
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
                }
            }
        }

        private func completeNestBuild() {
            saveWorkItem?.cancel()
            
            // 1. UI Feedback
            currentMessage = "Nest Built!"
            
            // 2. Trigger the physical nest to appear on the GameScene map
            self.onNestSpawned?()
            
            hasNest = true
            scheduleSave()
            
            
            // 3. START THE MATING PHASE (This spawns the Male Bird)
            self.startMatingPhase()

            // Consuming materials after a successful build: clear both counts and set
            self.inventory = ["stick": 0, "leaf": 0, "spiderweb": 0, "dandelion": 0]
            self.collectedItems.removeAll()

            // 4. Reset temporary game data
            self.slots = [nil, nil, nil]
            self.playerAttempt.removeAll()

            // 5. Update Persistent Storage (SwiftData)
            if let gs = gameState {
                gs.inventoryStick = 0
                gs.inventoryLeaf = 0
                gs.inventorySpiderweb = 0
                gs.inventoryDandelion = 0
                // Ensure your GameState model has this property to remember the progress
                // gs.isNestBuilt = true
            }
            
            do {
                try modelContext?.save()
            } catch {
                print("Error saving: \(error)")
            }

            // 6. Return to the Main Map
            // We wait 1.5 seconds so the player can actually read the "Nest Built!" message
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // This tells the BuildNestScene to transition back to GameScene
                self.onChallengeComplete?()
                
                // Ensure controls (joystick/buttons) come back
                self.controlsAreVisable = true
            }
        }
    
        
        // Inside your ViewModel class
        func startNewChallenge() {
            let possibleItems = ["stick", "leaf", "spiderweb", "dandelion"]
            
            // .shuffled() rearranges the original 3 items randomly
            // This ensures you get one of each, with no duplicates.
            challengeSequence = possibleItems.shuffled()
            
            // Reset state for the new game
            slots = [nil, nil, nil, nil]
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
            guard currentAttempt.count == 4 else { return }
            
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
            
            UserDefaults.standard.register(defaults: [
                    "is_music_enabled": true,
                    "is_sound_enabled": true
                ])

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
            
            self.highScore = UserDefaults.standard.integer(forKey: "highScore")
            
            if let gs = gameState, self.collectedItems.isEmpty {
                var rebuilt: Set<String> = []
                if gs.inventoryStick > 0 { rebuilt.insert("stick") }
                if gs.inventoryLeaf > 0 { rebuilt.insert("leaf") }
                if gs.inventorySpiderweb > 0 { rebuilt.insert("spiderweb") }
                if gs.inventoryDandelion > 0 { rebuilt.insert("dandelion") }

                self.collectedItems = rebuilt
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
            $currentBabyAmount
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)
            
            $hunger
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $isFlying
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $savedPlayerPosition
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $inventory
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $gameStarted
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $userScore
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $hasFoundMale
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)
            
            // REMOVED: $userFedBabyCount, $babyPosition, $babySpawnDate
        }

        deinit {
            saveWorkItem?.cancel()
        }
        
        private func mapFromModel(_ state: GameState) {
            DispatchQueue.main.async {
                self.savedPlayerPosition = CGPoint(x: state.playerX, y: state.playerY)
                self.savedCameraPosition = CGPoint(x: state.cameraX, y: state.cameraY)
                self.isFlying = state.isFlying
                self.controlsAreVisable = state.controlsAreVisable
                self.gameStarted = state.gameStarted
                self.showGameOver = state.showGameOver
                self.showGameWin = state.showGameWin
                self.hunger = max(0, min(5, Int(state.hunger)))
                self.inventory = ["stick": state.inventoryStick, "leaf": state.inventoryLeaf, "spiderweb": state.inventorySpiderweb, "dandelion": state.inventoryDandelion]
                self.userScore = state.userScore
                self.hasFoundMale = state.hasFoundMale
                self.hasPlayedBabyGame = state.hasPlayedBabyGame
                self.isBabyReadyToGrow = state.isBabyReadyToGrow
                self.currentBabyAmount = state.currentBabyAmount
                
                self.hasNest = state.hasNest
                self.nestPosition = state.hasNest ? CGPoint(x: state.nestX, y: state.nestY) : nil
                self.hasBaby = state.hasBaby
                
                // Note: babyPosition and babySpawnDate removed to fix "Refill All" bug
            }
        }
        
        private func mapToModel() {
            guard let gs = gameState else { return }
            if let p = savedPlayerPosition {
                gs.playerX = Double(p.x)
                gs.playerY = Double(p.y)
            }
            gs.isFlying = isFlying
            gs.hunger = Double(hunger)
            gs.inventoryStick = inventory["stick"] ?? 0
            gs.inventoryLeaf = inventory["leaf"] ?? 0
            gs.inventorySpiderweb = inventory["spiderweb"] ?? 0
            gs.inventoryDandelion = inventory["dandelion"] ?? 0

            
            gs.userScore = userScore
            gs.hasFoundMale = hasFoundMale
            gs.hasNest = hasNest
            gs.currentBabyAmount = currentBabyAmount

            if let pos = nestPosition {
                gs.nestX = pos.x
                gs.nestY = pos.y
            }

            gs.hasBaby = hasBaby
            // babySpawnTimestamp and babyX/Y are no longer mapped to global ViewModel vars
        }
        
        func scheduleSave() {
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
        
        // MARK: - Nest/Baby Removal (Step 7)
        // MARK: - Nest/Baby Removal
        func clearNestAndBabyState() {
            // 1. Reset the high-level flags
            hasBaby = false
            hasNest = false
            
            // 2. Clear the nest position
            nestPosition = nil

            // Note: babyPosition and babySpawnDate were removed
            // to allow each bird to have its own independent timer.
            
            scheduleSave()
        }
        
        var hungerSegments: Int {
            return max(0, min(5, hunger))
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

