//
//  GameScene.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/20/26.
//

import Foundation
import GameController
import SpriteKit

struct PhysicsCategory {
    static let none:   UInt32 = 0
    static let player: UInt32 = 0b1      // 1
    static let mate:   UInt32 = 0b10     // 2
    static let nest:   UInt32 = 0b100    // 4
}


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
    private let defaultPlayerStartPosition = CGPoint(x: 800, y: -400)
    private let defaultCameraScale: CGFloat = 1.25

    // MARK: - ViewModel Bridge
    // Reference to SwiftUI ViewModel for shared game state & persistence
    weak var viewModel: MainGameView.ViewModel?

    let interactionLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    // Babybird feed game variables //
    var babyHunger: CGFloat = 1.0 // 1.0 is full, 0.0 is starving
    let hungerDrainRate: CGFloat = 0.05 // Drains 5% every second
    var isBabySpawned: Bool = false
    var babySpawnTime: Date?
    let timeLimit: TimeInterval = 120 // 2 minutes to feed the baby
    
    
    // MARK: - Internal State
    // Local runtime state for timing, cooldowns, and flags
    private var hasInitializedWorld = false
    private var lastUpdateTime: TimeInterval = 0
    private var healthAccumulator: CGFloat = 0
    private var positionPersistAccumulator: CGFloat = 0
    private var lastAppliedIsFlying: Bool = false
    
    // MARK: - Walk Animaiton Variables
    // controls the walking animation for the user bird
    private let walkFrames: [SKTexture] = [
        SKTexture(imageNamed: "Bird_Ground_Left"),
        SKTexture(imageNamed: "Bird_Ground_Right")
        
    ]
    
    private var lastWalkSpeed: CGFloat? = nil
        
    private lazy var walkAction: SKAction = {
        walkFrames.forEach { $0.filteringMode = .nearest }
        let animate = SKAction.animate(with: walkFrames,
                                      timePerFrame: 0.24,
                                      resize: false,
                                      restore: false)
        return SKAction.repeatForever(animate)
    }()
    
    private let walkKey = "walk"
    
        
    

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

    private var predatorCooldownEnd: Date?

    // Fixed spawn points for predators
    private let predatorSpawnPoints: [CGPoint] = [
        CGPoint(x: 120, y: 150),
        CGPoint(x: -300, y: 200),
        CGPoint(x: 800, y: -100),
        CGPoint(x: -500, y: -200)
    ]

    // Tracks which spawn point indices are currently occupied
    private var occupiedPredatorSpawns: Set<Int> = []
    private var bannedPredatorSpawns: Set<Int> = []

    // MARK: - Input & Camera
    var virtualController: GCVirtualController?
    let cameraNode = SKCameraNode()
    var playerSpeed: CGFloat = 400.0
    var birdImage: String = "Bird_Ground_Right"

    // Joystick deadzone used for movement + walk animation gating
    private let joystickDeadzone: CGFloat = 0.15

    // MARK: - Scene Lifecycle
    // Called when the scene is first presented.
    // Sets up camera, loads textures, and initializes world.
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self // <--- ADD THIS LINE
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
        restoreReturnStateIfNeeded()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // 1. Identify which nodes are involved
        let nodeA = contact.bodyA.node
        let nodeB = contact.bodyB.node
        
        // 2. Combine categories to see WHAT touched WHAT
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // CASE A: Player touches Male Bird (Hatch Baby)
        if contactMask == (PhysicsCategory.player | PhysicsCategory.mate) {
            let maleNode = (nodeA?.name == "MaleBird") ? nodeA : nodeB
            
            // Ensure we only trigger this once
            if maleNode?.parent != nil {
                maleNode?.removeFromParent()
                viewModel?.hasFoundMale = true
                viewModel?.currentMessage = "Found him! The baby has hatched."
                spawnBabyInNest()
            }
        }
        
        // CASE B: Player touches Predator (Example logic)
        /*
        if contactMask == (PhysicsCategory.player | PhysicsCategory.predator) {
            let predatorNode = (nodeA?.name == predatorMini) ? nodeA : nodeB
            if let predator = predatorNode {
                transitionToPredatorGame(triggeringPredator: predator)
            }
        }
        */
    }
    
    func spawnSuccessNest() {
        let nest = SKSpriteNode(imageNamed: "built_nest") // Make sure you have this image
        nest.name = "final_nest"
        nest.size = CGSize(width: 100, height: 100)
        nest.zPosition = 5 // Above the ground
        
        // Pick a random spot within a specific range
        // Adjust these numbers based on where your island "land" actually is
        let randomX = CGFloat.random(in: -1000...1000)
        let randomY = CGFloat.random(in: -1000...1000)
        nest.position = CGPoint(x: randomX, y: randomY)
        
        // Add a little "poof" animation so it doesn't just pop in
        nest.alpha = 0
        nest.setScale(0.1)
        addChild(nest)
        
        let appear = SKAction.group([
            SKAction.fadeIn(withDuration: 1.0),
            SKAction.scale(to: 1.0, duration: 1.0)
        ])
        nest.run(appear)
        
        print("Nest spawned at: \(nest.position)")
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
        
        if let spawnTime = babySpawnTime {
            let elapsed = Date().timeIntervalSince(spawnTime)
            
            // Check if the 2-minute limit has passed
            if elapsed > timeLimit {
                // 1. Remove the Baby
                if let baby = self.childNode(withName: "babyBird") {
                    baby.removeFromParent()
                }
                
                // 2. Remove the Nest
                if let nest = self.childNode(withName: "final_nest") {
                    // Optional: Add a fade-out effect before removing
                    let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                    let remove = SKAction.removeFromParent()
                    nest.run(SKAction.sequence([fadeOut, remove]))
                }
                
                // 3. Reset State
                babySpawnTime = nil
                viewModel?.hasFoundMale = false // Reset this so they have to try again
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
        
        // Single distance check function to reduce code duplication
        // Proximity-based interaction messages
        func checkDistance(to nodeName: String, threshold: CGFloat = 200) -> Bool {
            guard let node = self.childNode(withName: nodeName) else { return false }
            let dx = player.position.x - node.position.x
            let dy = player.position.y - node.position.y
            return sqrt(dx*dx + dy*dy) < threshold
        }

        // Minigame checks
        // This usually lives inside the update() function or a dedicated checkProximity() function
        if viewModel?.isFlying == false {
            if viewModel?.messageIsLocked == false {
                
                // --- 1. Priority: Mini-Games & Objectives ---
                if checkDistance(to: "babyBird") {
                    feedBabyBirdMiniIsInRange = true
                    viewModel?.currentMessage = "Tap to feed baby bird"
                    
                } else if checkDistance(to: "final_nest") {
                    // Check if we found the mate yet
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

                    for node in children where ["stick", "leaf", "spiderweb"].contains(node.name) {
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
            removeBabyBird()
            //add score for completing a baby
        }

        
        
        func clearCollectedItemsFromMap() {
            // Look for any nodes that match your item names
            for node in children {
                if let name = node.name, ["stick", "leaf", "spiderweb"].contains(name) {
                    // Only remove them if the player has actually "built" with them
                    // Or just remove all to 'respawn' them later
                    node.removeFromParent()
                }
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
            adjustCircleScale(by: delta)
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
    
    // MARK: - Player State
    // Applies visual & gameplay changes when switching flying/ground modes.
    // - Updates speed and default texture.
    // - Stops ground-walk animation when entering flight.
    // - Cross-fades the texture and plays a subtle scale pulse.
    func applyBirdState(isFlying: Bool) {
        // Adjust movement speed
        playerSpeed = isFlying ? 650.0 : 400.0

        // Choose the "base" texture for the new state
        birdImage = isFlying ? "Bird_Flying_Open" : "Bird_Ground_Right"

        // If we just entered flight, ensure we are not running the ground walk animation.
        if isFlying, let bird = self.childNode(withName: "userBird") as? SKSpriteNode {
            stopWalking(bird)
        }

        // Cross-fade to the new texture so state changes feel smooth.
        crossFadeBirdTexture(to: birdImage, duration: 0.15)

        // Subtle scale pulse around the target scale (tiny feedback that state changed).
        if let bird = self.childNode(withName: "userBird") as? SKSpriteNode {
            let finalScale: CGFloat = isFlying ? 1.1 : 1.0
            let pulseUp = SKAction.scale(to: finalScale * 1.06, duration: 0.08)
            pulseUp.timingMode = .easeOut
            let pulseDown = SKAction.scale(to: finalScale, duration: 0.12)
            pulseDown.timingMode = .easeIn
            bird.run(SKAction.sequence([pulseUp, pulseDown]), withKey: "statePulse")
        }
    }

    // MARK: - Player Movement
    // Moves the player based on joystick or controller input.
    // - Uses a deadzone so tiny joystick drift doesn't move the character.
    // - Keeps speed consistent by clamping the input vector to the unit circle.
    // - Rotates the bird to face its movement direction (with exponential damping).
    func updatePlayerPosition(deltaTime: CGFloat) {
        guard let player = self.childNode(withName: "userBird") as? SKSpriteNode else { return }

        // In map mode, we prevent walking animation and don't process movement here.
        if viewModel?.isMapMode == true {
            stopWalking(player)
            return
        }

        // Prefer SwiftUI joystick via view model (CGPoint normalized to [-1, 1])
        var inputPoint: CGPoint = viewModel?.joystickVelocity ?? .zero

        // Fallback to virtual controller if SwiftUI joystick is idle
        if inputPoint == .zero,
           let xValue = virtualController?.controller?.extendedGamepad?.leftThumbstick.xAxis.value,
           let yValue = virtualController?.controller?.extendedGamepad?.leftThumbstick.yAxis.value {
            inputPoint = CGPoint(x: CGFloat(xValue), y: CGFloat(yValue))
        }

        // Convert to vector components
        var dx = inputPoint.x
        var dy = inputPoint.y

        // Determine if the joystick is actively moving (deadzone)
        let rawMag = sqrt(dx * dx + dy * dy)
        let isMoving = rawMag > joystickDeadzone

        // MARK: Walk Animation Gating
        // Only show the ground-walk animation when:
        // - we're NOT flying, and
        // - the input magnitude is above the deadzone.
        let isFlyingNow = viewModel?.isFlying ?? false
        if isFlyingNow {
            stopWalking(player)
        } else {
            if isMoving {
                startWalking(player, speed: rawMag)
            } else {
                stopWalking(player)
            }
        }

        // Clamp to unit circle for consistent speed
        var mag = rawMag
        if mag > 1.0 {
            dx /= mag
            dy /= mag
            mag = 1.0
        }

        // Convert input to a velocity in world units
        let velocity: CGVector = isMoving
            ? CGVector(dx: dx * playerSpeed, dy: dy * playerSpeed)
            : .zero

        // Apply movement
        player.position.x += velocity.dx * deltaTime
        player.position.y += velocity.dy * deltaTime

        // Rotate the bird to face movement direction (smooth + frame-rate independent)
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        if speed > 0.001 {
            let target = atan2(velocity.dy, velocity.dx)

            // Your texture appears oriented "up" by default, so we offset by -90 degrees
            let assetOrientationOffset: CGFloat = -(.pi / 2)
            let desired = target + assetOrientationOffset

            let current = player.zRotation
            let deltaAngle = atan2(sin(desired - current), cos(desired - current))

            // Exponential damping for stable smoothing across different frame rates
            let turnStiffness: CGFloat = 12.0  // higher = snappier
            let rotationFactor = 1 - exp(-turnStiffness * deltaTime)

            player.zRotation = current + deltaAngle * rotationFactor
        }
    }

    // MARK: - Walk Animation
    // Creates a repeat-forever walk action where `speedMultiplier` (0..1)
    // affects how quickly we step between frames.
    private func makeWalkAction(speedMultiplier: CGFloat) -> SKAction {
        let minFrameTime: CGFloat = 0.30    // slower steps
        let maxFrameTime: CGFloat = 0.18    // faster steps

        // Clamp multiplier into a safe range
        let t = max(0.1, min(speedMultiplier, 1.0))

        // Linearly interpolate timePerFrame (lower time = faster animation)
        let frameTime = minFrameTime - (minFrameTime - maxFrameTime) * t

        let animate = SKAction.animate(
            with: walkFrames,
            timePerFrame: frameTime,
            resize: false,
            restore: false
        )

        return SKAction.repeatForever(animate)
    }

    // Starts (or updates) the ground-walk animation.
    // We avoid restarting the action every frame by only refreshing when
    // the speed meaningfully changes.
    private func startWalking(_ player: SKSpriteNode, speed: CGFloat) {
        let didSpeedChange = abs((lastWalkSpeed ?? 0) - speed) > 0.05

        // Only start walking action if not already running OR speed changed significantly
        if player.action(forKey: walkKey) == nil || didSpeedChange {
            let walk = makeWalkAction(speedMultiplier: speed)
            player.removeAction(forKey: walkKey)
            player.run(walk, withKey: walkKey)
            lastWalkSpeed = speed
        }
    }

    // Stops the ground-walk animation and clears cached speed.
    private func stopWalking(_ player: SKSpriteNode) {
        player.removeAction(forKey: walkKey)
        lastWalkSpeed = nil
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
                if (node.name == buildNestMini || node.name == "final_nest"), buildNestMiniIsInRange {
                    if let items = viewModel?.collectedItems,
                       items.contains("stick"),
                       items.contains("leaf"),
                       items.contains("spiderweb") {
                        transitionToBuildNestScene()
                        viewModel?.controlsAreVisable = false
                        return
                    }
                }
                
                // Feed Self Logic
                if node.name == feedUserBirdMini, feedUserBirdMiniIsInRange {
                    transitionToFeedUserScene()
                    viewModel?.controlsAreVisable = false
                    return
                }
                
                // Feed Baby Logic
                if (node.name == feedBabyBirdMini || node.name == "babyBird"), feedBabyBirdMiniIsInRange {
                    transitionToFeedBabyScene()
                    viewModel?.controlsAreVisable = false
                    return
                }
                
                // Leave Island Logic
                if node.name == leaveIslandMini, leaveIslandMiniIsInRange {
                    transitionToLeaveIslandMini()
                    viewModel?.controlsAreVisable = false
                    return
                }
            }
            
            // --- 2. HANDLE ITEM PICKUPS ---
            for node in touchedNodes {
                guard let name = node.name else { continue }
                if ["stick", "leaf", "spiderweb"].contains(name) {
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

        // MARK: - Helper Functions
        func pickupItem(_ node: SKNode) {
            guard let rawName = node.name else { return }
            // Standardize to lowercase so set membership is consistent
            let itemName = rawName.lowercased()

            // Drive inventory UI from collectedItems via the ViewModel helper
            // This also persists and optionally updates counts if you still track them
            if viewModel?.collectedItems.contains(itemName) == true {
                viewModel?.currentMessage = " You already have \(itemName)"
                return
            }
            
            viewModel?.collectItem(itemName)

            // Remove the item from the world
            node.removeFromParent()

            // Optional: brief feedback
            viewModel?.currentMessage = "Picked up \(itemName.capitalized)"
            scheduleRespawn(for: node.name!)
            print("Successfully added \(itemName) to collected items.")
        }

        // Add any missing transition functions below this line
    func transitionToFeedBabyScene() {
        guard let view = self.view else { return }
        saveReturnState()
        let minigameScene = FeedBabyScene(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.viewModel = self.viewModel
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(minigameScene, transition: transition)
    }

    } // End of GameScene Class

// MARK: - World Setup & Utilities
// All helper methods for spawning, clamping, camera, transitions, etc.
extension GameScene {
    
    // Nest game //
        
    func spawnBabyInNest() {
        // Look for "final_nest" (the name used in spawnSuccessNest)
        guard let nest = self.childNode(withName: "final_nest") else {
            print("Error: Could not find 'final_nest' to spawn the baby.")
            return
        }
        
        let baby = SKSpriteNode(imageNamed: "baby_bird_idle")
        baby.name = "babyBird"
        // Position the baby slightly inside the nest
        baby.position = CGPoint(x: nest.position.x, y: nest.position.y + 10)
        baby.zPosition = nest.zPosition + 1
        baby.setScale(0.5)
        
        // Add physics so the player can "touch" the baby to feed it
        baby.physicsBody = SKPhysicsBody(circleOfRadius: 25)
        baby.physicsBody?.isDynamic = false
        baby.physicsBody?.categoryBitMask = PhysicsCategory.nest
        baby.physicsBody?.contactTestBitMask = PhysicsCategory.player
        babySpawnTime = Date()
            print("Baby spawned! Timer started.")
        addChild(baby)
        
        // Visual Hatch Effect
        baby.alpha = 0
        baby.run(SKAction.fadeIn(withDuration: 1.0))
        
        viewModel?.currentMessage = "The baby has hatched! Now keep it fed."
    }
    
    func removeBabyBird() {
        self.childNode(withName: "babyBird")?.removeFromParent()
    }
    
    
    func spawnMaleBird() {
            if childNode(withName: "MaleBird") != nil { return }
            
            let maleBird = SKSpriteNode(imageNamed: "male_bird")
            maleBird.name = "MaleBird"
            maleBird.size = CGSize(width: 50, height: 50)
            maleBird.zPosition = 5
            
            // Position him somewhere random but far enough away to be a "quest"
            let randomX = CGFloat.random(in: 500...1000) * (Bool.random() ? 1 : -1)
            let randomY = CGFloat.random(in: 500...1000) * (Bool.random() ? 1 : -1)
            maleBird.position = CGPoint(x: randomX, y: randomY)
            
            // Physics for contact detection
            maleBird.physicsBody = SKPhysicsBody(circleOfRadius: 25)
            maleBird.physicsBody?.isDynamic = false
            maleBird.physicsBody?.categoryBitMask = PhysicsCategory.mate
            maleBird.physicsBody?.contactTestBitMask = PhysicsCategory.player
            maleBird.physicsBody?.collisionBitMask = PhysicsCategory.none
            
            addChild(maleBird)
        }
        
        

    func scheduleRespawn(for itemName: String) {
        print("⏰ Respawn timer started for: \(itemName). Will appear in 30s.")
        
        // Create a sequence of 5-second waits to print progress
        let segment = SKAction.sequence([
            SKAction.wait(forDuration: 5.0),
            SKAction.run { print("... \(itemName) respawning in 25s...") },
            SKAction.wait(forDuration: 5.0),
            SKAction.run { print("... \(itemName) respawning in 20s...") },
            SKAction.wait(forDuration: 10.0),
            SKAction.run { print("... \(itemName) respawning in 10s...") },
            SKAction.wait(forDuration: 10.0)
        ])
        
        let spawn = SKAction.run { [weak self] in
            guard let self = self, let player = self.childNode(withName: "userBird") else { return }
            
            // DEBUG: Instead of totally random, spawn it within 500 pixels of the player
            // so you can actually see it happen!
            let randomX = player.position.x + CGFloat.random(in: -500...500)
            let randomY = player.position.y + CGFloat.random(in: -500...500)
            let spawnPoint = CGPoint(x: randomX, y: randomY)
            
            self.spawnItem(at: spawnPoint, type: itemName)
            
            
            print("✅ SUCCESS: \(itemName) respawned at \(spawnPoint)")
        }
        
        self.run(SKAction.sequence([segment, spawn]))
    }

    // Helper to help you find the respawned item visually
    func createDebugFlare(at pos: CGPoint) {
        let circle = SKShapeNode(circleOfRadius: 100)
        circle.strokeColor = .yellow
        circle.lineWidth = 5
        circle.position = pos
        circle.zPosition = 100
        addChild(circle)
        circle.run(SKAction.sequence([SKAction.fadeOut(withDuration: 2.0), SKAction.removeFromParent()]))
    }
    
    
    // End Nest Game//
    
    // Initializes or resets the entire world state.
    // Spawns background, player, predators, items, and restores save state.
    func initializeGame(resetState: Bool = false) {
        viewModel?.joystickVelocity = .zero
        
        if resetState {
            viewModel?.showGameWin = false
            viewModel?.savedCameraPosition = nil
            viewModel?.savedPlayerPosition = nil
            viewModel?.health = 1
            viewModel?.isFlying = false
            viewModel?.gameStarted = true
            viewModel?.inventory = ["stick": 0, "leaf": 0, "spiderweb": 0]
            viewModel?.collectedItems.removeAll()
            viewModel?.savedPlayerPosition = nil
            viewModel?.showGameWin = false
        }
        
        self.removeAllChildren()
        
        setupBackground()
        setupUserBird()
        self.predatorHit = false
        self.predatorCooldownEnd = nil
        occupiedPredatorSpawns.removeAll()
        bannedPredatorSpawns.removeAll()
        // Spawn up to desiredPredatorCount unique predators
        var spawned = 0
        while spawned < min(desiredPredatorCount, predatorSpawnPoints.count) && spawnPredatorAtAvailableSpot() {
            spawned += 1
        }
        setupBuildNestSpot()
        setupFeedUserBirdSpot()
        setupFeedBabyBirdSpot()
        setupLeaveIslandSpot()
        
        spawnItem(at: CGPoint(x: 400, y: 100), type: "leaf")
        spawnItem(at: CGPoint(x: 200, y: 100), type: "stick")
        spawnItem(at: CGPoint(x: -600, y: 100), type: "stick")
        spawnItem(at: CGPoint(x: -400, y: 300), type: "leaf")
        spawnItem(at: CGPoint(x: -700, y: 400), type: "spiderweb")
        spawnItem(at: CGPoint(x: 700, y: 200), type: "spiderweb")
        
        
        spawnItem(at: CGPoint(x: 900, y: 900), type: "tree1")

        // If we're resetting, force the player + camera back to defaults and
        // overwrite any previously persisted return state.
        if resetState {
            if let player = self.childNode(withName: "userBird") {
                player.position = defaultPlayerStartPosition
            }
            cameraNode.position = defaultPlayerStartPosition
            cameraNode.setScale(defaultCameraScale)

            viewModel?.savedPlayerPosition = defaultPlayerStartPosition
            viewModel?.savedCameraPosition = defaultPlayerStartPosition
        }
        
        hasInitializedWorld = true
        
        viewModel?.mainScene = self
        // Only restore persisted positions when NOT doing a full reset.
        if !resetState {
            restoreReturnStateIfNeeded()
        }
    }
    func setupBackground() {
        // Remove existing background
        self.children
            .filter { $0.name == "background" }
            .forEach { $0.removeFromParent() }
        
        let grassTexture = SKTexture(imageNamed: "map_land")
        grassTexture.usesMipmaps = true
        grassTexture.filteringMode = .linear
        
        let waterTexture = SKTexture(imageNamed: "map_water")
        waterTexture.usesMipmaps = true
        waterTexture.filteringMode = .linear
        
        let grassBackground = SKSpriteNode(texture: grassTexture)
        grassBackground.name = "background"
        grassBackground.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        grassBackground.position = .zero
        grassBackground.zPosition = -1
        
        // Treat map as fixed world size (no scaling hacks)
        grassBackground.size = CGSize(width: 8000, height: 5000)
        grassBackground.xScale = 1
        grassBackground.yScale = 1
        
        let waterBackground = SKSpriteNode(texture: waterTexture)
        waterBackground.name = "background1"
        waterBackground.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        waterBackground.position = .zero
        waterBackground.zPosition = -2
        waterBackground.size = CGSize(width: 12000, height: 12000)
        
        // Treat map as fixed world size (no scaling hacks)
        waterBackground.size = CGSize(width: 10000, height: 5000)
        waterBackground.xScale = 1
        waterBackground.yScale = 1
        
        
        
        addChild(grassBackground)
        addChild(waterBackground)
        
        // DEBUG: visualize world bounds
        // let mapFrame = SKShapeNode(rect: background.frame)
        // mapFrame.strokeColor = .green
        // mapFrame.lineWidth = 8
        // mapFrame.zPosition = 1000
        // addChild(mapFrame)
    }
    
    func spawnItem(at position: CGPoint, type: String) {
        let item = SKSpriteNode(imageNamed: type)
        item.position = position
        item.name = type
        item.setScale(0.5)
        
        self.addChild(item)
    }
    
    
    
    // Prevents the camera from leaving the map bounds.
    func clampCameraToMap() {
        guard let camera = camera,
              let background = self.childNode(withName: "background") as? SKSpriteNode,
              let view = self.view else { return }
        
        let halfWidth = (view.bounds.width * 0.5) * camera.xScale
        let halfHeight = (view.bounds.height * 0.5) * camera.yScale
        
        let mapRect = CGRect(
            x: background.position.x - background.size.width/2,
            y: background.position.y - background.size.height/2,
            width: background.size.width,
            height: background.size.height
        )
        
        var pos = camera.position
        pos.x = max(mapRect.minX + halfWidth, min(pos.x, mapRect.maxX - halfWidth))
        pos.y = max(mapRect.minY + halfHeight, min(pos.y, mapRect.maxY - halfHeight))
        camera.position = pos
    }
    
    // Prevents the player from leaving the map bounds.
    func clampPlayerToMap() {
        guard let player = self.childNode(withName: "userBird"),
              let background = self.childNode(withName: "background") as? SKSpriteNode else { return }
        
        let halfWidth = background.size.width / 2
        let halfHeight = background.size.height / 2
        
        let minX = background.position.x - halfWidth
        let maxX = background.position.x + halfWidth
        let minY = background.position.y - halfHeight
        let maxY = background.position.y + halfHeight
        
        player.position.x = max(minX, min(player.position.x, maxX))
        player.position.y = max(minY, min(player.position.y, maxY))
    }
    
    func zoomToFitMap() {
        guard let backgroud = childNode(withName: "background") as? SKSpriteNode,
              let view = self.view else { return }
        
        let scaleX = view.bounds.width / backgroud.size.width
        let scaleY = view.bounds.height / backgroud.size.height
        
        let zoom = min(scaleX, scaleY)
        cameraNode.setScale(1 / zoom)
    }
    
    func enterMapNode() {
        viewModel?.isMapMode = true
        viewModel?.controlsAreVisable = false
        
        guard let background = childNode(withName: "background") else { return }
        // center camera on map
        cameraNode.position = background.position
        // zoom out
        zoomToFitMap()
        // add player marker
        showPlayerMarker()
    }
    
    func exitMapMode() {
        viewModel?.isMapMode = false
        viewModel?.controlsAreVisable = true
        
        // Remove marker
        childNode(withName: "mapMarker")?.removeFromParent()
        
        // Snap camera back to player
        if let player = childNode(withName: "userBird") {
            cameraNode.position = player.position
            cameraNode.setScale(1.25) // your normal zoom
        }
    }
    
    func showPlayerMarker() {
        guard let player = childNode(withName: "userBird") else { return }
        
        let marker = SKShapeNode(circleOfRadius: 20)
        marker.fillColor = .red
        marker.strokeColor = .clear
        marker.name = "mapMarker"
        marker.zPosition = 1000
        marker.position = player.position
        addChild(marker)
    }
    
    // Smooth camera follow using exponential damping and dead zone.
    func updateCameraFollow(target: CGPoint, deltaTime: CGFloat) {
        // Exponential damping for smooth, frame-rate independent following
        let stiffness: CGFloat = 6.0   // higher = snappier, lower = smoother
        let deadZone: CGFloat = 20.0   // ignore tiny movements near the center
        
        let dx = target.x - cameraNode.position.x
        let dy = target.y - cameraNode.position.y
        
        // Apply dead zone to reduce jitter
        let tx = abs(dx) > deadZone ? dx : 0
        let ty = abs(dy) > deadZone ? dy : 0
        
        // Stable interpolation factor across frame rates
        let factor = 1 - exp(-stiffness * deltaTime)
        
        cameraNode.position.x += tx * factor
        cameraNode.position.y += ty * factor
    }
    
    
    
    func saveReturnState() {
        if let player = self.childNode(withName: "userBird") {
            viewModel?.savedPlayerPosition = player.position
        }
        viewModel?.savedCameraPosition = cameraNode.position
    }
    func restoreReturnStateIfNeeded() {
        if let pos = viewModel?.savedPlayerPosition,
           let player = self.childNode(withName: "userBird") {
            player.position = pos
        }
        if let camPos = viewModel?.savedCameraPosition {
            cameraNode.position = camPos
        } else if let player = self.childNode(withName: "userBird") {
            cameraNode.position = player.position
            cameraNode.setScale(defaultCameraScale)
        }
    }
    
    func setupUserBird() {
        if self.childNode(withName: "userBird") != nil { return }
        
        let player = SKSpriteNode(imageNamed: birdImage)
        player.size = CGSize(width: 100, height: 100)
        player.position = defaultPlayerStartPosition
        player.zPosition = 10
        player.name = "userBird"
        
        // --- ADD PHYSICS HERE ---
        // Create a circular physics body slightly smaller than the bird for "fair" collisions
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width * 0.4)
        
        // 'isDynamic' must be true for the bird to trigger contact events while moving
        player.physicsBody?.isDynamic = true
        
        // Turn off gravity so your bird doesn't fall off the screen
        player.physicsBody?.affectedByGravity = false
        
        // Assign its identity
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        
        // Tell it to "report" hits with the male bird
        player.physicsBody?.contactTestBitMask = PhysicsCategory.mate
        
        // 'collisionBitMask' at .none ensures you fly THROUGH the male bird instead of bouncing off
        player.physicsBody?.collisionBitMask = PhysicsCategory.none
        // -------------------------
        
        self.addChild(player)
    }
    
    func crossFadeBirdTexture(to imageName: String, duration: TimeInterval = 0.15) {
        // If the bird doesn't exist yet, create it with the target texture
        guard let existing = self.childNode(withName: "userBird") as? SKSpriteNode else {
            let node = SKSpriteNode(imageNamed: imageName)
            node.name = "userBird"
            node.zPosition = 10
            addChild(node)
            return
        }
        
        // Avoid work if the texture already matches
        if let tex = existing.texture, tex.description.contains(imageName) {
            return
        }
        
        let newTexture = SKTexture(imageNamed: imageName)
        SKTexture.preload([newTexture]) { [weak self] in
            guard let self = self,
                  let bird = self.childNode(withName: "userBird") as? SKSpriteNode else { return }
            DispatchQueue.main.async {
                // Remove any previous temp overlay
                self.childNode(withName: "userBird_crossfade_temp")?.removeFromParent()
                
                // Create an overlay sprite with the new texture, matching the bird's transform and size
                let overlay = SKSpriteNode(texture: newTexture)
                overlay.name = "userBird_crossfade_temp"
                overlay.position = bird.position
                overlay.zPosition = bird.zPosition + 1
                overlay.zRotation = bird.zRotation
                overlay.anchorPoint = bird.anchorPoint
                overlay.size = bird.size
                overlay.xScale = bird.xScale
                overlay.yScale = bird.yScale
                overlay.alpha = 0
                self.addChild(overlay)
                
                let fadeIn = SKAction.fadeIn(withDuration: duration)
                let fadeOut = SKAction.fadeOut(withDuration: duration)
                
                bird.run(fadeOut, withKey: "crossfadeOut")
                overlay.run(fadeIn, completion: { [weak self] in
                    guard let self = self,
                          let bird = self.childNode(withName: "userBird") as? SKSpriteNode else { return }
                    bird.texture = newTexture
//                    bird.size = newTexture.size()
                    bird.alpha = 1.0
                    overlay.removeFromParent()
                })
            }
        }
    }
    
    // Returns true if the player is within threshold of any predator node
    func isPlayerNearAnyPredator(player: SKNode, threshold: CGFloat = 200) -> Bool {
        for node in children where node.name == predatorMini {
            let dx = player.position.x - node.position.x
            let dy = player.position.y - node.position.y
            let distance = sqrt(dx*dx + dy*dy)
            if distance < threshold {
                return true
            }
        }
        return false
    }
    
    func createRandomPredatorSpawn() -> CGPoint {
        guard let background = self.childNode(withName: "background") as? SKSpriteNode else {
            return .zero
        }

        let halfWidth = background.size.width / 2
        let halfHeight = background.size.height / 2

        let randomX = CGFloat.random(in: -halfWidth...halfWidth)
        let randomY = CGFloat.random(in: -halfHeight...halfHeight)

        return CGPoint(x: randomX, y: randomY)
    }
    
    // Returns a random free spawn index, or nil if all are occupied or banned
    func nextAvailablePredatorSpawnIndex() -> Int? {
        let available = (0..<predatorSpawnPoints.count).filter { !occupiedPredatorSpawns.contains($0) && !bannedPredatorSpawns.contains($0) }
        return available.randomElement()
    }
    
    // Spawns a predator at a free spot and marks it occupied.
    @discardableResult
    
    
    func spawnPredatorAtAvailableSpot() -> Bool {
        guard let index = nextAvailablePredatorSpawnIndex(),
              let background = self.childNode(withName: "background") as? SKSpriteNode else { return false }

        // Compute random point inside map bounds
        let halfWidth = background.size.width / 2
        let halfHeight = background.size.height / 2

        let randomX = CGFloat.random(in: -halfWidth...halfWidth)
        let randomY = CGFloat.random(in: -halfHeight...halfHeight)
        let position = CGPoint(x: randomX, y: randomY)

        occupiedPredatorSpawns.insert(index)
        setupPredator(at: position, spawnIndex: index)
        return true
    }
    
    func removePredator(_ node: SKNode, banSpawn: Bool = true) {
        if let idx = node.userData?["spawnIndex"] as? Int {
            occupiedPredatorSpawns.remove(idx)
            if banSpawn {
                bannedPredatorSpawns.insert(idx)
            }
        }
        node.removeFromParent()
    }
    
    func closestPredator(to player: SKNode, within threshold: CGFloat) -> SKNode? {
        var closest: SKNode?
        var closestDist = threshold
        for node in children where node.name == predatorMini {
            let dx = player.position.x - node.position.x
            let dy = player.position.y - node.position.y
            let dist = sqrt(dx*dx + dy*dy)
            if dist < closestDist {
                closestDist = dist
                closest = node
            }
        }
        return closest
    }
    
    func setupPredator(at position: CGPoint? = nil, spawnIndex: Int? = nil) {
        let spot = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        
        spot.position = position ?? CGPoint(x: 120, y: 150)
        spot.name = predatorMini
        
        if spot.userData == nil { spot.userData = [:] }
        if let idx = spawnIndex {
            spot.userData?["spawnIndex"] = idx
        }
        
        let moveRight = SKAction.moveBy(x: 1000, y: 0, duration: 3)
        let moveLeft = moveRight.reversed()
        let sequence = SKAction.sequence([moveRight, moveLeft])
        let repeatForever = SKAction.repeatForever(sequence)
        spot.run(repeatForever)
        addChild(spot)
    }
    func removeAllPredators() {
        for node in children where node.name == predatorMini {
            node.removeFromParent()
        }
        occupiedPredatorSpawns.removeAll()
    }
    
    func startPredatorCooldown(duration: TimeInterval = 5.0) {
        predatorHit = true
        predatorCooldownEnd = Date().addingTimeInterval(duration)
    }
    
    func setupLeaveIslandSpot() {
        if self.childNode(withName: leaveIslandMini) != nil { return }
        let spot = SKSpriteNode(color: .systemCyan, size: CGSize(width: 50, height: 50))
        spot.position = CGPoint(x: 200, y: -450)
        spot.name = leaveIslandMini
        addChild(spot)
    }
    
    func setupBuildNestSpot() {
        if self.childNode(withName: buildNestMini) != nil { return }
        let spot = SKSpriteNode(color: .blue, size: CGSize(width: 50, height: 50))
        spot.position = CGPoint(x: -200, y: -150)
        spot.name = buildNestMini
        addChild(spot)
    }
    
    func setupFeedUserBirdSpot() {
        if self.childNode(withName: feedUserBirdMini) != nil { return }
        let spot = SKSpriteNode(color: .green, size: CGSize(width: 50, height: 50))
        spot.position = CGPoint(x: -200, y: 150)
        spot.name = feedUserBirdMini
        addChild(spot)
    }
    
    func setupFeedBabyBirdSpot() {
        if self.childNode(withName: feedBabyBirdMini) != nil { return }
        let spot = SKSpriteNode(color: .yellow, size: CGSize(width: 50, height: 50))
        spot.position = CGPoint(x: 200, y: -150)
        spot.name = feedBabyBirdMini
        addChild(spot)
    }
    
    
    
    
    // Scene transition helpers for minigames.
    func transitionToLeaveIslandMini() {
        guard let view = self.view else { return }
        saveReturnState()
        let minigameScene = LeaveIslandScene(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.viewModel = self.viewModel
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(minigameScene, transition: transition)
    }
    
    // Scene transition helpers for minigames.
    func transitionToPredatorGame(triggeringPredator predator: SKNode) {
        guard let view = self.view else { return }
        saveReturnState()
        removePredator(predator, banSpawn: true)
        startPredatorCooldown(duration: 5.0)
        viewModel?.controlsAreVisable = false
        // Removed these lines as per instructions:
        // self.childNode(withName: predatorMini)?.removeFromParent()
        // startPredatorTimer()
        let minigameScene = PredatorGame(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.viewModel = self.viewModel
        minigameScene.dismissAction = { [weak self] in
            DispatchQueue.main.async {
                self?.viewModel?.showGameOver = true
                self?.viewModel?.controlsAreVisable = false
            }
        }
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(minigameScene, transition: transition)
    }
    
    // Scene transition helpers for minigames.
    func transitionToBuildNestScene() {
        guard let vm = viewModel, let view = self.view else { return }
        
        // 1. Prepare UI
        vm.controlsAreVisable = false
        saveReturnState()
        
        // 2. Clear the items BEFORE moving (Consuming the materials)
        vm.collectedItems.removeAll()
        
        // 3. Initialize and transition
        let minigameScene = BuildNestScene(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.viewModel = vm
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(minigameScene, transition: transition)
        
        print("Transitioning to Nest Scene...")
    }
    
    // Scene transition helpers for minigames.
    func transitionToFeedUserScene() {
        guard let view = self.view else { return }
        saveReturnState()
        let minigameScene = FeedUserScene(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.viewModel = self.viewModel
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(minigameScene, transition: transition)
    }
    
    // Scene transition helpers for minigames.
    
    
    func adjustCircleScale(by delta: CGFloat) {
        guard let circle = self.childNode(withName: "userBird") as? SKShapeNode else { return }
        
        let targetScale = max(0.7, min(1.1, circle.xScale + delta))
        
        guard abs(targetScale - circle.xScale) > .ulpOfOne else { return }
        
        // Stop any in-flight scale animation to avoid stacking
        circle.removeAction(forKey: "scaleEase")
        
        // Animate scale with ease-in-out timing
        let duration: TimeInterval = 1
        let scaleAction = SKAction.scale(to: targetScale, duration: duration)
        scaleAction.timingMode = .easeInEaseOut
        circle.run(scaleAction, withKey: "scaleEase")
        
    }
    // Dynamically resizes water background so it always fills the visible camera area.
    // Prevents black edges when zooming or panning.
    func resizeWaterToFillScreen() {
        guard let view = self.view else { return }
        
        let padding: CGFloat = 150.0 // extra buffer to prevent black edges
        let visibleWidth = view.bounds.width * cameraNode.xScale + padding
        let visibleHeight = view.bounds.height * cameraNode.yScale + padding
        
        for node in children where node.name == "background1" {
            if let water = node as? SKSpriteNode {
                water.size = CGSize(
                    width: max(water.size.width, visibleWidth),
                    height: max(water.size.height, visibleHeight)
                )
                
                // Center water on camera, plus small offset to ensure coverage
                water.position = cameraNode.position
            }
        }
    }
    
}

