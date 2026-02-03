//
//  LeaveIslandScene.swift
//  BirdSim
//
//  Created by Jaiden Henley on 1/29/26.
//

import SpriteKit

class LeaveIslandScene: SKScene, SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        gameOver()
    }
    
    func gameWin() {
        viewModel?.showGameWin = true
    }
    
    func gameOver() {
        // Trigger the SwiftUI GameOverView
        viewModel?.showGameOver = true
        // Optional: stop physics so everything freezes
        self.isPaused = true
    }

    var viewModel: MainGameView.ViewModel?
    
    var bird = SKSpriteNode(color: .yellow, size: CGSize(width: 40, height: 40))
    
    override func didMove(to view: SKView) {
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -5.0)
        self.physicsWorld.contactDelegate = self
        
        setupBird()
        setupObstacles()
        startCountdown()
    }
    
    func setupBird() {
        bird.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        bird.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.categoryBitMask = 1
        bird.physicsBody?.contactTestBitMask = 1
        bird.physicsBody?.collisionBitMask = 2
        bird.name = "playerBird"
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
        let gapHeight: CGFloat = 200.0
            let pipeWidth: CGFloat = 60.0
            let pipeOffset = CGFloat.random(in: -150...150)
            
            // Bottom Pipe
            let bottomPipe = SKSpriteNode(color: .green, size: CGSize(width: pipeWidth, height: 600))
            bottomPipe.position = CGPoint(x: self.frame.maxX + 50, y: self.frame.midY - 300 - (gapHeight / 2) + pipeOffset)
            setupObstaclePhysics(bottomPipe)
            
            // Top Pipe
            let topPipe = SKSpriteNode(color: .green, size: CGSize(width: pipeWidth, height: 600))
            topPipe.position = CGPoint(x: self.frame.maxX + 50, y: self.frame.midY + 300 + (gapHeight / 2) + pipeOffset)
            setupObstaclePhysics(topPipe)
            
            let moveLeft = SKAction.moveBy(x: -self.frame.width - 150, y: 0, duration: 4.0)
            let sequence = SKAction.sequence([moveLeft, .removeFromParent()])
            
            bottomPipe.run(sequence)
            topPipe.run(sequence)
            
            addChild(bottomPipe)
            addChild(topPipe)
    }
    
    func setupObstaclePhysics(_ obstacle: SKSpriteNode) {
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
        obstacle.physicsBody?.isDynamic = false
        obstacle.physicsBody?.categoryBitMask = 2
        obstacle.physicsBody?.contactTestBitMask = 1
        obstacle.physicsBody?.collisionBitMask = 1
    }
    
    func startCountdown() {
        let wait = SKAction.wait(forDuration: 5.0)
        let action = SKAction.run {
            self.userHasWon()
        }
        let sequence = SKAction.sequence([wait, action])
        self.run(sequence)
    }
    
    func userHasWon() {
        addPoints()
        gameWin()
    }
    
    func addPoints() {
        viewModel?.userScore += 5 // change score amount for build nest minigame here
        print("added 1 to score")
    }
    
    

    override func update(_ currentTime: TimeInterval) {
        // If bird falls below bottom of screen → game over
        if bird.position.y < frame.minY {
            gameOver()
        }

        // (Optional) If bird goes too high → also game over
        if bird.position.y > frame.maxY {
            gameOver()
        }
    }
}
