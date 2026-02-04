//
//  GameScene.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/20/26.
//

import Foundation
import GameController
import SpriteKit

// MARK: - GameScene
// Main SpriteKit scene for the overworld.
// Responsible for:
// - Player movement & camera
// - Interaction detection
// - Spawning and managing predators/items
// - Transitioning into minigames
// - Syncing transient state with the SwiftUI ViewModel

class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Defaults
    let defaultPlayerStartPosition = CGPoint(x: 800, y: -400)
    let defaultCameraScale: CGFloat = 1.25

    // MARK: - ViewModel Bridge
    // Reference to SwiftUI ViewModel for shared game state & persistence
    weak var viewModel: MainGameView.ViewModel?

    let interactionLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    // MARK: - Internal State
    // Local runtime state for timing, cooldowns, and flags
    var hasInitializedWorld = false
    var lastUpdateTime: TimeInterval = 0
    var healthAccumulator: CGFloat = 0
    var positionPersistAccumulator: CGFloat = 0
    var lastAppliedIsFlying: Bool = false
    
    // MARK: - Walk Animaiton Variables
    // controls the walking animation for the user bird
    let walkFrames: [SKTexture] = [
        SKTexture(imageNamed: "Bird_Ground_Left"),
        SKTexture(imageNamed: "Bird_Ground_Right")
        
    ]
    
    
    var lastWalkSpeed: CGFloat? = nil
        
    lazy var walkAction: SKAction = {
        walkFrames.forEach { $0.filteringMode = .nearest }
        let animate = SKAction.animate(with: walkFrames,
                                      timePerFrame: 0.24,
                                      resize: false,
                                      restore: false)
        return SKAction.repeatForever(animate)
    }()
    
    let walkKey = "walk"

    // MARK: - Scene Graph Nodes
    // Root nodes for world content and UI overlays
    let worldNode = SKNode()
    let overlayNode = SKNode()

    // MARK: - Predator / Minigame Identifiers
    let predatorMini: String = "predatorMini"
    let buildNestMini: String = "buildNestMini"
    let feedUserBirdMini: String = "feedUserBirdMini"
    let feedBabyBirdMini: String = "feedBabyBirdMini"
    let leaveIslandMini: String = "leaveIslandMini"

    var buildNestMiniIsInRange: Bool = false
    var feedUserBirdMiniIsInRange: Bool = false
    var feedBabyBirdMiniIsInRange: Bool = false
    var leaveIslandMiniIsInRange: Bool = false
    var predatorHit: Bool = false
    let desiredPredatorCount: Int = 4

    var predatorCooldownEnd: Date?

    // Fixed spawn points for predators
    let predatorSpawnPoints: [CGPoint] = [
        CGPoint(x: 120, y: 150),
        CGPoint(x: -300, y: 200),
        CGPoint(x: 800, y: -100),
        CGPoint(x: -500, y: -200)
    ]

    // Tracks which spawn point indices are currently occupied
    var occupiedPredatorSpawns: Set<Int> = []
    var bannedPredatorSpawns: Set<Int> = []

    // MARK: - Input & Camera
    var virtualController: GCVirtualController?
    let cameraNode = SKCameraNode()
    var playerSpeed: CGFloat = 400.0
    var birdImage: String = "Bird_Ground_Right"
    
    // Babybird feed game variables //
    var babyHunger: CGFloat = 1.0 // 1.0 is full, 0.0 is starving
    let hungerDrainRate: CGFloat = 0.05 // Drains 5% every second
    var isBabySpawned: Bool = false
    var babySpawnTime: Date?
    let timeLimit: TimeInterval = 120 // 2 minutes to feed the baby
    

    // Joystick deadzone used for movement + walk animation gating
    let joystickDeadzone: CGFloat = 0.15

    // MARK: - Scene Lifecycle
    // Called when the scene is first presented.
    // Sets up camera, loads textures, and initializes world.
    override func didMove(to view: SKView) {
        
        // Start background music if it isn't already playing
        SoundManager.shared.startBackgroundMusic(track: .mainMap)
        
        self.physicsWorld.contactDelegate = self
        // Setup camera first
        self.camera = cameraNode
        if cameraNode.parent == nil {
            self.addChild(cameraNode)
            cameraNode.setScale(1.25)
        }

        if !hasInitializedWorld {
            // Preload the background texture
            let backgroundTexture = SKTexture(imageNamed: "map_land")
            SKTexture.preload([backgroundTexture]) { [weak self] in
                DispatchQueue.main.async {
                    self?.initializeGame(resetState: false)
                }
            }
        } else {
            if viewModel?.mainScene == nil {
                viewModel?.mainScene = self
            }
        }
        viewModel?.onNestSpawned = { [weak self] in
                // We call this on the main thread to ensure SpriteKit can add the node
                DispatchQueue.main.async {
                    self?.spawnSuccessNest()
                }
            }
        if let savedDate = viewModel?.babySpawnDate {
                self.babySpawnTime = savedDate
                self.isBabySpawned = true
            }
        restoreReturnStateIfNeeded()
        viewModel?.controlsAreVisable = true
        checkBabyWinCondition()
    }
    
    // Called when leaving this scene.
    // Persists player & camera positions.
    override func willMove(from view: SKView) {
        // Persist the latest positions before leaving the scene
        if let player = self.childNode(withName: "userBird") {
            viewModel?.savedPlayerPosition = player.position
        }
        viewModel?.savedCameraPosition = cameraNode.position
        viewModel?.saveState()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let nodeA = contact.bodyA.node
        let nodeB = contact.bodyB.node
      
        
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // 2. THIS IS THE ONLY PLACE SPAWN SHOULD HAPPEN
        if contactMask == (PhysicsCategory.player | PhysicsCategory.mate) {
            let maleNode = (nodeA?.name == "MaleBird") ? nodeA : nodeB
            
            if maleNode?.parent != nil {
                maleNode?.removeFromParent()
                viewModel?.hasFoundMale = true
                
                // Search for the nest ONLY when the male is touched
                if let emptyNest = nextEmptyNest() {
                    spawnBabyInNest(in: emptyNest)
                    viewModel?.currentMessage = "Found him! The baby has hatched."
                } else {
                    viewModel?.currentMessage = "Found him! Now go finish your nest."
                }
            }
        }
    }

    // Main per-frame update loop.
    // Handles:
    // - Timers & persistence
    // - Health drain
    // - Proximity checks
    // - Movement & camera follow
    // - UI message updates
    override func update(_ currentTime: TimeInterval) {
        buildNestMiniIsInRange = false
        feedUserBirdMiniIsInRange = false
        feedBabyBirdMiniIsInRange = false
        leaveIslandMiniIsInRange = false
        
        // Clear the message at the start of the frame so it goes away when out of range
        viewModel?.currentMessage = ""
        
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        
        let rawDelta: CGFloat = CGFloat(currentTime - lastUpdateTime)
        let deltaTime = min(max(rawDelta, 1.0/120.0), 1.0/30.0)
        lastUpdateTime = currentTime
        
        // Periodically persist player & camera positions (once per second)
        positionPersistAccumulator += deltaTime
        if positionPersistAccumulator >= 1.0 {
            positionPersistAccumulator = 0
            if let player = self.childNode(withName: "userBird") {
                viewModel?.savedPlayerPosition = player.position
            }
            viewModel?.savedCameraPosition = cameraNode.position
            viewModel?.saveState()
        }
        
        // Gradual health drain over time (frame-rate independent)
        if var health = viewModel?.health, health > 0 {
            let drainThisFrame = 0.01 * deltaTime
            health = max(0, health - drainThisFrame)
            if health != viewModel?.health {
                viewModel?.health = health
            }
        }
        
        if let spawnTime = babySpawnTime, let baby = babyBirdNode() {
            let elapsed = Date().timeIntervalSince(spawnTime)
            let remainingPercentage = CGFloat(1.0 - (elapsed / timeLimit))

            if let bar = baby.childNode(withName: "hungerBar") as? BabyHungerBar {
                bar.updateBar(percentage: remainingPercentage)
                if remainingPercentage > 0.25 {
                    bar.stopPanic()
                }
            }

            // Check if the 2-minute limit has passed
            if elapsed > timeLimit {
                // 1. Remove the Baby (works even if it's inside the nest)
                baby.removeFromParent()

                // 2. Remove the Nest
                // Inside the 'if elapsed > timeLimit' block
                let nestToRemove = self.childNode(withName: "final_nest") ?? self.childNode(withName: "nest_active")
                nestToRemove?.removeFromParent()

                // 3. Reset State
                babySpawnTime = nil
                viewModel?.clearNestAndBabyState()
                viewModel?.hasFoundMale = false
                viewModel?.currentMessage = "The nest was abandoned..."
                print("Nest and Baby disappeared due to timeout.")
            }
        }
        
        // Get player once instead of multiple times
        guard let player = self.childNode(withName: "userBird") else { return }

        // Check for nearby predators and trigger minigame
        if !predatorHit, let predator = closestPredator(to: player, within: 200) {
            transitionToPredatorGame(triggeringPredator: predator)
        }
        
        // Resolve predator cooldown and respawn up to desired count
        if predatorHit, let end = predatorCooldownEnd, Date() >= end {
            predatorHit = false
            predatorCooldownEnd = nil

            let currentCount = children.filter { $0.name == predatorMini }.count
            let needed = max(0, desiredPredatorCount - currentCount)
            if needed > 0 {
                for _ in 0..<needed {
                    if !spawnPredatorAtAvailableSpot() { break }
                }
            }
        }
        // Minigame checks
        // This usually lives inside the update() function or a dedicated checkProximity() function
        if viewModel?.isFlying == false {
            if viewModel?.messageIsLocked == false {
                
                // --- 1. Priority: Mini-Games & Objectives ---
                if checkDistance(to: "babyBird") {
                    feedBabyBirdMiniIsInRange = true
                    viewModel?.currentMessage = "Tap to feed baby bird"
                    
                } else if checkDistance(to: "final_nest") || checkDistance(to: "old_nest") {
                    if viewModel?.hasFoundMale == true {
                        viewModel?.currentMessage = "The baby has hatched!"
                    } else {
                        viewModel?.currentMessage = "Nest complete! Find your mate."
                    }
                    
                } else if checkDistance(to: buildNestMini) {
                    buildNestMiniIsInRange = true
                    viewModel?.currentMessage = "Tap to build a nest"
                    
                } else if checkDistance(to: feedUserBirdMini) {
                    feedUserBirdMiniIsInRange = true
                    viewModel?.currentMessage = "Tap to feed"
                    
                } else if checkDistance(to: leaveIslandMini) {
                    leaveIslandMiniIsInRange = true
                    viewModel?.currentMessage = "Tap to leave island"
                    
                } else {
                    // --- 2. Secondary: Item Pickups ---
                    var closestItem: SKNode?
                    var closestDistance: CGFloat = 200 // Max pickup range

                    for node in children where ["stick", "leaf", "spiderweb","dandelion"].contains(node.name) {
                        let dx = player.position.x - node.position.x
                        let dy = player.position.y - node.position.y
                        let distance = sqrt(dx * dx + dy * dy)

                        if distance < closestDistance {
                            closestDistance = distance
                            closestItem = node
                        }
                    }

                    if let item = closestItem {
                        viewModel?.currentMessage = "Pick up \(item.name?.capitalized ?? "")"
                    } else {
                        // 3. Clear message if nothing is nearby
                        viewModel?.currentMessage = ""
                    }
                }
            }
        } else {
            // Clear message if flying
            if viewModel?.messageIsLocked == false {
                viewModel?.currentMessage = ""
            }
        }
        
        
        if viewModel?.userFedBabyCount == 2 {
            // 1. Find the baby using the recursive search helper
            if let baby = babyBirdNode() {
                
                // 2. Identify the nest (the baby's parent)
                let nest = baby.parent
                
                // 3. STOP THE TIMER IMMEDIATELY
                // This prevents the "abandoned" timeout logic from firing
                self.babySpawnTime = nil
                self.isBabySpawned = false
                
                // 4. Update Game State
                viewModel?.userScore += 2
                viewModel?.userFedBabyCount = 0
                viewModel?.hasFoundMale = false
                viewModel?.clearNestAndBabyState()
                viewModel?.currentMessage = "The baby has grown and left the nest!"
                
                // 5. Visual Removal
                let fade = SKAction.fadeOut(withDuration: 0.5)
                let remove = SKAction.removeFromParent()
                
                // Removing the nest automatically removes the baby and the hunger bar
                nest?.run(SKAction.sequence([fade, remove]))
                
                print("DEBUG: Successfully cleared nest and baby after 2 feedings.")
            }
        }
        
        let message = viewModel?.currentMessage ?? ""
        interactionLabel.text = message
        if message.isEmpty {
            if interactionLabel.alpha != 0 {
                interactionLabel.removeAction(forKey: "msgFade")
                let fade = SKAction.fadeOut(withDuration: 0.2)
                interactionLabel.run(fade, withKey: "msgFade")
            }
        } else {
            if interactionLabel.alpha != 1 {
                interactionLabel.removeAction(forKey: "msgFade")
                let fade = SKAction.fadeIn(withDuration: 0.1)
                interactionLabel.run(fade, withKey: "msgFade")
            }
        }
        
        if let delta = viewModel?.pendingScaleDelta, delta != 0 {
            adjustPlayerScale(by: delta)
            viewModel?.pendingScaleDelta = 0
        }
        
        if let vm = viewModel {
            if vm.isFlying != lastAppliedIsFlying {
                lastAppliedIsFlying = vm.isFlying
                applyBirdState(isFlying: vm.isFlying)
            }
        }
        
        // Core movement + camera systems
        updatePlayerPosition(deltaTime: deltaTime)
        clampPlayerToMap()
        updateCameraFollow(target: player.position, deltaTime: deltaTime)
        resizeWaterToFillScreen()
        clampCameraToMap()
    }
    
    // MARK: - Input Handling
    // Handles taps for:
    // - Picking up items
    // - Triggering minigames
    
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            let touchedNodes = nodes(at: location)
            
            // --- 1. HANDLE MINIGAME SPOTS & SPECIAL OBJECTS ---
            for node in touchedNodes {
                // Predator Interaction
                if node.name == predatorMini, !predatorHit {
                    transitionToPredatorGame(triggeringPredator: node)
                    viewModel?.controlsAreVisable = false
                    return
                }
                
                // Build Nest Logic
                if (node.name == buildNestMini || node.name == "final_nest") {
                    if let player = self.childNode(withName: "userBird") {
                        let dx = player.position.x - node.position.x
                        let dy = player.position.y - node.position.y
                        let distance = sqrt(dx*dx + dy*dy)
                        if distance > 220 || viewModel?.isFlying == true { continue }
                    }
                    if let items = viewModel?.collectedItems,
                       items.contains("stick"),
                       items.contains("leaf"),
                       items.contains("spiderweb"),
                        items.contains("dandelion")
                    {
                        transitionToBuildNestScene()
                        viewModel?.controlsAreVisable = false
                        return
                    }
                }
                
                // Feed Self Logic
                if node.name == feedUserBirdMini {
                    if let player = self.childNode(withName: "userBird") {
                        let dx = player.position.x - node.position.x
                        let dy = player.position.y - node.position.y
                        let distance = sqrt(dx*dx + dy*dy)
                        if distance > 220 || viewModel?.isFlying == true { continue }
                    }
                    transitionToFeedUserScene()
                    viewModel?.controlsAreVisable = false
                    return
                }
                
                // Feed Baby Logic
                if node.name == feedBabyBirdMini || node.name == "babyBird" {
                    guard viewModel?.isFlying != true else { continue }

                    if let player = self.childNode(withName: "userBird") {
                        // If they tapped the baby, it may be nested. Use world coords.
                        let targetPos: CGPoint
                        if node.name == "babyBird" {
                            targetPos = node.convert(.zero, to: self)
                        } else {
                            targetPos = node.position
                        }

                        let dx = player.position.x - targetPos.x
                        let dy = player.position.y - targetPos.y
                        let distance = sqrt(dx*dx + dy*dy)
                        if distance > 200 { continue }
                    }

                    transitionToFeedBabyScene()
                    viewModel?.controlsAreVisable = false
                    return
                }
                
                // Leave Island Logic
                if node.name == leaveIslandMini {
                    if let player = self.childNode(withName: "userBird") {
                        let dx = player.position.x - node.position.x
                        let dy = player.position.y - node.position.y
                        let distance = sqrt(dx*dx + dy*dy)
                        if distance > 220 || viewModel?.isFlying == true { continue }
                    }
                    transitionToLeaveIslandMini()
                    viewModel?.controlsAreVisable = false
                    return
                }
            }
            
            // --- 2. HANDLE ITEM PICKUPS ---
            for node in touchedNodes {
                guard let name = node.name else { continue }
                if ["stick", "leaf", "spiderweb","dandelion"].contains(name) {
                    let largerHitArea = node.frame.insetBy(dx: -40, dy: -40)
                    if largerHitArea.contains(location), let player = self.childNode(withName: "userBird") {
                        let dx = player.position.x - node.position.x
                        let dy = player.position.y - node.position.y
                        let distance = sqrt(dx*dx + dy*dy)
                        
                        if distance < 200, viewModel?.isFlying == false {
                            pickupItem(node)
                            return
                        }
                    }
                }
            }
        } // End of touchesBegan

} // End of GameScene Class

  




