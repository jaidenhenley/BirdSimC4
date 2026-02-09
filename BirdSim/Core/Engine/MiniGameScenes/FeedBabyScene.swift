//
//  MiniGameScene3 2.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/26/26.
//




import SpriteKit
import UIKit

class FeedBabyScene: SKScene, SKPhysicsContactDelegate {
    var viewModel: MainGameView.ViewModel?
    var isSceneTransitioning = false
    
    // --- Win/Loss Tracking ---
    var caughtCount = 0
    var missedCount = 0
    let totalRopes = 3
    let requiredToWin = 2
    
    var scoreLabel: SKLabelNode!
    
    // --- Physics Categories ---
    let ropeCategory: UInt32 = 0x1 << 0
    let itemCategory: UInt32 = 0x1 << 1
    let bucketCategory: UInt32 = 0x1 << 2
    
    // --- Responsive Constants ---
    private var unit: CGFloat {
        return min(size.width, size.height)
    }

    override func didMove(to view: SKView) {
        self.scaleMode = .aspectFill
        
        // Warm up the haptic engine
        HapticManager.shared.prepare()
        
        SoundManager.shared.startBackgroundMusic(track: .feedingBaby)
        backgroundColor = .black
        
        physicsWorld.contactDelegate = self
        // Gravity relative to screen height
        physicsWorld.gravity = CGVector(dx: 0, dy: -unit * 0.02)
        
        setupUI()
        setupGameElements()
    }
    
    private func setupUI() {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = unit * 0.05
        scoreLabel.text = "Caught: 0/\(requiredToWin)"
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - (unit * 0.15))
        scoreLabel.fontColor = .white
        scoreLabel.zPosition = 100
        addChild(scoreLabel)
        
