//
//  GameScene.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/20/26.
//

import Foundation
import GameController
import SpriteKit

class GameScene: SKScene {
    
    weak var viewModel: MainGameView.ViewModel?
    
    let interactionLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    private var hasInitializedWorld = false
    private var lastUpdateTime: TimeInterval = 0
    private var healthAccumulator: CGFloat = 0
    private var lastAppliedIsFlying: Bool = false
    
    let worldNode = SKNode()
    let overlayNode = SKNode()
    
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
    
    var virtualController: GCVirtualController?
    let cameraNode = SKCameraNode()
    var playerSpeed: CGFloat = 400.0
    var birdImage: String = "Bird_Ground"
    
    override func didMove(to view: SKView) {
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
                    self?.initializeGame()
                }
            }
        } else {
            if viewModel?.mainScene == nil {
                viewModel?.mainScene = self
            }
        }

        restoreReturnStateIfNeeded()
    }
    override func didSimulatePhysics() {
        // Intentionally left empty – camera updates occur in update(_:)
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
        waterBackground.size = CGSize(width: 8000, height: 5000)
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
        
        // Health drain
        if var health = viewModel?.health, health > 0 {
            let drainThisFrame = 0.01 * deltaTime
            health = max(0, health - drainThisFrame)
            if health != viewModel?.health {
                viewModel?.health = health
            }
        }
        
        // Get player once instead of multiple times
        
        // Get player once instead of multiple times
        guard let player = self.childNode(withName: "userBird") else { return }
        
        // Predator check: find the closest predator within threshold and transition with that specific node
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
        func checkDistance(to nodeName: String, threshold: CGFloat = 200) -> Bool {
            guard let node = self.childNode(withName: nodeName) else { return false }
            let dx = player.position.x - node.position.x
            let dy = player.position.y - node.position.y
            return sqrt(dx*dx + dy*dy) < threshold
        }
        
        // Minigame checks
        if viewModel?.isFlying == false {
            if checkDistance(to: buildNestMini) {
                buildNestMiniIsInRange = true
                viewModel?.currentMessage = "Tap to build a nest"
            } else if checkDistance(to: feedUserBirdMini) {
                feedUserBirdMiniIsInRange = true
                viewModel?.currentMessage = "Tap to feed"
            } else if checkDistance(to: feedBabyBirdMini) {
                feedBabyBirdMiniIsInRange = true
                viewModel?.currentMessage = "Tap to feed baby bird"
            } else if checkDistance(to: leaveIslandMini) {
                leaveIslandMiniIsInRange = true
                viewModel?.currentMessage = "Tap to leave island"
                
            } else {
                // Check for closest item only if no minigame is in range
                var closestItem: SKNode?
                var closestDistance: CGFloat = .greatestFiniteMagnitude
                
                for node in children where node.name == "stick" || node.name == "leaf" || node.name == "spiderweb" {
                    let dx = player.position.x - node.position.x
                    let dy = player.position.y - node.position.y
                    let distance = sqrt(dx * dx + dy * dy)
                    
                    if distance < 200 && distance < closestDistance {
                        closestDistance = distance
                        closestItem = node
                    }
                }
                
                if let item = closestItem {
                    viewModel?.currentMessage = "Pick up \(item.name?.capitalized ?? "")"
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
        
        updatePlayerPosition(deltaTime: deltaTime)
        clampPlayerToMap()
        updateCameraFollow(target: player.position, deltaTime: deltaTime)
        resizeWaterToFillScreen()
        clampCameraToMap()
    }
    
    func applyBirdState(isFlying: Bool) {
        // Adjust movement speed
        playerSpeed = isFlying ? 650.0 : 400.0
        birdImage = isFlying ? "Bird_Flying_Open" : "Bird_Ground"
        
        // Cross-fade to the new texture
        crossFadeBirdTexture(to: birdImage, duration: 0.15)
        
        // Subtle scale pulse around the target scale
        if let bird = self.childNode(withName: "userBird") as? SKSpriteNode {
            let finalScale: CGFloat = isFlying ? 1.1 : 1.0
            let pulseUp = SKAction.scale(to: finalScale * 1.06, duration: 0.08)
            pulseUp.timingMode = .easeOut
            let pulseDown = SKAction.scale(to: finalScale, duration: 0.12)
            pulseDown.timingMode = .easeIn
            bird.run(SKAction.sequence([pulseUp, pulseDown]), withKey: "statePulse")
        }
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
                
                // Create an overlay sprite with the new texture, matching the bird's transform
                let overlay = SKSpriteNode(texture: newTexture)
                overlay.name = "userBird_crossfade_temp"
                overlay.position = bird.position
                overlay.zPosition = bird.zPosition + 1
                overlay.zRotation = bird.zRotation
                overlay.anchorPoint = bird.anchorPoint
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
                    bird.size = newTexture.size()
                    bird.alpha = 1.0
                    overlay.removeFromParent()
                })
            }
        }
    }

    
    func updatePlayerPosition(deltaTime: CGFloat) {
        guard let player = self.childNode(withName: "userBird") else { return }
        if viewModel?.isMapMode  == true { return }
        
        // Prefer SwiftUI joystick via view model (CGPoint normalized to [-1, 1])
        var inputPoint: CGPoint = viewModel?.joystickVelocity ?? .zero
        
        // Fallback to virtual controller if SwiftUI joystick is idle
        if inputPoint == .zero,
           let xValue = virtualController?.controller?.extendedGamepad?.leftThumbstick.xAxis.value,
           let yValue = virtualController?.controller?.extendedGamepad?.leftThumbstick.yAxis.value {
            inputPoint = CGPoint(x: CGFloat(xValue), y: CGFloat(yValue))
        }
        
        // Convert to vector components and clamp to unit circle
        var dx = inputPoint.x
        var dy = inputPoint.y
        let mag = sqrt(dx*dx + dy*dy)
        if mag > 1.0 {
            dx /= mag
            dy /= mag
        }
        
        let velocity = CGVector(dx: dx * playerSpeed, dy: dy * playerSpeed)
        player.position.x += velocity.dx * deltaTime
        player.position.y += velocity.dy * deltaTime
        
        // Smoothly rotate the bird to face movement direction using exponential damping
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        if speed > 0.001 {
            let target = atan2(velocity.dy, velocity.dx)
            let assetOrientationOffset: CGFloat = -(.pi / 2)
            let desired = target + assetOrientationOffset

            let current = player.zRotation
            let deltaAngle = atan2(sin(desired - current), cos(desired - current))

            // Use exponential damping for frame-rate independent rotation
            let turnStiffness: CGFloat = 12.0  // increased from 10.0 for snappier response
            let rotationFactor = 1 - exp(-turnStiffness * deltaTime)

            player.zRotation = current + deltaAngle * rotationFactor
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        // get location of touch in scene
        let location = touch.location(in: self)
        
        // Handle item taps: validate distance on tap
        for node in nodes(at: location) where node.name == "stick" {
            let largerHitArea = node.frame.insetBy(dx: -20, dy: -20)
            if largerHitArea.contains(location),
               let player = self.childNode(withName: "userBird") {
                let dx = player.position.x - node.position.x
                let dy = player.position.y - node.position.y
                let distance = sqrt(dx*dx + dy*dy)
                if distance < 200, viewModel?.isFlying == false {
                    pickupItem(node)
                    return
                }
            }
        }
        for node in nodes(at: location) where node.name == "leaf" {
            let largerHitArea = node.frame.insetBy(dx: -20, dy: -20)
            if largerHitArea.contains(location),
               let player = self.childNode(withName: "userBird") {
                let dx = player.position.x - node.position.x
                let dy = player.position.y - node.position.y
                let distance = sqrt(dx*dx + dy*dy)
                if distance < 200, viewModel?.isFlying == false {
                    pickupItem(node)
                    return
                }
            }
        }
        for node in nodes(at: location) where node.name == "spiderweb" {
            let largerHitArea = node.frame.insetBy(dx: -20, dy: -20)
            if largerHitArea.contains(location),
               let player = self.childNode(withName: "userBird") {
                let dx = player.position.x - node.position.x
                let dy = player.position.y - node.position.y
                let distance = sqrt(dx*dx + dy*dy)
                if distance < 200, viewModel?.isFlying == false {
                    pickupItem(node)
                    return
                }
            }
        }
        
        // handles tapped areas for minigames
        // find all nodes in the location
        let touchedNodes = nodes(at: location)
        
        // check is any of the touched nodes is in our minigame spot
        for node in touchedNodes {
            if node.name == predatorMini, !predatorHit {
                transitionToPredatorGame(triggeringPredator: node)
                viewModel?.controlsAreVisable = false
                return
            } else if node.name == buildNestMini, buildNestMiniIsInRange == true {
                transitionToBuildNestScene()
                viewModel?.controlsAreVisable = false
            } else if node.name == feedUserBirdMini, feedUserBirdMiniIsInRange == true {
                transitionToFeedUserScene()
                viewModel?.controlsAreVisable = false
            } else if node.name == feedBabyBirdMini, feedBabyBirdMiniIsInRange == true {
                transitionToFeedBabyScene()
                viewModel?.controlsAreVisable = false
            } else if node.name == leaveIslandMini, leaveIslandMiniIsInRange == true {
                if let items = viewModel?.collectedItems,
                   items.contains("stick"),
                   items.contains("leaf"),
                   items.contains("spiderweb") {
                    transitionToLeaveIslandMini()
                    viewModel?.controlsAreVisable = false
                }
            }
        }
    }
    
    func touchDown(atPoint pos : CGPoint) {
        
    }
    
    
    func touchMoved(toPoint pos : CGPoint) {
        
    }
    
    
    func touchUp(atPoint pos : CGPoint) {
        
    }
}

