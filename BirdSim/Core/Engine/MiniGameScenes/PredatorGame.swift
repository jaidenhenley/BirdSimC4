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
        // Warm up haptics
        HapticManager.shared.prepare()
        
        SoundManager.shared.startBackgroundMusic(track: .predator)
        backgroundColor = .black
        
        setupTimingBar()
        startNeedleMovement()
    }
    
    private func setupTimingBar() {
        bar.position = CGPoint(x: frame.midX, y: frame.midY - 50)
        addChild(bar)
        
        let zoneWidth = bar.size.width / 6
        let zoneTypes = ["danger", "safe", "danger", "safe", "danger", "safe"].shuffled()
        
        for i in 0..<6 {
            let type = zoneTypes[i]
            let isDanger = type == "danger"
            
            let zone = SKSpriteNode(color: isDanger ? .systemRed : .systemGreen,
                                    size: CGSize(width: zoneWidth - 4, height: 40))
            
            let xPos = (-bar.size.width / 2) + (CGFloat(i) * zoneWidth) + (zoneWidth / 2)
            zone.position = CGPoint(x: xPos, y: 0)
            zone.name = type
            bar.addChild(zone)
            
            if isDanger {
                dangerZones.append(zone)
                let miniPredator = SKSpriteNode(imageNamed: "Predator/PredatorHead")
                miniPredator.size = CGSize(width: 70, height: 70)
                miniPredator.position = CGPoint(x: xPos, y: 70)
                bar.addChild(miniPredator)
            }
        }
        
        needle.position = CGPoint(x: bar.frame.minX, y: bar.position.y)
        needle.zPosition = 100
        addChild(needle)
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "AVOID THE PREDATORS!"
        label.fontSize = 28
        label.fontColor = .white
        label.position = CGPoint(x: frame.midX, y: frame.midY + 180)
        addChild(label)
    }
    
    private func startNeedleMovement() {
        // HAPTIC BEAT: We trigger a light tick every time the needle reverses
        let moveRight = SKAction.moveTo(x: bar.frame.maxX, duration: 0.9)
        let moveLeft = SKAction.moveTo(x: bar.frame.minX, duration: 0.9)
        
        let hapticTick = SKAction.run {
            HapticManager.shared.trigger(.selection)
        }
        
        let sequence = SKAction.sequence([hapticTick, moveRight, hapticTick, moveLeft])
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
        // SUCCESS HAPTIC: A crisp double-pulse
        HapticManager.shared.trigger(.success)
        
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
        // ERROR HAPTIC: A heavy, jarring triple-pulse
        HapticManager.shared.trigger(.error)
        
        let lossLabel = SKLabelNode(text: "CAUGHT!")
        lossLabel.fontColor = .red
        lossLabel.fontName = "AvenirNext-Bold"
        lossLabel.fontSize = 40
        lossLabel.position = CGPoint(x: frame.midX, y: frame.midY - 150)
        lossLabel.zPosition = 200
        addChild(lossLabel)
        
        SoundManager.shared.playSoundEffect(named: "error_buzz")

        let flash = SKSpriteNode(color: .red, size: self.size)
        flash.position = CGPoint(x: frame.midX, y: frame.midY)
        flash.alpha = 0.3
        flash.zPosition = 150
        addChild(flash)

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
