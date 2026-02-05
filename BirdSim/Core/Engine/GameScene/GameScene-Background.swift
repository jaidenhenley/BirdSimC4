//
//  GameScene-Background.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {
    func setupBackground() {
        // Remove existing background
        self.children
            .filter { $0.name == "background" }
            .forEach { $0.removeFromParent() }
        
        let grassTexture = SKTexture(imageNamed: "map_land")
        grassTexture.usesMipmaps = true
        grassTexture.filteringMode = .linear
        
        let waterTexture = SKTexture(imageNamed: "map_water")
        waterTexture.usesMipmaps = true
        waterTexture.filteringMode = .linear
        
        let grassBackground = SKSpriteNode(texture: grassTexture)
        grassBackground.name = "background"
        grassBackground.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        grassBackground.position = .zero
        grassBackground.zPosition = -1
        
        // Treat map as fixed world size (no scaling hacks)
        grassBackground.size = CGSize(width: 8000, height: 5000)
        grassBackground.xScale = 1
        grassBackground.yScale = 1
        
        let waterBackground = SKSpriteNode(texture: waterTexture)
        waterBackground.name = "background1"
        waterBackground.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        waterBackground.position = .zero
        waterBackground.zPosition = -2
        waterBackground.size = CGSize(width: 12000, height: 12000)
        
        // Treat map as fixed world size (no scaling hacks)
        waterBackground.size = CGSize(width: 10000, height: 8000)
        waterBackground.xScale = 1
        waterBackground.yScale = 1
        
        addChild(grassBackground)
        addChild(waterBackground)
    }
}