extension GameScene {
    
    func initializeGame() {
        viewModel?.joystickVelocity = .zero
        
        viewModel?.savedCameraPosition = nil
        viewModel?.savedPlayerPosition = nil
        viewModel?.health = 1
        viewModel?.isFlying = false
        
        self.removeAllChildren()
        
        viewModel?.gameStarted = true
        
        self.removeAllActions()
        
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
        
        hasInitializedWorld = true
        
        viewModel?.mainScene = self
    }
    
    func spawnItem(at position: CGPoint, type: String) {
        let item = SKSpriteNode(imageNamed: type)
        item.position = position
        item.name = type
        item.setScale(0.5)
        
        self.addChild(item)
    }
    
    func pickupItem(_ node: SKNode) {
        guard let name = node.name else { return }
        
        if viewModel?.collectedItems.contains(name) == true {
            print("\(name) already collected")
            return
        }
        // Update ViewModel
        viewModel?.collectItem(name)
        
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        
        node.run(SKAction.sequence([
            moveUp, fadeOut, remove
        ]))
        
        print("Bird tapped a \(name)")
    }
    
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
}

extension GameScene {
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
        }
    }
    
    func setupUserBird() {
        if self.childNode(withName: "userBird") != nil { return }
        
        let player = SKSpriteNode(imageNamed: birdImage)
        player.position = CGPoint(x: 800, y: -400)
        player.zPosition = 10
        player.name = "userBird"
        
        self.addChild(player)
    }
        
    func startPredatorTimer() {
        self.removeAction(forKey: "predatorCooldown")
        
        let wait = SKAction.wait(forDuration: 5.0) //adjust timer here for predator cooldown
        let reset = SKAction.run { [weak self] in
            guard let self = self else {
                return
            }
            self.predatorHit = false
            
            if self.childNode(withName: self.predatorMini) == nil {
                let spawnPoint = self.nextPredatorSpawnPoint()
                self.setupPredator(at: spawnPoint)
            }
        }
        
        let sequence = SKAction.sequence([
            wait,reset
        ])
        self.run(sequence, withKey: "predatorCooldown")
    
    }
    
    func nextPredatorSpawnPoint() -> CGPoint {
        let randomPoints: [CGPoint] = [
            CGPoint(x: 120, y: 150),
            CGPoint(x: -300, y: 200),
            CGPoint(x: 800, y: -100),
            CGPoint(x: -500, y: -200)
        ]
        
        return randomPoints.randomElement() ?? CGPoint(x: 120, y: 150)
    }
    
    // Returns a random free spawn index, or nil if all are occupied or banned
    func nextAvailablePredatorSpawnIndex() -> Int? {
        let available = (0..<predatorSpawnPoints.count).filter { !occupiedPredatorSpawns.contains($0) && !bannedPredatorSpawns.contains($0) }
        return available.randomElement()
    }

    // Spawns a predator at a free spot and marks it occupied.
    @discardableResult
    func spawnPredatorAtAvailableSpot() -> Bool {
        guard let index = nextAvailablePredatorSpawnIndex() else { return false }
        let position = predatorSpawnPoints[index]
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
    
    
    
    
    func transitionToLeaveIslandMini() {
        guard let view = self.view else { return }
        saveReturnState()
        let minigameScene = LeaveIslandScene(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.viewModel = self.viewModel
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(minigameScene, transition: transition)
    }
    
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
    
    func transitionToBuildNestScene() {
        guard let view = self.view else { return }
        saveReturnState()
        let minigameScene = BuildNestScene(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.viewModel = self.viewModel
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(minigameScene, transition: transition)
    }
    
    func transitionToFeedUserScene() {
        guard let view = self.view else { return }
        saveReturnState()
        let minigameScene = FeedUserScene(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.viewModel = self.viewModel
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(minigameScene, transition: transition)
    }
    
    func transitionToFeedBabyScene() {
        guard let view = self.view else { return }
        saveReturnState()
        let minigameScene = FeedBabyScene(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.viewModel = self.viewModel
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(minigameScene, transition: transition)
    }
    
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
    // Dynamically resize the water to fill the camera view, with extra padding to eliminate black edges.
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


