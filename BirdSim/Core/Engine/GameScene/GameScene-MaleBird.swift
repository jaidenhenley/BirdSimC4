//
//  GameScene-MaleBird.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {
    func spawnMaleBird() {
            if childNode(withName: "MaleBird") != nil { return }
            
            let maleBird = SKSpriteNode(imageNamed: "Predator/MaleBird")
            maleBird.name = "MaleBird"
            maleBird.size = CGSize(width: 200, height: 200)
            maleBird.zPosition = 5
            
            // Position him somewhere random but far enough away to be a "quest"
            let randomX = CGFloat.random(in: 500...1000) * (Bool.random() ? 1 : -1)
            let randomY = CGFloat.random(in: 500...1000) * (Bool.random() ? 1 : -1)
            maleBird.position = CGPoint(x: randomX, y: randomY)
            
            // Physics for contact detection
            maleBird.physicsBody = SKPhysicsBody(circleOfRadius: 25)
            maleBird.physicsBody?.isDynamic = false
            maleBird.physicsBody?.categoryBitMask = PhysicsCategory.mate
            maleBird.physicsBody?.contactTestBitMask = PhysicsCategory.player
            maleBird.physicsBody?.collisionBitMask = PhysicsCategory.none
        maleBird.physicsBody?.categoryBitMask = PhysicsCategory.mate
        // The male bird must be looking for the player
        maleBird.physicsBody?.contactTestBitMask = PhysicsCategory.player
        
        // Face right initially
        maleBird.xScale = abs(maleBird.xScale)
        maleBird.zRotation = -(.pi / 2)

        // Simple back-and-forth motion. Facing is handled per-frame by `updatePredatorFacingDirections()`.
        let moveRight = SKAction.moveBy(x: 1000, y: 0, duration: 12)
        let moveLeft  = moveRight.reversed()
        let sequence = SKAction.sequence([moveRight, moveLeft])
        maleBird.run(SKAction.repeatForever(sequence))
            addChild(maleBird)
        }
    
    func updateMaleFacingDirections() {
        enumerateChildNodes(withName: "MaleBird") { node, _ in
            guard let male = node as? SKSpriteNode else { return }

            if male.userData == nil { male.userData = [:] }

            let currentX = male.position.x
            let lastXNumber = male.userData?["lastX"] as? NSNumber
            let lastX = lastXNumber.map { CGFloat($0.doubleValue) } ?? currentX

            let dx = currentX - lastX
 
            // Small threshold prevents rapid flipping from tiny jitter
            if dx > 0.5 {
                male.zRotation = -(.pi / 2)
            } else if dx < -0.5 {
                male.zRotation = .pi / 2
            }

            male.userData?["lastX"] = NSNumber(value: Double(currentX))
        }
    }
    
    
}
