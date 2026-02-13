//
//  Minigame1.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/22/26.
//

import SpriteKit
import GameController // Required for Keyboard support

class PredatorGame: SKScene {
    var viewModel: MainGameView.ViewModel?
    var dismissAction: (() -> Void)?
    
    // Mini-game nodes
    private let bar = SKSpriteNode(color: .darkGray, size: CGSize(width: 600, height: 40))
    private let needle = SKSpriteNode(color: .white, size: CGSize(width: 8, height: 80))
    private let timerLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    private var dangerZones: [SKSpriteNode] = []
    private var isResolved = false
    private var timeLeft = 10

    override func didMove(to view: SKView) {
        HapticManager.shared.prepare()
        SoundManager.shared.startBackgroundMusic(track: .predator)
        backgroundColor = .black
        
        setupTimingBar()
        setupTimer()
        startNeedleMovement()
    }
    
    // MARK: - Input Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if viewModel?.minigameStarted == true && viewModel?.showMiniGameSheet == false {
            attemptResolve()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Check for Space Bar press via GameController
        if let keyboard = GCKeyboard.coalesced?.keyboardInput {
            if keyboard.button(forKeyCode: .spacebar)?.isPressed == true {
                if viewModel?.minigameStarted == true && viewModel?.showMiniGameSheet == false {
                    attemptResolve()
                }
            }
        }
    }

    /// Shared logic for both Space Bar and Touch
    private func attemptResolve() {
        if isResolved { return }
        
        // Stop all game loops immediately
        isResolved = true
        removeAction(forKey: "gameTimer")
        needle.removeAction(forKey: "needleAnim")
        
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

    // MARK: - Setup & Game Logic
    
    private func setupTimingBar() {
        bar.position = CGPoint(x: frame.midX, y: frame.midY - 50)
        bar.zPosition = 1
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
            zone.zPosition = 2
            bar.addChild(zone)
            
            if isDanger {
                dangerZones.append(zone)
                let miniPredator = SKSpriteNode(imageNamed: "Predator/PredatorHead")
                miniPredator.size = CGSize(width: 70, height: 70)
                miniPredator.position = CGPoint(x: xPos, y: 70)
                miniPredator.zPosition = 3
                bar.addChild(miniPredator)
            }
        }
        
        needle.position = CGPoint(x: bar.frame.minX, y: bar.position.y)
        needle.zPosition = 100
        addChild(needle)
        
        let instructionLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        instructionLabel.text = "TAP OR SPACE TO AVOID PREDATORS!"
        instructionLabel.fontSize = 24
        instructionLabel.fontColor = .white
        instructionLabel.position = CGPoint(x: frame.midX, y: frame.midY + 180)
        instructionLabel.zPosition = 10
        addChild(instructionLabel)
    }

    private func setupTimer() {
        timerLabel.text = "TIME: \(timeLeft)"
        timerLabel.fontSize = 40
        timerLabel.fontColor = .systemYellow
        timerLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 100)
        timerLabel.zPosition = 100
        
        if timerLabel.parent == nil { addChild(timerLabel) }
        
        let wait = SKAction.wait(forDuration: 1.0)
        let update = SKAction.run { [weak self] in
            guard let self = self, !self.isResolved else { return }
            self.timeLeft -= 1
            self.timerLabel.text = "TIME: \(self.timeLeft)"
            
            if self.timeLeft <= 3 && self.timeLeft > 0 {
                self.timerLabel.fontColor = .red
                self.timerLabel.run(SKAction.sequence([
                    SKAction.scale(to: 1.2, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ]))
                HapticManager.shared.trigger(.selection)
            }
            
            if self.timeLeft <= 0 {
                self.handleTimeout()
            }
        }
        run(SKAction.repeatForever(SKAction.sequence([wait, update])), withKey: "gameTimer")
    }

    private func startNeedleMovement() {
        let moveRight = SKAction.moveTo(x: bar.frame.maxX, duration: 0.9)
        let moveLeft = SKAction.moveTo(x: bar.frame.minX, duration: 0.9)
        let hapticTick = SKAction.run { HapticManager.shared.trigger(.selection) }
        let sequence = SKAction.sequence([hapticTick, moveRight, hapticTick, moveLeft])
        needle.run(SKAction.repeatForever(sequence), withKey: "needleAnim")
    }

    private func handleWin() {
        HapticManager.shared.trigger(.success)
        addPoints()
        let winLabel = SKLabelNode(text: "ESCAPED!")
        winLabel.fontColor = .green
        winLabel.fontName = "AvenirNext-Bold"
        winLabel.position = CGPoint(x: frame.midX, y: frame.midY - 150)
        winLabel.zPosition = 200
        addChild(winLabel)
        run(SKAction.wait(forDuration: 1.2)) { [weak self] in self?.returnToMainWorld() }
    }

    private func handleLoss() {
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
            self?.triggerDeathMessage(in: "You died from a predator attack.")
        }
    }

    private func handleTimeout() {
        if isResolved { return }
        isResolved = true
        needle.removeAction(forKey: "needleAnim")
        removeAction(forKey: "gameTimer")
        timerLabel.text = "OUT OF TIME!"
        timerLabel.fontColor = .red
        handleLoss()
    }

    func returnToMainWorld() {
        guard let view = self.view else { return }
        viewModel?.minigameStarted = false
        viewModel?.joystickVelocity = .zero
        viewModel?.controlsAreVisable = true
        viewModel?.mapIsVisable = true
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
    
    func triggerDeathMessage(in message: String) {
        viewModel?.currentDeathMessage = message
    }
}

