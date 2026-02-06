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
    private let bar = SKSpriteNode(color: .darkGray, size: CGSize(width: 600, height: 40))
    private let needle = SKSpriteNode(color: .white, size: CGSize(width: 8, height: 80))
    
    private var dangerZones: [SKSpriteNode] = []
    private var isResolved = false

    override func didMove(to view: SKView) {
        SoundManager.shared.startBackgroundMusic(track: .predator)
        backgroundColor = .black
        
        setupTimingBar()
        startNeedleMovement()
    }
    
    private func setupTimingBar() {
        // 1. Position the main bar
        bar.position = CGPoint(x: frame.midX, y: frame.midY - 50)
        addChild(bar)
        
        // 2. Setup Zones (3 Danger, 3 Safe)
        let zoneWidth = bar.size.width / 6
        // We shuffle to keep the player on their toes
        let zoneTypes = ["danger", "safe", "danger", "safe", "danger", "safe"].shuffled()
        
        for i in 0..<6 {
            let type = zoneTypes[i]
            let isDanger = type == "danger"
            
            // Create the slot/zone
            let zone = SKSpriteNode(color: isDanger ? .systemRed : .systemGreen,
                                    size: CGSize(width: zoneWidth - 4, height: 40)) // -4 for a tiny gap
            
            let xPos = (-bar.size.width / 2) + (CGFloat(i) * zoneWidth) + (zoneWidth / 2)
            zone.position = CGPoint(x: xPos, y: 0)
            zone.name = type
            bar.addChild(zone)
            
            if isDanger {
                dangerZones.append(zone)
                
                // 3. Place a Predator Head above every Red Zone
                let miniPredator = SKSpriteNode(imageNamed: "Predator/PredatorHead")
                miniPredator.size = CGSize(width: 70, height: 70)
                // Positioned relative to the zone, slightly above
                miniPredator.position = CGPoint(x: xPos, y: 70)
                bar.addChild(miniPredator)
            } else {
                // Optional: Place a "Nest" or "Safe" icon above Green zones
                
            }
        }
        
        // 4. Setup the needle
        // We set zPosition high so it stays on top of everything
        needle.position = CGPoint(x: bar.frame.minX, y: bar.position.y)
        needle.zPosition = 100
        addChild(needle)
        
        // Instruction Label
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "AVOID THE PREDATORS!"
        label.fontSize = 28
        label.fontColor = .white
        label.position = CGPoint(x: frame.midX, y: frame.midY + 180)
        addChild(label)
    }
    
    private func startNeedleMovement() {
        let moveRight = SKAction.moveTo(x: bar.frame.maxX, duration: 0.9)
        let moveLeft = SKAction.moveTo(x: bar.frame.minX, duration: 0.9)
        let sequence = SKAction.sequence([moveRight, moveLeft])
        needle.run(SKAction.repeatForever(sequence), withKey: "needleAnim")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isResolved { return }
        
        needle.removeAction(forKey: "needleAnim")
        isResolved = true
        
        let needleX = needle.position.x
        var caught = false
        
        for zone in dangerZones {
            let zoneWorldPos = zone.parent!.convert(zone.position, to: self)
            let halfWidth = zone.size.width / 2
            let range = (zoneWorldPos.x - halfWidth)...(zoneWorldPos.x + halfWidth)
            
            if range.contains(needleX) {
                caught = true
                break
            }
        }
        
        if caught {
            handleLoss()
        } else {
            handleWin()
        }
    }
    
    private func handleWin() {
        addPoints()
        let winLabel = SKLabelNode(text: "ESCAPED!")
        winLabel.fontColor = .green
        winLabel.fontName = "AvenirNext-Bold"
        winLabel.position = CGPoint(x: frame.midX, y: frame.midY - 150)
        addChild(winLabel)
        
        run(SKAction.wait(forDuration: 1.2)) { [weak self] in
            self?.returnToMainWorld()
        }
    }
    
    private func handleLoss() {
        // 1. Visual Feedback
        let lossLabel = SKLabelNode(text: "CAUGHT!")
        lossLabel.fontColor = .red
        lossLabel.fontName = "AvenirNext-Bold"
        lossLabel.fontSize = 40
        lossLabel.position = CGPoint(x: frame.midX, y: frame.midY - 150)
        lossLabel.zPosition = 200 // Ensure it's on top of everything
        addChild(lossLabel)
        
        // 2. Play a sound effect if you have one
        SoundManager.shared.playSoundEffect(named: "error_buzz")

        // 3. Optional: Flash the screen red
        let flash = SKSpriteNode(color: .red, size: self.size)
        flash.position = CGPoint(x: frame.midX, y: frame.midY)
        flash.alpha = 0.3
        flash.zPosition = 150
        addChild(flash)

        // 4. Delay before exiting
        run(SKAction.wait(forDuration: 1.5)) { [weak self] in
            self?.triggerGameOver()
        }
    }
    
    func returnToMainWorld() {
        guard let view = self.view else { return }
        viewModel?.joystickVelocity = .zero
        viewModel?.controlsAreVisable = true
        let transition = SKTransition.crossFade(withDuration: 0.5)
        if let existing = viewModel?.mainScene {
            view.presentScene(existing, transition: transition)
        }
    }

    func addPoints() {
        viewModel?.userScore += 1
    }
    
    func triggerGameOver() {
        dismissAction?()
    }
}
