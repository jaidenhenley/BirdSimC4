//
//  LeaveIslandScene.swift
//  BirdSim
//
//  Created by Jaiden Henley on 1/29/26.
//

import SpriteKit

class LeaveIslandScene: SKScene, SKPhysicsContactDelegate {
    var viewModel: MainGameView.ViewModel?
    var bird = SKSpriteNode(imageNamed: "User_BirdFlappy")
    private var isGameOver = false
    
    // --- Responsive Constants ---
    // We base units on screen height to keep vertical gameplay consistent across devices
    private var unit: CGFloat { return size.height }
    private var playableWidth: CGFloat { return size.width }
    
    // Collision Categories
    private let birdCategory: UInt32 = 0x1 << 0
    private let pipeCategory: UInt32 = 0x1 << 1

    override func didMove(to view: SKView) {
        // .aspectFit ensures the entire game scene is visible on iPad without cropping
        self.scaleMode = .aspectFit
        
        SoundManager.shared.startBackgroundMusic(track: .leaveMap)
        HapticManager.shared.prepare()

        // Physics: Gravity is now relative to height for consistent fall speed
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -unit * 0.01)
        self.physicsWorld.contactDelegate = self
        
        setupBird()
        setupObstacles()
        startCountdown()
    }
    
    func setupBird() {
        let birdSize = unit * 0.08 // Smaller multiplier since unit is now height
        bird.position = CGPoint(x: size.width * 0.25, y: size.height * 0.5)
        bird.size = CGSize(width: birdSize, height: birdSize)
        
        // Physics body
        bird.physicsBody = SKPhysicsBody(circleOfRadius: birdSize * 0.4)
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.contactTestBitMask = pipeCategory
        bird.physicsBody?.collisionBitMask = pipeCategory
        bird.physicsBody?.mass = 0.1
        bird.name = "playerBird"
        addChild(bird)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        
        HapticManager.shared.trigger(.selection)
        
        // Velocity reset for snappy controls
        bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        // Impulse scaled to height so the "jump" height is the same % of screen
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: unit * 0.045))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        gameOver()
    }
    
    func gameOver() {
        guard !isGameOver else { return }
        isGameOver = true
        
        HapticManager.shared.trigger(.error)
        viewModel?.showGameOver = true
        self.isPaused = true
    }

    func userHasWon() {
        guard !isGameOver else { return }
        HapticManager.shared.trigger(.success)
        addPoints()
        viewModel?.showGameWin = true
    }
    
    // MARK: - Layout & Obstacles
    
    func setupObstacles() {
        let spawn = SKAction.run { [weak self] in self?.createObstaclePair() }
        let delay = SKAction.wait(forDuration: 1.5)
        run(SKAction.repeatForever(SKAction.sequence([spawn, delay])), withKey: "pipeSpawn")
    }
    
    func createObstaclePair() {
        let gapHeight = unit * 0.3 // Gap is 30% of screen height
        let pipeWidth = unit * 0.12
        let pipeHeight = unit // Pipe is at least as tall as the screen
        
        // Random offset: Keep the gap within the middle 60% of the screen
        let playableRange = unit * 0.6
        let randomCenterY = CGFloat.random(in: (unit * 0.2)...(unit * 0.8))
            
        // Bottom Pipe
        let bottomPipe = SKSpriteNode(color: .green, size: CGSize(width: pipeWidth, height: pipeHeight))
        bottomPipe.position = CGPoint(x: size.width + pipeWidth,
                                      y: randomCenterY - (gapHeight / 2) - (pipeHeight / 2))
        setupObstaclePhysics(bottomPipe)
            
        // Top Pipe
        let topPipe = SKSpriteNode(color: .green, size: CGSize(width: pipeWidth, height: pipeHeight))
        topPipe.position = CGPoint(x: size.width + pipeWidth,
                                   y: randomCenterY + (gapHeight / 2) + (pipeHeight / 2))
        setupObstaclePhysics(topPipe)
            
        // Movement: Speed is distance/time. Using a duration relative to width
        // keeps the speed consistent even on wider iPad screens.
        let distanceToMove = size.width + (pipeWidth * 3)
        let moveLeft = SKAction.moveBy(x: -distanceToMove, y: 0, duration: 3.0)
        let sequence = SKAction.sequence([moveLeft, .removeFromParent()])
            
        bottomPipe.run(sequence)
        topPipe.run(sequence)
            
        addChild(bottomPipe)
        addChild(topPipe)
    }
    
    func setupObstaclePhysics(_ obstacle: SKSpriteNode) {
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
        obstacle.physicsBody?.isDynamic = false
        obstacle.physicsBody?.categoryBitMask = pipeCategory
        obstacle.physicsBody?.contactTestBitMask = birdCategory
    }
    
    func startCountdown() {
        let wait = SKAction.wait(forDuration: 15.0)
        let action = SKAction.run { [weak self] in self?.userHasWon() }
        self.run(SKAction.sequence([wait, action]))
    }
    
    func addPoints() {
        viewModel?.userScore += 5
    }

    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }
        
        // Screen bounds check
        if bird.position.y < 0 || bird.position.y > size.height {
            gameOver()
        }
        
        // Tilt Logic
        let velocity = bird.physicsBody?.velocity.dy ?? 0
        let targetRotation = velocity * (velocity < 0 ? 0.002 : 0.001)
        bird.zRotation = min(max(-1, targetRotation), 0.5)
    }
}
