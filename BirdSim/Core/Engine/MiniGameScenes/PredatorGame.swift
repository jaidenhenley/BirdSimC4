//
//  Minigame1.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/22/26.
//

import SpriteKit

class PredatorGame: SKScene {
    var viewModel: MainGameView.ViewModel?
    var dismissAction: (() -> Void)?
    
    // Mini-game nodes
    private let bar = SKSpriteNode(color: .darkGray, size: CGSize(width: 400, height: 40))
    private let dangerZone = SKSpriteNode(color: .systemRed, size: CGSize(width: 100, height: 40))
    private let safeZone = SKSpriteNode(color: .systemGreen, size: CGSize(width: 300, height: 40))
    private let needle = SKSpriteNode(color: .white, size: CGSize(width: 8, height: 60))
    
    private var isResolved = false

    override func didMove(to view: SKView) {
        backgroundColor = .black // Dark background for contrast
        setupTimingBar()
        startNeedleMovement()
    }
    
    private func setupTimingBar() {
        // 1. Position the main bar in the center
        bar.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(bar)
        
        // 2. Add a 'Safe' background to the bar
        bar.addChild(safeZone)
        
        // 3. Add the Danger Zone (the part that causes defeat)
        // Positioned in the middle of the bar
        dangerZone.position = .zero
        dangerZone.name = "danger"
        bar.addChild(dangerZone)
        
        // 4. Setup the needle
        needle.position = CGPoint(x: bar.frame.minX, y: frame.midY)
        needle.zPosition = 10
        addChild(needle)
        
        // Instruction Label
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "STOP ON THE GREEN TO ESCAPE!"
        label.fontSize = 24
        label.position = CGPoint(x: frame.midX, y: frame.midY + 100)
        addChild(label)
    }
    
    private func startNeedleMovement() {
        // Needle moves back and forth across the bar's width
        let moveRight = SKAction.moveTo(x: bar.frame.maxX, duration: 1.0)
        let moveLeft = SKAction.moveTo(x: bar.frame.minX, duration: 1.0)
        let sequence = SKAction.sequence([moveRight, moveLeft])
        needle.run(SKAction.repeatForever(sequence), withKey: "needleAnim")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isResolved { return }
        
        // Stop movement immediately on tap
        needle.removeAction(forKey: "needleAnim")
        isResolved = true
        
        // Calculate hit detection
        let needleX = needle.position.x
        
        // Convert DangerZone's world position to check boundaries
        let dangerWorldPos = dangerZone.parent!.convert(dangerZone.position, to: self)
        let dangerRange = (dangerWorldPos.x - dangerZone.size.width/2)...(dangerWorldPos.x + dangerZone.size.width/2)
        
        if dangerRange.contains(needleX) {
            // LOST: Needle stopped on Red
            handleLoss()
        } else {
            // WON: Needle stopped on Green
            handleWin()
        }
    }
    
    private func handleWin() {
        let winLabel = SKLabelNode(text: "SUCCESS!")
        winLabel.fontColor = .green
        winLabel.position = CGPoint(x: frame.midX, y: frame.midY - 80)
        addChild(winLabel)
        
        // Return to map after short delay
        run(SKAction.wait(forDuration: 1.0)) { [weak self] in
            guard let self = self, let view = self.view else { return }
            self.viewModel?.joystickVelocity = .zero
            self.viewModel?.controlsAreVisable = true
            
            let transition = SKTransition.crossFade(withDuration: 0.5)
            if let existing = self.viewModel?.mainScene {
                view.presentScene(existing, transition: transition)
            }
        }
    }
    
    private func handleLoss() {
        let lossLabel = SKLabelNode(text: "CAUGHT!")
        lossLabel.fontColor = .red
        lossLabel.position = CGPoint(x: frame.midX, y: frame.midY - 80)
        addChild(lossLabel)
        
        // Trigger Game Over via ViewModel
        run(SKAction.wait(forDuration: 1.0)) { [weak self] in
            self?.triggerGameOver()
        }
    }
    
    func triggerGameOver() {
        dismissAction?()
    }
}
