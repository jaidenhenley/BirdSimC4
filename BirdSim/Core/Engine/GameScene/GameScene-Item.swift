//
//  GameScene-Item.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {
    func pickupItem(_ node: SKNode) {
        guard let rawName = node.name else { return }
        // Standardize to lowercase so set membership is consistent
        let itemName = rawName.lowercased()

        // Drive inventory UI from collectedItems via the ViewModel helper
        // This also persists and optionally updates counts if you still track them
        if viewModel?.collectedItems.contains(itemName) == true {
            viewModel?.currentMessage = " You already have \(itemName)"
            return
        }
        
        viewModel?.collectItem(itemName)
        if viewModel?.tutorialIsOn == true, viewModel?.pickedUpOnce == false {
            viewModel?.showMainGameInstructions(type: .pickupRemainingItems)
            viewModel?.pickedUpOnce = true
        }
        // Remove the item from the world
        node.removeFromParent()

        // Optional: brief feedback
        viewModel?.currentMessage = "Picked up \(itemName.capitalized)"
        scheduleRespawn(for: node.name!)
        print("Successfully added \(itemName) to collected items.")
    }
    
    func spawnItem(at position: CGPoint, type: String) {
        let item = SKSpriteNode(imageNamed: type)
        item.position = position
        item.name = type
        item.setScale(0.5)
        
        self.addChild(item)
    }
    
    
    func scheduleRespawn(for itemName: String) {
        print("⏰ Respawn timer started for: \(itemName). Will appear in 30s.")
        
        // Create a sequence of 5-second waits to print progress
        let segment = SKAction.sequence([
            SKAction.wait(forDuration: 5.0),
            SKAction.run { print("... \(itemName) respawning in 25s...") },
            SKAction.wait(forDuration: 5.0),
            SKAction.run { print("... \(itemName) respawning in 20s...") },
            SKAction.wait(forDuration: 10.0),
            SKAction.run { print("... \(itemName) respawning in 10s...") },
            SKAction.wait(forDuration: 10.0)
        ])
        
        let spawn = SKAction.run { [weak self] in
            guard let self = self, let player = self.childNode(withName: "userBird") else { return }
            
            // DEBUG: Instead of totally random, spawn it within 500 pixels of the player
            // so you can actually see it happen!
            let randomX = player.position.x + CGFloat.random(in: -500...500)
            let randomY = player.position.y + CGFloat.random(in: -500...500)
            let spawnPoint = CGPoint(x: randomX, y: randomY)
            
            self.spawnItem(at: spawnPoint, type: itemName)
            
            
            print("✅ SUCCESS: \(itemName) respawned at \(spawnPoint)")
        }
        
        self.run(SKAction.sequence([segment, spawn]))
    }
    
    func clearCollectedItemsFromMap() {
        // Look for any nodes that match your item names
        for node in children {
            if let name = node.name, ["stick", "leaf", "spiderweb", "dandelion"].contains(name) {
                // Only remove them if the player has actually "built" with them
                // Or just remove all to 'respawn' them later
                node.removeFromParent()
            }
        }
    }
}
