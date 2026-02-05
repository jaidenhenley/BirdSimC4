//
//  GameScene-BabyHungerBar.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//
import SpriteKit

extension GameScene {
    class BabyHungerBar: SKNode {
        var barSprite: SKSpriteNode?
        let barWidth: CGFloat = 100
        let barHeight: CGFloat = 10

        override init() {
            super.init()
            setupBar()
        }

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            setupBar()
        }

        private func setupBar() {
            // 1. Create a background (the empty gray part of the bar)
            let background = SKSpriteNode(color: .darkGray, size: CGSize(width: barWidth, height: barHeight))
            background.zPosition = -1
            addChild(background)

            // 2. Create the actual filling bar
            // We use a plain white color as the base so the tinting is accurate
            barSprite = SKSpriteNode(color: .white, size: CGSize(width: barWidth, height: barHeight))
            barSprite?.anchorPoint = CGPoint(x: 0, y: 0.5)
            barSprite?.position = CGPoint(x: -barWidth / 2, y: 0)
            
            // Use colorBlendFactor instead of colorSubstituteAmount
            barSprite?.color = .green
            barSprite?.colorBlendFactor = 1.0
            
            if let bar = barSprite {
                addChild(bar)
            }
        }

        func updateBar(percentage: CGFloat) {
            let clippedPercentage = max(0, min(percentage, 1.0))
            
            // Update the scale (1.0 is full, 0.0 is empty)
            barSprite?.xScale = clippedPercentage
            
            // Color feedback
            if clippedPercentage < 0.3 {
                barSprite?.color = .red
            } else if clippedPercentage < 0.6 {
                barSprite?.color = .yellow
            } else {
                barSprite?.color = .green
            }
        }
    }
}
