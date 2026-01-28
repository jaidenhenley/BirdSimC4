//
//  GameScene.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/20/26.
//

import SpriteKit
import GameController

class GameScene: SKScene {
    
    weak var viewModel: MainGameViewModel?
    
    let interactionLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    private var hasInitializedWorld = false
    private var lastUpdateTime: TimeInterval = 0
    private var healthAccumulator: CGFloat = 0
    private var lastAppliedIsFlying: Bool = false
    
    let worldNode = SKNode()
    let overlayNode = SKNode()
    
    let predator: String = "predatorNode"
    let miniGame1: String = "miniGameNode1"
    let miniGame2: String = "miniGameNode2"
    let miniGame3: String = "miniGameNode3"
    
    var miniGame1IsInRange: Bool = false
    var miniGame2IsInRange: Bool = false
    var miniGame3IsInRange: Bool = false
    var predatorHit: Bool = false
    
    var virtualController: GCVirtualController?
    let cameraNode = SKCameraNode()
    var playerSpeed: CGFloat = 400.0
    var birdImage: String = "Bird_Ground"
    
    override func didMove(to view: SKView) {
        
        if !hasInitializedWorld {
            setupBackground()
            setupUserBird()
            setupPredator()
            setupMiniGame1Spot()
            setupMiniGame2Spot()
            setupMiniGame3Spot()
            
            spawnItem(at: CGPoint(x: 400, y: 100), type: "leaf")
            spawnItem(at: CGPoint(x: 200, y: 100), type: "stick")
            spawnItem(at: CGPoint(x: -600, y: 100), type: "stick")
            spawnItem(at: CGPoint(x: -400, y: 300), type: "leaf")
            
            hasInitializedWorld = true
            
            viewModel?.mainScene = self
        } else {
            if viewModel?.mainScene == nil {
                viewModel?.mainScene = self
            }
        }
        // setupVirtualController()
        self.camera = cameraNode
        if cameraNode.parent == nil {
            self.addChild(cameraNode)
            cameraNode.setScale(1.25)
        }
        if interactionLabel.parent == nil {
            interactionLabel.fontSize = 24
            interactionLabel.fontColor = .white
            interactionLabel.position = CGPoint(x: 0, y: -200) // Lower center of screen
            interactionLabel.zPosition = 1000
            cameraNode.addChild(interactionLabel)
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
        
        let texture = SKTexture(imageNamed: "TestBirdMap")
        texture.usesMipmaps = true
        texture.filteringMode = .linear
        
        let background = SKSpriteNode(texture: texture)
        background.name = "background"
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        background.position = .zero
        background.zPosition = -1
        
        // Treat map as fixed world size (no scaling hacks)
        background.size = CGSize(width: 5000, height: 3800)
        background.xScale = 1
        background.yScale = 1
        
        addChild(background)
        
        // DEBUG: visualize world bounds
        // let mapFrame = SKShapeNode(rect: background.frame)
        // mapFrame.strokeColor = .green
        // mapFrame.lineWidth = 8
        // mapFrame.zPosition = 1000
        // addChild(mapFrame)
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // A. Start with an empty message
        var currentMessage = ""
        miniGame1IsInRange = false
        miniGame2IsInRange = false
        miniGame3IsInRange = false
        
        
        
        //Initialize last update time on the first frame
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        
        //Calculate how much time has passed since last frame
        let rawDelta: CGFloat
        if lastUpdateTime == 0 {
            rawDelta = 1.0 / 60.0 // assume one frame on first update
        } else {
            rawDelta = CGFloat(currentTime - lastUpdateTime)
        }
        
        // Clamp delta between ~8ms (120fps) and ~33ms (30fps)
        let deltaTime = min(max(rawDelta, 1.0/120.0), 1.0/30.0)
        lastUpdateTime = currentTime
        
        // Smooth, frame-based health drain (1% per second by default)
        if var health = viewModel?.health, health > 0 {
            let drainPerSecond: CGFloat = 0.01 // 1%/sec
            let drainThisFrame = drainPerSecond * deltaTime
            health = max(0, health - drainThisFrame)
            if health != viewModel?.health {
                viewModel?.health = health
            }
        }
        
        
        // Get the player and the target node(Predator Attack Radius)
        if let player = self.childNode(withName: "userBird"),
           let portal = self.childNode(withName: predator){
            //2. Calculate the distance between them using the Pythagorean theorem
            let dx = player.position.x - portal.position.x
            let dy = player.position.y - portal.position.y
            let distance = sqrt(dx*dx + dy*dy)
            
            // If distance is less then 200 pixels, trigger the game
            
            if distance < 200, predatorHit == false {
                transitionToPredatorGame()
                predatorHit = true
                startPredatorTimer()
                viewModel?.controlsAreVisable = false
            }
        }
        if let player = self.childNode(withName: "userBird"),
           let portal = self.childNode(withName: miniGame1){
            //2. Calculate the distance between them using the Pythagorean theorem
            let dx = player.position.x - portal.position.x
            let dy = player.position.y - portal.position.y
            let distance = sqrt(dx*dx + dy*dy)
            
            // If distance is less then 200 pixels, trigger the game
            
            if distance < 200 {
                miniGame1IsInRange = true
                currentMessage = "Play MiniGame 1" // Set message here
            }
        }
        
        if let player = self.childNode(withName: "userBird"),
           let portal = self.childNode(withName: miniGame2){
            //2. Calculate the distance between them using the Pythagorean theorem
            let dx = player.position.x - portal.position.x
            let dy = player.position.y - portal.position.y
            let distance = sqrt(dx*dx + dy*dy)
            
            // If distance is less then 200 pixels, trigger the game
            
            if distance < 200 {
                miniGame2IsInRange = true
                currentMessage = "Play MiniGame 2" // Set message here
            }
        }
        
        if let player = self.childNode(withName: "userBird"),
           let portal = self.childNode(withName: miniGame3){
            // Calculate the distance between them using the Pythagorean theorem
            let dx = player.position.x - portal.position.x
            let dy = player.position.y - portal.position.y
            let distance = sqrt(dx*dx + dy*dy)
            
            // If distance is less then 200 pixels, trigger the game
            
            if distance < 200 {
                miniGame3IsInRange = true
                currentMessage = "Play MiniGame 3" // Set message here
            }
        }
        
        // Check if any item is near for UI prompt only
        if let player = self.childNode(withName: "userBird") {
            var foundNearbyItem = false
            for node in children where node.name == "stick" && viewModel?.isFlying == false || node.name == "leaf" && viewModel?.isFlying == false {
                let dx = player.position.x - node.position.x
                let dy = player.position.y - node.position.y
                let distance = sqrt(dx*dx + dy*dy)
                if distance < 200 {
                    foundNearbyItem = true
                    break
                }
            }
            if foundNearbyItem {
                currentMessage = "PickUp Item"
            }
        }
        
        interactionLabel.text = currentMessage
        
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
        
        if let player = self.childNode(withName: "userBird") {
            updateCameraFollow(target: player.position, deltaTime: deltaTime)
            clampCameraToMap()
        }
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
        
        // Smoothly rotate the bird to face movement direction
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        if speed > 0.001 {
            // Angle from velocity vector
            let target = atan2(velocity.dy, velocity.dx)
            // If your sprite artwork faces up instead of right, add an offset:
            let assetOrientationOffset: CGFloat = -(.pi / 2) // change to 0 if asset faces right
            let desired = target + assetOrientationOffset

            // Shortest-angle interpolation
            let current = player.zRotation
            let deltaAngle = atan2(sin(desired - current), cos(desired - current))

            // Turn rate in radians per second; higher is snappier
            let turnRate: CGFloat = 10.0
            let step = min(1.0, turnRate * deltaTime)

            player.zRotation = current + deltaAngle * step
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
        
        // handles tapped areas for minigames
        // find all nodes in the location
        let touchedNodes = nodes(at: location)
        
        // check is any of the touched nodes is in our minigame spot
        for node in touchedNodes {
            if node.name == predator {
                print("predator tapped")
                transitionToPredatorGame()
                viewModel?.controlsAreVisable = false
                return
            } else if node.name == miniGame1, miniGame1IsInRange == true {
                print("minigame 1 tapped")
                transitionToMinigame1()
                viewModel?.controlsAreVisable = false
            } else if node.name == miniGame2, miniGame2IsInRange == true {
                print("minigame 2 tapped")
                transitionToMinigame2()
                viewModel?.controlsAreVisable = false
            } else if node.name == miniGame3, miniGame3IsInRange == true {
                print("minigame 3 tapped")
                transitionToMinigame3()
                viewModel?.controlsAreVisable = false
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
    
    func spawnItem(at position: CGPoint, type: String) {
        let item = SKSpriteNode(imageNamed: type)
        item.position = position
        item.name = type
        item.setScale(0.5)
        
        self.addChild(item)
    }
    
    func pickupItem(_ node: SKNode) {
        guard let name = node.name else { return }
        
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
        player.position = CGPoint(x: 200, y: 400)
        player.zPosition = 10
        player.name = "userBird"
        
        self.addChild(player)
    }
    
  
    func setupPredator() {
        if self.childNode(withName: predator) != nil { return }
        
        let spot = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        spot.position = CGPoint(x: frame.midX, y: frame.midY)
        spot.name = predator
        
        let moveRight = SKAction.moveBy(x: 1000, y: 0, duration: 3)
        let moveLeft = moveRight.reversed()
        let sequence = SKAction.sequence([moveRight, moveLeft])
        let repeatForever = SKAction.repeatForever(sequence)
        spot.run(repeatForever)
        addChild(spot)
        
    }
    
    func startPredatorTimer() {
        self.removeAction(forKey: "predatorCooldown")
        
        let wait = SKAction.wait(forDuration: 5.0) //adjust timer here for predator cooldown
        let reset = SKAction.run {
            self.predatorHit = false
        }
        
        let sequence = SKAction.sequence([
            wait,reset
        ])
        self.run(sequence, withKey: "predatorCooldown")
    
    }
    
    func setupMiniGame1Spot() {
        if self.childNode(withName: miniGame1) != nil { return }
        let spot = SKSpriteNode(color: .blue, size: CGSize(width: 50, height: 50))
        spot.position = CGPoint(x: frame.minX, y: frame.minY)
        spot.name = miniGame1
        addChild(spot)
    }
    func setupMiniGame2Spot() {
        if self.childNode(withName: miniGame2) != nil { return }
        let spot = SKSpriteNode(color: .green, size: CGSize(width: 50, height: 50))
        spot.position = CGPoint(x: frame.minX, y: frame.maxY)
        spot.name = miniGame2
        addChild(spot)
    }
    func setupMiniGame3Spot() {
        if self.childNode(withName: miniGame3) != nil { return }
        let spot = SKSpriteNode(color: .yellow, size: CGSize(width: 50, height: 50))
        spot.position = CGPoint(x: frame.maxX, y: frame.minY)
        spot.name = miniGame3
        addChild(spot)
    }
    
    
    
    func transitionToPredatorGame() {
        guard let view = self.view else { return }
        saveReturnState()
        let minigameScene = PredatorGame(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.mainViewModel = self.viewModel
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(minigameScene, transition: transition)
    }
    
    func transitionToMinigame1() {
        guard let view = self.view else { return }
        saveReturnState()
        let minigameScene = MiniGameScene1(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.mainViewModel = self.viewModel
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(minigameScene, transition: transition)
    }
    
    func transitionToMinigame2() {
        guard let view = self.view else { return }
        saveReturnState()
        let minigameScene = MiniGameScene2(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.mainViewModel = self.viewModel
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(minigameScene, transition: transition)
    }
    
    func transitionToMinigame3() {
        guard let view = self.view else { return }
        saveReturnState()
        let minigameScene = MiniGameScene3(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.mainViewModel = self.viewModel
        
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
}

