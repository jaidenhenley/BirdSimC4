//
//  GameScene-Animations.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit


extension GameScene {
    
    /// Returns the next available nest that does not already contain a baby.
    /// No distance checks — just finds an empty nest.
    func nextEmptyNest() -> SKNode? {
        // Check for both the "active" build site and the "final" completed nest
        for node in children.reversed() {
            if node.name == "final_nest" || node.name == "nest_active" {
                if node.childNode(withName: "babyBird") == nil {
                    return node
                }
            }
        }
        return nil
    }
    
    func spawnSuccessNest() {
        // Generate a unique ID for this specific nest instance
        let nestID = UUID().uuidString
        let nest = SKSpriteNode(imageNamed: "nest")
        
        nest.name = "nest_active" // Generic name for proximity checks
        nest.userData = ["nestID": nestID, "hasEgg": false] // Track state per nest
        
        nest.size = CGSize(width: 100, height: 100)
        nest.zPosition = 5
        
        // Spawn near player or at random
        let randomX = CGFloat.random(in: -1000...1000)
        let randomY = CGFloat.random(in: -1000...1000)
        nest.position = CGPoint(x: randomX, y: randomY)
        
        addChild(nest)
        
        // Visual "Poof"
        nest.alpha = 0
        nest.setScale(0.1)
        nest.run(SKAction.group([
            SKAction.fadeIn(withDuration: 1.0),
            SKAction.scale(to: 1.0, duration: 1.0)
        ]))
    }
    
    func finishBuildingNest(newNest: SKNode) {
        // 1. Label the nest so your other logic can identify it as complete
        newNest.name = "final_nest"
        
        // 2. Pass this specific nest instance to the spawn function
        spawnBabyInNest(in: newNest)
    }

    
    
    // Finds the baby bird even if it's nested under another node (like the nest).
    func babyBirdNode() -> SKSpriteNode? {
        return self.childNode(withName: "//babyBird") as? SKSpriteNode
    }
    
    func checkBabyWinCondition() {
        guard let fedCount = viewModel?.userFedBabyCount, fedCount >= 2 else { return }
        
        // 1. Find the baby using the recursive search helper you already have
        if let baby = babyBirdNode(), let nest = baby.parent {
            
            // Prevent multiple triggers by clearing this immediately
            self.babySpawnTime = nil
            self.isBabySpawned = false
            
            // 2. Play the Success Animation
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            
            nest.run(SKAction.sequence([scaleUp, fadeOut, remove])) { [weak self] in
                // 3. Reset Game State AFTER animation finishes
                self?.viewModel?.userScore += 2
                self?.viewModel?.userFedBabyCount = 0
                self?.viewModel?.hasFoundMale = false
                self?.viewModel?.clearNestAndBabyState()
                self?.viewModel?.currentMessage = "The baby has grown and left the nest!"
            }
            
            print("DEBUG: Baby fed twice. Nest and baby removed.")
        }
    }
    
    func spawnBabyInNest(in nest: SKNode) {
        // We no longer need to search for "final_nest" here because we passed it in!
        
        let baby = SKSpriteNode(imageNamed: "babybird")
        baby.name = "babyBird"
        baby.setScale(0.2)
        baby.zPosition = 1 // Ensure it's above the nest texture
        
        // Position it at the center of the nest
        baby.position = .zero
        
        let hungerBar = BabyHungerBar()
        hungerBar.name = "hungerBar"
        hungerBar.setScale(5.0)
        hungerBar.position = CGPoint(x: 0, y: 350)
        baby.addChild(hungerBar)
        
        // Physics body for feeding
        let body = SKPhysicsBody(circleOfRadius: 25)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.baby
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.none
        baby.physicsBody = body

        babySpawnTime = Date()
        nest.addChild(baby) // Add baby to the specific nest passed in

        viewModel?.hasBaby = true
        viewModel?.babyPosition = baby.convert(.zero, to: self)
        viewModel?.babySpawnDate = babySpawnTime
        viewModel?.saveState()

        baby.alpha = 0
        baby.run(SKAction.fadeIn(withDuration: 1.0))
        viewModel?.currentMessage = "The baby has hatched! Now keep it fed."
    }
    
    func removeBabyBird() {
        // Remove babies that are nested inside any nest
        for nest in children where nest.name == "final_nest" {
            nest.childNode(withName: "babyBird")?.removeFromParent()
        }
        // Also remove any stray babies added directly to the scene (safety)
        for node in children where node.name == "babyBird" {
            node.removeFromParent()
        }
    }
    
    func removeSpecificNest(_ nest: SKNode) {
        // Change name immediately so the update loop doesn't hit it again
        nest.name = "nest_removing"

        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
        let scaleDown = SKAction.scale(to: 0.2, duration: 0.8)
        let group = SKAction.group([fadeOut, scaleDown])
        let remove = SKAction.removeFromParent()
        
        nest.run(SKAction.sequence([group, remove]))
    }
    
    func restorePersistedNestAndBaby() {
        guard let viewModel = viewModel else { return }

        // Restore Nest
        if viewModel.hasNest, let pos = viewModel.nestPosition {
            let nest = SKSpriteNode(imageNamed: "nest")
            nest.name = "final_nest"
            nest.size = CGSize(width: 100, height: 100)
            nest.zPosition = 5
            nest.position = pos
            addChild(nest)
        }

        // Restore Baby
        if viewModel.hasBaby, let worldPos = viewModel.babyPosition {
            // Try to find an existing nest to parent the baby (prefer exact match to saved nestPosition)
            var targetNest: SKNode? = nil
            if let savedNestPos = viewModel.nestPosition {
                targetNest = children.first(where: { $0.name == "final_nest" && $0.position == savedNestPos })
            }
            if targetNest == nil {
                // Fallback: nearest nest to the saved baby position
                let nests = children.filter { $0.name == "final_nest" }
                targetNest = nests.min(by: { lhs, rhs in
                    let dx1 = lhs.position.x - worldPos.x
                    let dy1 = lhs.position.y - worldPos.y
                    let d1 = dx1*dx1 + dy1*dy1
                    let dx2 = rhs.position.x - worldPos.x
                    let dy2 = rhs.position.y - worldPos.y
                    let d2 = dx2*dx2 + dy2*dy2
                    return d1 < d2
                })
            }

            let baby = SKSpriteNode(imageNamed: "babyBird")
            baby.name = "babyBird"
            baby.zPosition = 6
            baby.setScale(0.2)

            let body = SKPhysicsBody(circleOfRadius: 25)
            body.isDynamic = false
            body.categoryBitMask = PhysicsCategory.baby
            body.contactTestBitMask = PhysicsCategory.player
            body.collisionBitMask = PhysicsCategory.none
            baby.physicsBody = body

            if let nest = targetNest {
                // Place as child of nest with a local offset similar to spawnBabyInNest
                baby.position = CGPoint(x: 0, y: 10)
                nest.addChild(baby)
            } else {
                // Fallback: place at saved world position if no nest found
                baby.position = worldPos
                addChild(baby)
            }

            // Restore the hatch timer
            self.babySpawnTime = viewModel.babySpawnDate
        }
    }
}
