//
//  GameScene.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/20/26.
//

import SpriteKit
import GameController

class GameScene: SKScene {
    
    let interactionLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    private var hasInitializedWorld = false
    
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
    
    
    weak var viewModel: MainGameViewModel?
    
    var lastUpdateTime: TimeInterval = 0
    var virtualController: GCVirtualController?
    let cameraNode = SKCameraNode()
    var circleSpeed: CGFloat = 400.0
    
    override func didMove(to view: SKView) {
        
        if !hasInitializedWorld {
            setupBackground()
            setupTestCircle()
            setupPredator()
            setupMiniGame1Spot()
            setupMiniGame2Spot()
            setupMiniGame3Spot()
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
        
        
        //1. Get the player and the target node(Predator Attack Radius)
        if let player = self.childNode(withName: "movingCircle"),
           let portal = self.childNode(withName: predator){
            //2. Calculate the distance between them using the Pythagorean theorem
            let dx = player.position.x - portal.position.x
            let dy = player.position.y - portal.position.y
            let distance = sqrt(dx*dx + dy*dy)
            
            //3. If distance is less then 200 pixels, trigger the game
            
            if distance < 200, predatorHit == false {
                transitionToPredatorGame()
                predatorHit = true
                viewModel?.controlsAreVisable = false
            }
        }
        if let player = self.childNode(withName: "movingCircle"),
           let portal = self.childNode(withName: miniGame1){
            //2. Calculate the distance between them using the Pythagorean theorem
            let dx = player.position.x - portal.position.x
            let dy = player.position.y - portal.position.y
            let distance = sqrt(dx*dx + dy*dy)
            
            //3. If distance is less then 200 pixels, trigger the game
            
            if distance < 200 {
                miniGame1IsInRange = true
                currentMessage = "Play MiniGame 1" // Set message here
            }
        }
        
        if let player = self.childNode(withName: "movingCircle"),
           let portal = self.childNode(withName: miniGame2){
            //2. Calculate the distance between them using the Pythagorean theorem
            let dx = player.position.x - portal.position.x
            let dy = player.position.y - portal.position.y
            let distance = sqrt(dx*dx + dy*dy)
            
            //3. If distance is less then 200 pixels, trigger the game
            
            if distance < 200 {
                miniGame2IsInRange = true
                currentMessage = "Play MiniGame 2" // Set message here
            }
        }
        
        if let player = self.childNode(withName: "movingCircle"),
           let portal = self.childNode(withName: miniGame3){
            //2. Calculate the distance between them using the Pythagorean theorem
            let dx = player.position.x - portal.position.x
            let dy = player.position.y - portal.position.y
            let distance = sqrt(dx*dx + dy*dy)
            
            //3. If distance is less then 200 pixels, trigger the game
            
            if distance < 200 {
                miniGame3IsInRange = true
                currentMessage = "Play MiniGame 3" // Set message here
            }
        }
        interactionLabel.text = currentMessage
        
        
        // Compute delta time and clamp to avoid large spikes causing visible jumps
        let rawDelta: CGFloat
        if lastUpdateTime == 0 {
            rawDelta = 1.0 / 60.0 // assume one frame on first update
        } else {
            rawDelta = CGFloat(currentTime - lastUpdateTime)
        }
        lastUpdateTime = currentTime
        
        // Clamp delta between ~8ms (120fps) and ~33ms (30fps)
        let deltaTime = min(max(rawDelta, 1.0/120.0), 1.0/30.0)
        
        if let delta = viewModel?.pendingScaleDelta, delta != 0 {
            adjustCircleScale(by: delta)
            viewModel?.pendingScaleDelta = 0
        }
        
        updatePlayerPosition(deltaTime: deltaTime)
        
        if let circle = self.childNode(withName: "movingCircle") {
            updateCameraFollow(target: circle.position, deltaTime: deltaTime)
            clampCameraToMap()
        }
    }
    
    func updatePlayerPosition(deltaTime: CGFloat) {
        guard let circle = self.childNode(withName: "movingCircle") else { return }
        
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
        
        let velocity = CGVector(dx: dx * circleSpeed, dy: dy * circleSpeed)
        circle.position.x += velocity.dx * deltaTime
        circle.position.y += velocity.dy * deltaTime
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        // get location of touch in scene
        let location = touch.location(in: self)
        
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
        if let circle = self.childNode(withName: "movingCircle") {
            viewModel?.savedPlayerPosition = circle.position
        }
        viewModel?.savedCameraPosition = cameraNode.position
    }
    func restoreReturnStateIfNeeded() {
        if let pos = viewModel?.savedPlayerPosition,
           let circle = self.childNode(withName: "movingCircle") {
            circle.position = pos
        }
        if let camPos = viewModel?.savedCameraPosition {
            cameraNode.position = camPos
        } else if let circle = self.childNode(withName: "movingCircle") {
            cameraNode.position = circle.position
        }
    }
    
    func setupTestCircle() {
        if self.childNode(withName: "movingCircle") != nil { return }
        let radius: CGFloat = 30
        let circle = SKShapeNode(circleOfRadius: radius)
        circle.fillColor = .red
        circle.strokeColor = .blue
        circle.lineWidth = 2
        circle.position = CGPoint(x: 200, y: 300)
        circle.name = "movingCircle"
        circle.zPosition = 10
        
        self.addChild(circle)
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
        guard let circle = self.childNode(withName: "movingCircle") as? SKShapeNode else { return }
        
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

