//
//  MiniGameScene3 2.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/26/26.
//




import SpriteKit

class FeedBabyScene: SKScene, SKPhysicsContactDelegate {
    var viewModel: MainGameView.ViewModel?
    var isSceneTransitioning = false
    
    // --- Win/Loss Tracking ---
    var caughtCount = 0
    var missedCount = 0
    let totalRopes = 3
    let requiredToWin = 2
    
    var scoreLabel: SKLabelNode!
    
    let ropeCategory: UInt32 = 0x1 << 0
    let itemCategory: UInt32 = 0x1 << 1
    let bucketCategory: UInt32 = 0x1 << 2
    
    override func didMove(to view: SKView) {
        SoundManager.shared.startBackgroundMusic(track: .feedingBaby)
        backgroundColor = .black
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        // --- Setup UI ---
        setupScoreLabel()
        setupBackButton()
        
        // --- Setup Ropes ---
        let padding: CGFloat = 80
        createRope(at: frame.minX + padding)
        createRope(at: frame.midX)
        createRope(at: frame.maxX - padding)
        
        setupUContainer()
    }
    
    func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 24
        scoreLabel.text = "Caught: 0/\(requiredToWin)"
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 50)
        scoreLabel.fontColor = .white
        addChild(scoreLabel)
    }
    
    func createRope(at xPos: CGFloat) {
        let anchor = SKSpriteNode(color: .red, size: CGSize(width: 20, height: 10))
        anchor.position = CGPoint(x: xPos, y: frame.maxY - 120)
        anchor.physicsBody = SKPhysicsBody(rectangleOf: anchor.size)
        anchor.physicsBody?.isDynamic = false
        addChild(anchor)
        
        var lastNode: SKNode = anchor
        
        for i in 0..<12 {
            let link = SKSpriteNode(color: .white, size: CGSize(width: 2, height: 20))
            link.position = CGPoint(x: anchor.position.x, y: anchor.position.y - CGFloat(i * 20) - 10)
            link.name = "rope_link"
            link.physicsBody = SKPhysicsBody(rectangleOf: link.size)
            link.physicsBody?.linearDamping = 0.5
            link.physicsBody?.angularDamping = 0.5
            link.physicsBody?.categoryBitMask = ropeCategory
            link.physicsBody?.collisionBitMask = 0
            addChild(link)
            
            let joint = SKPhysicsJointPin.joint(withBodyA: lastNode.physicsBody!,
                                                bodyB: link.physicsBody!,
                                                anchor: CGPoint(x: link.position.x, y: link.position.y + 10))
            physicsWorld.add(joint)
            lastNode = link
        }
        
        let itemNode = SKSpriteNode(color: .orange, size: CGSize(width: 30, height: 30))
        itemNode.position = CGPoint(x: lastNode.position.x, y: lastNode.position.y - 20)
        itemNode.name = "food_item"
        
        itemNode.physicsBody = SKPhysicsBody(rectangleOf: itemNode.size)
        itemNode.physicsBody?.categoryBitMask = itemCategory
        itemNode.physicsBody?.contactTestBitMask = bucketCategory
        itemNode.physicsBody?.collisionBitMask = bucketCategory
        itemNode.physicsBody?.restitution = 0.2
        addChild(itemNode)
        
        let lastJoint = SKPhysicsJointPin.joint(withBodyA: lastNode.physicsBody!,
                                                bodyB: itemNode.physicsBody!,
                                                anchor: CGPoint(x: itemNode.position.x, y: itemNode.position.y + 15))
        physicsWorld.add(lastJoint)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard !isSceneTransitioning else { return }
        
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if contactMask == (itemCategory | bucketCategory) {
            let itemNode = (contact.bodyA.categoryBitMask == itemCategory) ? contact.bodyA.node : contact.bodyB.node
            
            if itemNode?.parent != nil {
                itemNode?.removeFromParent()
                caughtCount += 1
                scoreLabel.text = "Caught: \(caughtCount)/\(requiredToWin)"
                
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                checkWinCondition()
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard !isSceneTransitioning else { return }
        
        enumerateChildNodes(withName: "food_item") { node, _ in
            if node.position.y < 0 {
                node.removeFromParent()
                self.missedCount += 1
                self.checkWinCondition()
            }
        }
    }
    
    func checkWinCondition() {
        if caughtCount >= requiredToWin {
            handleGameOver(success: true)
        } else if missedCount > (totalRopes - requiredToWin) {
            // If you miss more than 1 (in a 3-rope game), you can't get 2.
            handleGameOver(success: false)
        }
    }
    
    func handleGameOver(success: Bool) {
        isSceneTransitioning = true
        physicsWorld.contactDelegate = nil
        
        if success {
            viewModel?.incrementFeedingForCurrentNest()
        }
        
        let endLabel = SKLabelNode(text: success ? "SUCCESS!" : "TRY AGAIN!")
        endLabel.fontName = "AvenirNext-Bold"
        endLabel.fontSize = 40
        endLabel.fontColor = success ? .green : .red
        endLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        endLabel.zPosition = 100
        addChild(endLabel)
        
        let wait = SKAction.wait(forDuration: 1.5)
        let transitionAction = SKAction.run { [weak self] in
            self?.returnToMainGame()
        }
        
        self.run(SKAction.sequence([wait, transitionAction]))
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
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        for node in touchedNodes where node.name == "rope_link" {
            node.removeFromParent()
        }
    }
    
    func setupBackButton() {
        let backLabel = SKLabelNode(text: "Tap to go back")
        backLabel.position = CGPoint(x: frame.midX, y: 50)
        backLabel.name = "Back Button"
        addChild(backLabel)
    }
}
