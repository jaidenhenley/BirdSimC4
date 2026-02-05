//
//  MiniGameScene3 2.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/26/26.
//




import SpriteKit

class FeedBabyScene: SKScene, SKPhysicsContactDelegate {
    var viewModel: MainGameView.ViewModel?
    var item: SKSpriteNode?
    var isSceneTransitioning = false
    
    let ropeCategory: UInt32 = 0x1 << 0
    let itemCategory: UInt32 = 0x1 << 1
    let bucketCategory: UInt32 = 0x1 << 2
    
    override func didMove(to view: SKView) {
        SoundManager.shared.startBackgroundMusic(track: .feedingBaby)
        backgroundColor = .black
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        setupRopeAndItem()
        setupUContainer()
        setupBackButton()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard !isSceneTransitioning else { return }
        let otherBody = (contact.bodyA.categoryBitMask == itemCategory) ? contact.bodyB : contact.bodyA
        if otherBody.categoryBitMask == bucketCategory {
            handleGameOver(success: true)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let item = item, !isSceneTransitioning else { return }
        if item.position.y < 0 {
            handleGameOver(success: false)
        }
    }
    
    func handleGameOver(success: Bool) {
        isSceneTransitioning = true
        physicsWorld.contactDelegate = nil
        
        if success {
            // This is the "Magic Button" that resets the timer for the active nest
            viewModel?.incrementFeedingForCurrentNest()
        }
        
        let endLabel = SKLabelNode(text: success ? "SUCCESS!" : "TRY AGAIN!")
        endLabel.fontName = "AvenirNext-Bold"
        endLabel.fontSize = 40
        endLabel.fontColor = success ? .green : .red
        endLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        endLabel.zPosition = 100
        addChild(endLabel)
        
        let wait = SKAction.wait(forDuration: 1.0)
        let transitionAction = SKAction.run { [weak self] in
            self?.returnToMainGame()
        }
        
        self.run(SKAction.sequence([wait, transitionAction]))
    }

    // --- THIS WAS MISSING OR OUTSIDE THE BRACKETS ---
    func returnToMainGame() {
        guard let view = self.view else { return }
        
        if let existing = viewModel?.mainScene {
            viewModel?.joystickVelocity = .zero
            viewModel?.controlsAreVisable = true
            
            let transition = SKTransition.crossFade(withDuration: 0.5)
            view.presentScene(existing, transition: transition)
        }
    }

    func setupUContainer() {
        let bucketWidth: CGFloat = 100
        let bucketHeight: CGFloat = 60
        let thickness: CGFloat = 5
        let container = SKNode()
        container.position = CGPoint(x: frame.midX, y: 150)
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
    }

    func setupRopeAndItem() {
        let anchor = SKSpriteNode(color: .red, size: CGSize(width: 10, height: 10))
        anchor.position = CGPoint(x: frame.midX, y: frame.maxY - 100)
        anchor.physicsBody = SKPhysicsBody(rectangleOf: anchor.size)
        anchor.physicsBody?.isDynamic = false
        addChild(anchor)
        
        var lastNode: SKNode = anchor
        for i in 0..<12 {
            let link = SKSpriteNode(color: .white, size: CGSize(width: 2, height: 20))
            link.position = CGPoint(x: anchor.position.x, y: anchor.position.y - CGFloat(i * 20) - 10)
            link.name = "rope_link"
            link.physicsBody = SKPhysicsBody(rectangleOf: link.size)
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
        itemNode.physicsBody = SKPhysicsBody(circleOfRadius: 15)
        itemNode.physicsBody?.categoryBitMask = itemCategory
        itemNode.physicsBody?.contactTestBitMask = bucketCategory
        itemNode.physicsBody?.restitution = 0.2
        self.item = itemNode
        addChild(itemNode)
        
        let lastJoint = SKPhysicsJointPin.joint(withBodyA: lastNode.physicsBody!,
                                               bodyB: itemNode.physicsBody!,
                                               anchor: CGPoint(x: itemNode.position.x, y: itemNode.position.y + 15))
        physicsWorld.add(lastJoint)
        itemNode.physicsBody?.applyImpulse(CGVector(dx: 30, dy: 0))
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
