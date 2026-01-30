//
//  LeaveIslandScene.swift
//  BirdSim
//
//  Created by Jaiden Henley on 1/29/26.
//

import SpriteKit

class LeaveIslandScene: SKScene, SKPhysicsContactDelegate {
    var viewModel: MainGameView.ViewModel?
    
    var bird = SKSpriteNode(color: .yellow, size: CGSize(width: 40, height: 40))
    
    override func didMove(to view: SKView) {
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -5.0)
        self.physicsWorld.contactDelegate = self
        
        setupBird()
        setupObstacles()
//        backgroundColor = .systemCyan
//        
//        let backLabel = SKLabelNode(text: "Mini Game active tap to go back")
//        backLabel.position = CGPoint(x: frame.midX, y: frame.midY)
//        backLabel.fontColor = .white
//        backLabel.fontSize = 28
//        backLabel.name = "Back Button"
//        backLabel.zPosition = 10
//        addChild(backLabel)

    }
    
    func setupBird() {
        bird.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        bird.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.contactTestBitMask = 1
        addChild(bird)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 25))
    }
    
    func setupObstacles() {
        let spawn = SKAction.run { self.createObstaclePair() }
        let delay = SKAction.wait(forDuration: 2.0)
        run(SKAction.repeatForever(SKAction.sequence([spawn, delay])))
    }
    
    func createObstaclePair() {
        let pipe = SKSpriteNode(color: .green, size: CGSize(width: 50, height: 400))
                pipe.position = CGPoint(x: self.frame.maxX + 50, y: self.frame.midY - 250)
                pipe.physicsBody = SKPhysicsBody(rectangleOf: pipe.size)
                pipe.physicsBody?.isDynamic = false // Static so bird bounces off
                
                let moveLeft = SKAction.moveBy(x: -self.frame.width - 100, y: 0, duration: 4.0)
                pipe.run(SKAction.sequence([moveLeft, .removeFromParent()]))
                addChild(pipe)
    }

}
