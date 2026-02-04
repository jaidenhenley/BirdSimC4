//
//  GameScene-BabyHungerBar.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {
    class BabyHungerBar: SKNode {
        private let barWidth: CGFloat = 60
        private let barHeight: CGFloat = 8
        private let fillNode = SKSpriteNode(color: .green, size: CGSize(width: 60, height: 8))
        private var isPanicking = false
        
        override init() {
            super.init()
            
            // 1. The background (the empty track)
            let bgNode = SKSpriteNode(color: .black, size: CGSize(width: barWidth + 2, height: barHeight + 2))
            bgNode.alpha = 0.5
            bgNode.zPosition = -1 // Ensure it stays behind the fill
            addChild(bgNode)
            
            // 2. The fill (the actual hunger level)
            fillNode.anchorPoint = CGPoint(x: 0, y: 0.5)
            fillNode.position = CGPoint(x: -barWidth / 2, y: 0)
            addChild(fillNode)
        }
        
        required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        
        func updateBar(percentage: CGFloat) {
            // Update the scale of the bar
            fillNode.xScale = max(0, percentage)
            
            // --- Urgency Logic ---
            if percentage > 0.6 {
                fillNode.color = .green
                stopPanic()
            } else if percentage > 0.25 {
                fillNode.color = .yellow
                stopPanic()
            } else {
                fillNode.color = .red
                triggerPanic() // Start the visual alarm
            }
        }
        
        private func triggerPanic() {
            // Prevent stacking animations if already panicking
            guard !isPanicking else { return }
            isPanicking = true
            
            // A. Pulse the scale of the entire bar
            let pulseUp = SKAction.scale(to: 1.25, duration: 0.25)
            let pulseDown = SKAction.scale(to: 1.0, duration: 0.25)
            let pulseSequence = SKAction.sequence([pulseUp, pulseDown])
            self.run(SKAction.repeatForever(pulseSequence), withKey: "panicPulse")
            
            // B. Flash the fill color between Red and White
            let flashWhite = SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.15)
            let flashRed = SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 0.15)
            let flashSequence = SKAction.sequence([flashWhite, flashRed])
            fillNode.run(SKAction.repeatForever(flashSequence), withKey: "panicFlash")
        }
        
        func stopPanic() {
            guard isPanicking else { return }
            isPanicking = false
            
            // Remove the animations and reset scale/color
            self.removeAction(forKey: "panicPulse")
            fillNode.removeAction(forKey: "panicFlash")
            
            // Reset to natural state
            let resetScale = SKAction.scale(to: 1.0, duration: 0.2)
            self.run(resetScale)
        }
    }

}
