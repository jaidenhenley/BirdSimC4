//
//  MiniGameScene3.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/26/26.
//

import SpriteKit
import CoreMotion

class FeedUserScene: SKScene, SKPhysicsContactDelegate {
    var viewModel: MainGameView.ViewModel?
    
    // --- Accelerometer Properties ---
    private let motionManager = CMMotionManager()
    private var tiltValue: CGFloat = 0.0
    
    // --- Meter Properties ---
    private let meterBackground = SKShapeNode(rectOf: CGSize(width: 200, height: 20), cornerRadius: 5)
    private let meterFill = SKShapeNode(rectOf: CGSize(width: 0, height: 20), cornerRadius: 5)
    private var fullness: CGFloat = 0.0 {
        didSet {
            updateMeter()
        }
    }
    private let maxFullness: CGFloat = 100.0
    
    // Player node
    let player = SKShapeNode(rectOf: CGSize(width: 80, height: 40), cornerRadius: 10)
    
    // Physics Categories
    let playerCategory: UInt32 = 0x1 << 0
    let goodItemCategory: UInt32 = 0x1 << 1
    let badItemCategory: UInt32 = 0x1 << 2

    override func didMove(to view: SKView) {
        SoundManager.shared.startBackgroundMusic(track: .feedingUser)
        backgroundColor = .darkGray
        
        // 1. Setup Physics World
        physicsWorld.gravity = CGVector(dx: 0, dy: -2.0)
        physicsWorld.contactDelegate = self
        
        // 2. Setup Player
        player.fillColor = .cyan
        player.position = CGPoint(x: frame.midX, y: 100)
        player.name = "player"
        player.physicsBody = SKPhysicsBody(rectangleOf: player.frame.size)
        player.physicsBody?.isDynamic = false
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.contactTestBitMask = goodItemCategory | badItemCategory
        addChild(player)
        
        // 3. UI Setup
        setupMeter()
        setupBackButton()
        
        // 4. Start Accelerometer for Landscape
        setupAccelerometer()
        
        // 5. Start Spawning Shapes
        let spawnAction = SKAction.run { [weak self] in self?.spawnFallingShape() }
        let waitAction = SKAction.wait(forDuration: 0.8)
        run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])), withKey: "spawning")
    }
    
    // MARK: - Core Motion Setup
    private func setupAccelerometer() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.02
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
                guard let acceleration = data?.acceleration else { return }
                
                // LANDSCAPE LOGIC:
                // Tilting the phone left/right in landscape affects the 'y' property.
                // We use a simple low-pass filter to smooth the movement.
                let filterFactor: Double = 0.2
                let rawTilt = acceleration.y
                self?.tiltValue = CGFloat((rawTilt * filterFactor) + (Double(self?.tiltValue ?? 0) * (1.0 - filterFactor)))
            }
        }
    }

    // MARK: - Game Loop
    override func update(_ currentTime: TimeInterval) {
        // Sensitivity for landscape movement
        // We multiply by -1.0 because tilting left returns a positive Y in landscape
        let sensitivity: CGFloat = 80.0
        let moveAmount = tiltValue * sensitivity * -1.0
        
        let newX = player.position.x + moveAmount
        
        // Keep player within screen bounds
        let halfWidth = player.frame.width / 2
        player.position.x = max(halfWidth, min(frame.width - halfWidth, newX))
        
        // Visual Juice: Make the player tilt slightly in the direction of movement
        player.zRotation = tiltValue * 0.4
    }
    
    private func setupMeter() {
        meterBackground.position = CGPoint(x: frame.midX, y: frame.height - 50)
        meterBackground.fillColor = .black
        meterBackground.strokeColor = .white
        meterBackground.lineWidth = 2
        meterBackground.zPosition = 100
        addChild(meterBackground)

        meterFill.fillColor = .green
        meterFill.strokeColor = .clear
        meterFill.position = CGPoint(x: frame.midX - 100, y: frame.height - 50)
        meterFill.zPosition = 101
        meterFill.path = CGPath(rect: CGRect(x: 0, y: -10, width: 0.1, height: 20), transform: nil)
        addChild(meterFill)

        let label = SKLabelNode(text: "FULLNESS")
        label.fontSize = 14
        label.fontName = "AvenirNext-Bold"
        label.position = CGPoint(x: frame.midX, y: frame.height - 35)
        label.zPosition = 102
        addChild(label)
    }

    private func updateMeter() {
        let percentage = min(max(fullness / maxFullness, 0), 1.0)
        let newWidth = 200 * percentage
        meterFill.path = CGPath(roundedRect: CGRect(x: 0, y: -10, width: newWidth, height: 20),
                                cornerWidth: 5, cornerHeight: 5, transform: nil)
        
        if fullness >= maxFullness {
            handleWin()
        }
    }

    func spawnFallingShape() {
        let shapeType = Int.random(in: 0...2)
        let isGood = shapeType != 2
        let size = CGSize(width: 40, height: 40)
        let shapeNode: SKShapeNode
        
        switch shapeType {
        case 0: shapeNode = SKShapeNode(rectOf: size, cornerRadius: 4)
        case 1: shapeNode = SKShapeNode(circleOfRadius: 20)
        default:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 20, y: -20))
            path.addLine(to: CGPoint(x: -20, y: -20))
            path.closeSubpath()
            shapeNode = SKShapeNode(path: path)
        }
        
        shapeNode.fillColor = isGood ? .green : .red
        shapeNode.strokeColor = .white
        let randomX = CGFloat.random(in: 50...(frame.width - 50))
        shapeNode.position = CGPoint(x: randomX, y: frame.height + 50)
        
        shapeNode.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        shapeNode.physicsBody?.categoryBitMask = isGood ? goodItemCategory : badItemCategory
        shapeNode.physicsBody?.contactTestBitMask = playerCategory
        
        shapeNode.name = isGood ? "good" : "bad"
        addChild(shapeNode)
        
        let wait = SKAction.wait(forDuration: 5.0)
        let remove = SKAction.removeFromParent()
        shapeNode.run(SKAction.sequence([wait, remove]))
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let itemNode = (contact.bodyA.categoryBitMask == playerCategory) ? contact.bodyB.node : contact.bodyA.node
        
        if contactMask == (playerCategory | goodItemCategory) {
            fullness += 10.0
            itemNode?.removeFromParent()
            player.run(SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
        } else if contactMask == (playerCategory | badItemCategory) {
            fullness = max(0, fullness - 15.0)
            itemNode?.removeFromParent()
            let shake = SKAction.sequence([
                SKAction.moveBy(x: 10, y: 0, duration: 0.05),
                SKAction.moveBy(x: -20, y: 0, duration: 0.05),
                SKAction.moveBy(x: 10, y: 0, duration: 0.05)
            ])
            player.run(shake)
        }
    }

    private func handleWin() {
        removeAction(forKey: "spawning")
        motionManager.stopAccelerometerUpdates()
        
        viewModel?.health = 1.0
        addPoints()
        
        let winLabel = SKLabelNode(text: "BIRD IS FULL! + HEALTH")
        winLabel.fontSize = 35
        winLabel.fontName = "AvenirNext-Bold"
        winLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        winLabel.fontColor = .green
        winLabel.zPosition = 200
        addChild(winLabel)
        
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in self?.returnToMap() }
        ]))
    }

    func addPoints() {
        viewModel?.userScore += 1
    }
    
    func setupBackButton() {
        let backLabel = SKLabelNode(text: "← Back")
        backLabel.position = CGPoint(x: 60, y: frame.height - 50)
        backLabel.fontSize = 18
        backLabel.name = "Back Button"
        backLabel.zPosition = 100
        addChild(backLabel)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if atPoint(location).name == "Back Button" {
            motionManager.stopAccelerometerUpdates()
            returnToMap()
        }
    }
    
    func returnToMap() {
        guard let view = self.view, let existing = viewModel?.mainScene else { return }
        viewModel?.controlsAreVisable = true
        view.presentScene(existing, transition: SKTransition.crossFade(withDuration: 0.5))
    }
}
