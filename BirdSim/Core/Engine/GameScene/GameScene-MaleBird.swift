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
            
            addChild(maleBird)
        }
}
