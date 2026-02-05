//
//  GameScene-Animations.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {
    
    /// Returns the next available nest that does not already contain a baby.
    func nextEmptyNest() -> SKNode? {
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
        let nestID = UUID().uuidString
        let nest = SKSpriteNode(imageNamed: "nest")
        
        nest.name = "nest_active"
        // Standardize userData structure
        let data = NSMutableDictionary()
        data["nestID"] = nestID
        data["hasEgg"] = false
        nest.userData = data
        
        nest.size = CGSize(width: 100, height: 100)
        nest.zPosition = 5
        
        let randomX = CGFloat.random(in: -1000...1000)
        let randomY = CGFloat.random(in: -1000...1000)
        nest.position = CGPoint(x: randomX, y: randomY)
        
        addChild(nest)
        
        nest.alpha = 0
        nest.setScale(0.1)
        nest.run(SKAction.group([
            SKAction.fadeIn(withDuration: 1.0),
            SKAction.scale(to: 1.0, duration: 1.0)
        ]))
    }
    
    func finishBuildingNest(newNest: SKNode) {
        newNest.name = "final_nest"
        spawnBabyInNest(in: newNest)
    }

    func babyBirdNode() -> SKSpriteNode? {
        // Updated to search specifically within nests to avoid confusion
        return self.childNode(withName: "//babyBird") as? SKSpriteNode
    }
    
    func checkBabyWinCondition() {
        // We now check the fedCount inside the specific nest being interacted with
        guard let nest = viewModel?.activeNestNode,
              let data = nest.userData as? NSMutableDictionary,
              let fedCount = data["fedCount"] as? Int,
              fedCount >= 2 else { return }
        
        if let baby = nest.childNode(withName: "babyBird") {
            // Logic for a baby growing up
            self.isBabySpawned = false // Reference to local Scene property
            
            viewModel?.hasBaby = false
            
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
            let fadeOut = SKAction.fadeOut(withDuration: 0.4)
            let remove = SKAction.removeFromParent()
            
            nest.run(SKAction.sequence([scaleUp, fadeOut, remove])) { [weak self] in
                self?.viewModel?.userScore += 5
                self?.viewModel?.currentMessage = "A baby has grown and left the nest!"
                self?.viewModel?.activeNestNode = nil
            }
        }
    }
    
    func spawnBabyInNest(in nest: SKNode) {
        let baby = SKSpriteNode(imageNamed: "babybird")
        baby.name = "babyBird"
        baby.setScale(0.2)
        baby.zPosition = 1
        baby.position = .zero
        
        let hungerBar = BabyHungerBar()
        hungerBar.name = "hungerBar"
        hungerBar.setScale(5.0)
        hungerBar.position = CGPoint(x: 0, y: 350)
        baby.addChild(hungerBar)
        
        // IMPORTANT: The individual timer is born here
        let data = (nest.userData as? NSMutableDictionary) ?? NSMutableDictionary()
        data["spawnDate"] = Date()
        data["fedCount"] = 0
        nest.userData = data
        
        let body = SKPhysicsBody(circleOfRadius: 25)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.baby
        baby.physicsBody = body

        nest.addChild(baby)
        
        viewModel?.hasBaby = true
        // Position and SpawnDate are now managed via Node/Persistence, not global variables
        viewModel?.saveState()

        baby.alpha = 0
        baby.run(SKAction.fadeIn(withDuration: 1.0))
    }
    
    func removeBabyBird() {
        // Cleans up all babies in all nests
        enumerateChildNodes(withName: "//babyBird") { node, _ in
            node.removeFromParent()
        }
    }
    
    func removeSpecificNest(_ nest: SKNode) {
        nest.name = "nest_removing"
        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
        let scaleDown = SKAction.scale(to: 0.2, duration: 0.8)
        let group = SKAction.group([fadeOut, scaleDown])
        let remove = SKAction.removeFromParent()
        nest.run(SKAction.sequence([group, remove]))
    }
    
    func restorePersistedNestAndBaby() {
        guard let viewModel = viewModel else { return }

        // Restore single nest from SwiftData
        if viewModel.hasNest, let pos = viewModel.nestPosition {
            let nest = SKSpriteNode(imageNamed: "nest")
            nest.name = "final_nest"
            nest.size = CGSize(width: 100, height: 100)
            nest.zPosition = 5
            nest.position = pos
            
            let data = NSMutableDictionary()
            // If the app restarted, we reset the timer to Date() so the baby doesn't instantly die
            data["spawnDate"] = Date()
            data["fedCount"] = 0
            nest.userData = data
            
            addChild(nest)

            if viewModel.hasBaby {
                let baby = SKSpriteNode(imageNamed: "babybird")
                baby.name = "babyBird"
                baby.setScale(0.2)
                baby.zPosition = 1
                baby.position = CGPoint(x: 0, y: 10)

                let body = SKPhysicsBody(circleOfRadius: 25)
                body.isDynamic = false
                body.categoryBitMask = PhysicsCategory.baby
                baby.physicsBody = body
                
                let hungerBar = BabyHungerBar()
                hungerBar.name = "hungerBar"
                hungerBar.setScale(5.0)
                hungerBar.position = CGPoint(x: 0, y: 350)
                baby.addChild(hungerBar)
                
                nest.addChild(baby)
            }
        }
    }
}