        let backLabel = SKLabelNode(text: "EXIT MINI-GAME")
        backLabel.fontName = "AvenirNext-Bold"
        backLabel.fontSize = unit * 0.04
        backLabel.position = CGPoint(x: size.width / 2, y: unit * 0.08)
        backLabel.name = "Back Button"
        backLabel.zPosition = 100
        addChild(backLabel)
    }
    
    private func setupGameElements() {
        let ropeY = size.height * 0.85
        let spacing = size.width / 4
        
        createRope(at: spacing, yPos: ropeY)
        createRope(at: spacing * 2, yPos: ropeY)
        createRope(at: spacing * 3, yPos: ropeY)
        
        setupBucket()
    }
    
    func createRope(at xPos: CGFloat, yPos: CGFloat) {
        let anchorSize = unit * 0.04
        let anchor = SKSpriteNode(color: .red, size: CGSize(width: anchorSize, height: anchorSize / 2))
        anchor.position = CGPoint(x: xPos, y: yPos)
        anchor.physicsBody = SKPhysicsBody(rectangleOf: anchor.size)
        anchor.physicsBody?.isDynamic = false
        addChild(anchor)
        
        var lastNode: SKNode = anchor
        let linkCount = 12
        let linkWidth = unit * 0.005
        let linkHeight = (size.height * 0.4) / CGFloat(linkCount)
        
        

        for i in 0..<linkCount {
            let link = SKSpriteNode(color: .white, size: CGSize(width: linkWidth, height: linkHeight))
            link.position = CGPoint(x: xPos, y: yPos - (CGFloat(i) * linkHeight) - (linkHeight / 2))
            link.name = "rope_link"
            link.physicsBody = SKPhysicsBody(rectangleOf: link.size)
            link.physicsBody?.categoryBitMask = ropeCategory
            link.physicsBody?.collisionBitMask = 0
            link.physicsBody?.linearDamping = 0.5
            addChild(link)
            
            let joint = SKPhysicsJointPin.joint(withBodyA: lastNode.physicsBody!,
                                               bodyB: link.physicsBody!,
                                               anchor: CGPoint(x: xPos, y: link.position.y + (linkHeight / 2)))
            physicsWorld.add(joint)
            lastNode = link
        }
        
        let foodSize = unit * 0.08
        let itemNode = SKSpriteNode(color: .orange, size: CGSize(width: foodSize, height: foodSize))
        itemNode.position = CGPoint(x: lastNode.position.x, y: lastNode.position.y - (foodSize / 2))
        itemNode.name = "food_item"
        itemNode.physicsBody = SKPhysicsBody(circleOfRadius: foodSize / 2)
        itemNode.physicsBody?.categoryBitMask = itemCategory
        itemNode.physicsBody?.contactTestBitMask = bucketCategory
        itemNode.physicsBody?.collisionBitMask = bucketCategory
        itemNode.physicsBody?.restitution = 0.3
        addChild(itemNode)
        
        let lastJoint = SKPhysicsJointPin.joint(withBodyA: lastNode.physicsBody!,
                                               bodyB: itemNode.physicsBody!,
                                               anchor: CGPoint(x: itemNode.position.x, y: itemNode.position.y + (foodSize / 2)))
        physicsWorld.add(lastJoint)
    }
    
    func setupBucket() {
        let bucketWidth = unit * 0.25
        let bucketHeight = unit * 0.15
        let thickness = unit * 0.015
        
        let container = SKNode()
        container.name = "bucket"
        let leftEdge = bucketWidth
        let rightEdge = size.width - bucketWidth
        container.position = CGPoint(x: leftEdge, y: size.height * 0.2)
        
        let bottom = SKSpriteNode(color: .blue, size: CGSize(width: bucketWidth, height: thickness))
        let leftSide = SKSpriteNode(color: .blue, size: CGSize(width: thickness, height: bucketHeight))
        leftSide.position = CGPoint(x: -bucketWidth/2, y: bucketHeight/2)
        let rightSide = SKSpriteNode(color: .blue, size: CGSize(width: thickness, height: bucketHeight))
        rightSide.position = CGPoint(x: bucketWidth/2, y: bucketHeight/2)
        
        container.addChild(bottom)
        container.addChild(leftSide)
        container.addChild(rightSide)
        
        let bottomBody = SKPhysicsBody(rectangleOf: bottom.size)
        let leftBody = SKPhysicsBody(rectangleOf: leftSide.size, center: leftSide.position)
        let rightBody = SKPhysicsBody(rectangleOf: rightSide.size, center: rightSide.position)
        
        container.physicsBody = SKPhysicsBody(bodies: [bottomBody, leftBody, rightBody])
        container.physicsBody?.isDynamic = false
        container.physicsBody?.categoryBitMask = bucketCategory
        addChild(container)
        
        let duration: TimeInterval = 3.0
        let moveRight = SKAction.moveTo(x: rightEdge, duration: duration)
        let moveLeft = SKAction.moveTo(x: leftEdge, duration: duration)
        moveRight.timingMode = .easeInEaseOut
        
        container.run(SKAction.repeatForever(SKAction.sequence([moveRight, moveLeft])))
    }
    
    // MARK: - Haptic Interactions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        HapticManager.shared.prepare() // Keep engine awake
        
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)
        
        if node.name == "Back Button" {
            HapticManager.shared.trigger(.light)
            returnToMainGame()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        for node in touchedNodes where node.name == "rope_link" {
            node.removeFromParent()
        }

        
        // Define how "easy" it is to cut (in points)
        // 30-40 points is usually the sweet spot for fingers
        let cuttingRadius: CGFloat = unit * 0.05
        
        enumerateChildNodes(withName: "rope_link") { node, _ in
            // Calculate distance between touch and rope link
            let dx = node.position.x - location.x
            let dy = node.position.y - location.y
            let distance = sqrt(dx*dx + dy*dy)
            
            if distance < cuttingRadius {
                HapticManager.shared.trigger(.selection)
                node.removeFromParent()
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard !isSceneTransitioning else { return }
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if contactMask == (itemCategory | bucketCategory) {
            let itemNode = (contact.bodyA.categoryBitMask == itemCategory) ? contact.bodyA.node : contact.bodyB.node
            
            if itemNode?.parent != nil {
                // Trigger 'success' haptic when food is caught
                HapticManager.shared.trigger(.success)
                
                itemNode?.removeFromParent()
                caughtCount += 1
                scoreLabel.text = "Caught: \(caughtCount)/\(requiredToWin)"
                checkWinCondition()
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        enumerateChildNodes(withName: "food_item") { node, _ in
            if node.position.y < -50 {
                node.removeFromParent()
                self.missedCount += 1
                
                // Light 'thud' haptic for a missed item
                HapticManager.shared.trigger(.light)
                
                self.checkWinCondition()
            }
        }
    }
    
    func checkWinCondition() {
        if caughtCount >= requiredToWin {
            handleGameOver(success: true)
        } else if missedCount > (totalRopes - requiredToWin) {
            handleGameOver(success: false)
        }
    }
    
    func handleGameOver(success: Bool) {
        isSceneTransitioning = true
        physicsWorld.contactDelegate = nil
        
        // Final game result haptic
        HapticManager.shared.trigger(success ? .heavy : .error)
        
        if success { viewModel?.incrementFeedingForCurrentNest() }
        
        let endLabel = SKLabelNode(text: success ? "WELL FED!" : "TOO SLOW!")
        endLabel.fontName = "AvenirNext-Bold"
        endLabel.fontSize = unit * 0.1
        endLabel.fontColor = success ? .green : .red
        endLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        endLabel.zPosition = 200
        addChild(endLabel)
        
        self.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in self?.returnToMainGame() }
        ]))
    }

    func returnToMainGame() {
        guard let view = self.view else { return }
        if let existing = viewModel?.mainScene {
            viewModel?.joystickVelocity = .zero
            viewModel?.controlsAreVisable = true
            viewModel?.mapIsVisable = true
            let transition = SKTransition.crossFade(withDuration: 0.5)
            view.presentScene(existing, transition: transition)
        }
    }

    func setupUContainer() {
        let bucketWidth: CGFloat = 100
        let bucketHeight: CGFloat = 60
        let thickness: CGFloat = 5
        let container = SKNode()
        
        let leftEdge = frame.minX + (bucketWidth / 2)
        let rightEdge = frame.maxX - (bucketWidth / 2)
        
        container.position = CGPoint(x: leftEdge, y: 150)
        container.name = "bucket"
        
        let bottom = SKSpriteNode(color: .blue, size: CGSize(width: bucketWidth, height: thickness))
        let leftSide = SKSpriteNode(color: .blue, size: CGSize(width: thickness, height: bucketHeight))
        leftSide.position = CGPoint(x: -bucketWidth/2, y: bucketHeight/2)
        let rightSide = SKSpriteNode(color: .blue, size: CGSize(width: thickness, height: bucketHeight))
        rightSide.position = CGPoint(x: bucketWidth/2, y: bucketHeight/2)
        
        container.addChild(bottom)
        container.addChild(leftSide)
        container.addChild(rightSide)
        
        let bottomBody = SKPhysicsBody(rectangleOf: bottom.size, center: .zero)
        let leftBody = SKPhysicsBody(rectangleOf: leftSide.size, center: leftSide.position)
        let rightBody = SKPhysicsBody(rectangleOf: rightSide.size, center: rightSide.position)
        
        container.physicsBody = SKPhysicsBody(bodies: [bottomBody, leftBody, rightBody])
        container.physicsBody?.isDynamic = false
        container.physicsBody?.categoryBitMask = bucketCategory
        container.physicsBody?.contactTestBitMask = itemCategory
        addChild(container)
        
        let slowDuration: TimeInterval = 4.5
        let moveRight = SKAction.moveTo(x: rightEdge, duration: slowDuration)
        let moveLeft = SKAction.moveTo(x: leftEdge, duration: slowDuration)
        moveRight.timingMode = .easeInEaseOut
        moveLeft.timingMode = .easeInEaseOut

        let sequence = SKAction.sequence([moveRight, moveLeft])
        container.run(SKAction.repeatForever(sequence))
    }
    
    
    func setupBackButton() {
        let backLabel = SKLabelNode(text: "Tap to go back")
        backLabel.position = CGPoint(x: frame.midX, y: 50)
        backLabel.name = "Back Button"
        addChild(backLabel)
    }
}
