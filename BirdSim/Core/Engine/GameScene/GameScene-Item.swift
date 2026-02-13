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
        let itemName = rawName.lowercased()

        // 1. Check BEFORE doing anything else
        // Use a local check to see if the item is already in the list
        let alreadyOwned = viewModel?.collectedItems.contains(itemName) ?? false

        if alreadyOwned {
            print("DEBUG: Already owned \(itemName), playing tink.")
            viewModel?.currentMessage = "You already have a \(itemName)"
            SoundManager.shared.playEffect(.tink)
            return
        }
        
        // 2. Play the success sound IMMEDIATELY
        // We do this before the ViewModel update to ensure no race conditions
        SoundManager.shared.playEffect(.pickUp)

        // 3. Update State via ViewModel
        viewModel?.collectItem(itemName)
        if viewModel?.tutorialIsOn == true, viewModel?.pickedUpOnce == false {
            viewModel?.showMainGameInstructions(type: .pickupRemainingItems)
            viewModel?.pickedUpOnce = true
        }
        // Remove the item from the world
        node.removeFromParent()

        // Optional: brief feedback
        viewModel?.currentMessage = "Picked up \(itemName.capitalized)"
        
        // 4. Visual Feedback
        // We hide the node immediately so it feels "picked up" even while animating
        node.name = "picked_up_inactive" // Rename so it can't be double-tapped
        
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.15)
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        let group = SKAction.group([scaleDown, fadeOut])
        
        node.run(SKAction.sequence([
            group,
            SKAction.removeFromParent()
        ]))

        // 5. Logic and Respawn
        scheduleRespawn(for: rawName)
        SoundManager.shared.playEffect(.alert)

        print("Successfully added \(itemName) to collected items.")
    }
    
    func spawnItem(at position: CGPoint, type: String) {
        let item = SKSpriteNode(imageNamed: type)
        item.position = position
        item.name = type
        item.setScale(0.5)
            
        let moveUp = SKAction.moveBy(x: 0, y: 10, duration: 0.2)
        let moveDown = SKAction.moveBy(x: 0, y: -10, duration: 0.2)
        let wait = SKAction.wait(forDuration: 0.1)
        
        let bounceSequence = SKAction.sequence([moveUp, moveDown, wait])
        
        let repeatBounce = SKAction.repeatForever(bounceSequence)
        
        item.run(repeatBounce)
        
        
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
