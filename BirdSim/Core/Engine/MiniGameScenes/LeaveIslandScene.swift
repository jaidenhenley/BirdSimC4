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
    // Using the smaller dimension (usually width in portrait) as a base unit
    private var unit: CGFloat { return min(size.width, size.height) }
    
    // Collision Categories
    private let birdCategory: UInt32 = 0x1 << 0
    private let pipeCategory: UInt32 = 0x1 << 1

    override func didMove(to view: SKView) {
        // Essential for iPad/iPhone scaling:
        self.scaleMode = .aspectFill
        
        SoundManager.shared.startBackgroundMusic(track: .leaveMap)
        HapticManager.shared.prepare()

        // Scale gravity relative to screen height
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -unit * 0.012)
        self.physicsWorld.contactDelegate = self
        
        setupBird()
        setupObstacles()
        startCountdown()
    }
    
    func setupBird() {
        // Size the bird relative to the screen size
        let birdSize = unit * 0.18
        bird.position = CGPoint(x: size.width * 0.3, y: size.height * 0.5)
        bird.size = CGSize(width: birdSize, height: birdSize)
        
        // Physics body slightly smaller than the sprite for "fairer" collisions
        bird.physicsBody = SKPhysicsBody(circleOfRadius: birdSize * 0.4)
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.contactTestBitMask = pipeCategory
        bird.physicsBody?.collisionBitMask = pipeCategory
        bird.name = "playerBird"
        addChild(bird)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        
        HapticManager.shared.trigger(.selection)
        
        // Impulse scaled to screen size so the jump feels the same on all devices
        bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: unit * 0.08))
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
        let delay = SKAction.wait(forDuration: 1.8) // Slightly faster spawn for modern screens
        run(SKAction.repeatForever(SKAction.sequence([spawn, delay])), withKey: "pipeSpawn")
    }
    
    func createObstaclePair() {
        // Gap is relative: 35% of the screen height
        let gapHeight = size.height * 0.35
        let pipeWidth = unit * 0.15
        let pipeHeight = size.height
        
        // Random offset restricted to the middle 40% of the screen
        let maxOffset = size.height * 0.2
        let pipeOffset = CGFloat.random(in: -maxOffset...maxOffset)
            
        // Bottom Pipe
        let bottomPipe = SKSpriteNode(color: .green, size: CGSize(width: pipeWidth, height: pipeHeight))
        bottomPipe.position = CGPoint(x: size.width + pipeWidth,
                                      y: (size.height / 2) - (pipeHeight / 2) - (gapHeight / 2) + pipeOffset)
        setupObstaclePhysics(bottomPipe)
            
        // Top Pipe
        let topPipe = SKSpriteNode(color: .green, size: CGSize(width: pipeWidth, height: pipeHeight))
        topPipe.position = CGPoint(x: size.width + pipeWidth,
                                   y: (size.height / 2) + (pipeHeight / 2) + (gapHeight / 2) + pipeOffset)
        setupObstaclePhysics(topPipe)
            
        // Movement duration stays constant, so speed varies naturally by screen width
        let moveLeft = SKAction.moveBy(x: -size.width - (pipeWidth * 2), y: 0, duration: 3.5)
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
        
        // Kill zones relative to frame bounds
        if bird.position.y < (bird.size.height / 2) || bird.position.y > (size.height - bird.size.height / 2) {
            gameOver()
        }
        
        // Visual polish: Tilt the bird based on velocity
        let value = bird.physicsBody!.velocity.dy * (bird.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001)
        bird.zRotation = min(max(-1, value), 0.5)
    }
}
