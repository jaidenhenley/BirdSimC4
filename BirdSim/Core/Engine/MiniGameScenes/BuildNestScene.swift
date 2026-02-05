//
//  MiniGameScene2.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/26/26.
//

import SpriteKit

class BuildNestScene: SKScene {
    var viewModel: MainGameView.ViewModel?
    var draggedNode: SKSpriteNode?
    var originalPosition: CGPoint?
    private var backgroundNode: SKSpriteNode?
    
    // This connects the ViewModel's success to the Scene's transition
    // Inside BuildNestScene.swift
    override func didMove(to view: SKView) {
        self.scaleMode = .resizeFill
        
        SoundManager.shared.startBackgroundMusic(track: .nestBuilding)
        // Success path
        viewModel?.onChallengeComplete = { [weak self] in
            
            self?.addPoints()
            self?.exitMiniGame()
        }
        
        // Failure path
        viewModel?.onChallengeFailed = { [weak self] in
            self?.handleFailure()
        }
        
        setupGame()
        showMemorizationPhase()
    }

    
   
    
    func addPoints() {
        viewModel?.userScore += 1 // change score amount for build nest minigame here
        print("added 1 to score")
    }
    
    func exitMiniGame() {
        // 1. Reset the draggable items visibility for the next time the game opens
        let items = ["stick", "leaf", "spiderweb", "dandelion"]
        for name in items {
            self.childNode(withName: name)?.isHidden = false
        }
        
        guard let view = self.view, let mainScene = viewModel?.mainScene else { return }
        
        // 2. ONLY trigger mating if the nest is complete (3 items placed)
        let filledSlots = viewModel?.slots.compactMap { $0 }.count ?? 0
        if filledSlots == 4 {
            // Success path: Trigger the CPU bird spawn
            viewModel?.userScore += 1 // change score amount for build nest minigame here
            print("added 1 to score")
            viewModel?.startMatingPhase()
        } else {
            viewModel?.inventory = ["stick": 0, "leaf": 0, "spiderweb": 0, "dandelion": 0]
        }
        
        // 3. Return to the main world

        viewModel?.controlsAreVisable = true
        let transition = SKTransition.doorsOpenHorizontal(withDuration: 0.5)
        view.presentScene(mainScene, transition: transition)
    }
    
    // --- 1. SETUP THE INITIAL VIEW ---
    func setupGame() {
        setupBackground()

        
        let backLabel = SKLabelNode(text: "EXIT MINI-GAME")
        backLabel.position = CGPoint(x: frame.midX - 100, y: 100) // Moved slightly left
        backLabel.fontName = "AvenirNext-Bold"
        backLabel.fontSize = 20
        backLabel.name = "Back Button"
        backLabel.zPosition = 50
        addChild(backLabel)
        
        
        
        viewModel?.startNewChallenge()
    }
    
    func setupBackground() {
        // If the background already exists (e.g., on rotation/resize), just update its size/position
        if let bg = backgroundNode {
            bg.size = self.size
            bg.position = CGPoint(x: frame.midX, y: frame.midY)
            return
        }

        // Create the background sprite using your asset
        let backgroundtexture = SKTexture(image: .background)
        let background = SKSpriteNode(texture: backgroundtexture)

        background.zPosition = -100 // Behind everything
        background.size = self.size
        background.position = CGPoint(x: frame.midX, y: frame.midY)

        addChild(background)
        backgroundNode = background
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        backgroundNode?.size = self.size
        backgroundNode?.position = CGPoint(x: frame.midX, y: frame.midY)
    }
    
    // --- 2. THE MEMORIZATION PHASE ---
    func showMemorizationPhase() {
        guard let sequence = viewModel?.challengeSequence else { return }
        
        // Create a container so we can delete everything at once
        let hintContainer = SKNode()
        hintContainer.name = "HintContainer"
        addChild(hintContainer)
        
        for (index, itemName) in sequence.enumerated() {
            let hint = SKSpriteNode(imageNamed: itemName)
            hint.size = CGSize(width: 80, height: 80)
            // Positioned ABOVE the slots
            hint.position = CGPoint(x: frame.midX + CGFloat(index - 1) * 110, y: frame.midY + 150)
            hintContainer.addChild(hint)
        }
        
        // The "Disappearing" Logic
        let wait = SKAction.wait(forDuration: 3.0)
        let removeHints = SKAction.run { [weak self] in
            // This clears the 3 images above the slots
            hintContainer.removeFromParent()
            // NOW show the slots and draggables
            self?.setupBuildingPhase()
        }
        
        run(SKAction.sequence([wait, removeHints]))
    }
    
    // --- 3. THE BUILDING PHASE ---
    func setupBuildingPhase() {
        // Remove any previous UI background if present
        self.childNode(withName: "BuildBG")?.removeFromParent()

        // Layout constants
        let slotSize = CGSize(width: 90, height: 90)
        let draggableSize = CGSize(width: 70, height: 70)
        let spacingX: CGFloat = 110
        let slotsY: CGFloat = 60
        let draggablesY: CGFloat = -120

        // Background size (wide enough for 4 columns + padding)
        let bgWidth = (3 * spacingX) + slotSize.width + 120 // 3 gaps + slot width + padding
        let bgHeight = slotSize.height + draggableSize.height + 200 // rows + vertical padding
        let bg = SKShapeNode(rectOf: CGSize(width: bgWidth, height: bgHeight), cornerRadius: 16)
        bg.name = "BuildBG"
        bg.fillColor = .black
        bg.strokeColor = .clear
        bg.alpha = 0.3
        bg.position = CGPoint(x: frame.midX, y: frame.midY)
        bg.zPosition = 5
        addChild(bg)

        // 1. The 4 Empty Slots (Centered)
        for i in 0..<4 {
            let slot = SKShapeNode(rectOf: slotSize, cornerRadius: 8)
            slot.name = "slot_\(i)"
            let x = (CGFloat(i) - 1.5) * spacingX
            slot.position = CGPoint(x: frame.midX + x, y: frame.midY + slotsY)
            slot.strokeColor = .white
            slot.fillColor = .clear
            slot.zPosition = 6
            addChild(slot)
        }

        // 2. The 4 Draggable Items (Centered below)
        let items = ["stick", "leaf", "spiderweb", "dandelion"]
        for (index, name) in items.enumerated() {
            let draggable = SKSpriteNode(imageNamed: name)
            draggable.name = name
            draggable.size = draggableSize
            let x = (CGFloat(index) - 1.5) * spacingX
            draggable.position = CGPoint(x: frame.midX + x, y: frame.midY + draggablesY)
            draggable.zPosition = 7
            addChild(draggable)
        }
    }
    
    
    // --- 4. TOUCH CONTROLS ---
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)
        
        if node.name == "Back Button" {
            exitMiniGame()
        } else if ["stick", "leaf", "spiderweb", "dandelion"].contains(node.name) {
            draggedNode = node as? SKSpriteNode
            originalPosition = node.position
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let draggedNode = draggedNode else { return }
        draggedNode.position = touch.location(in: self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let draggedNode = draggedNode, let original = originalPosition else { return }
        let nodesAtLocation = nodes(at: draggedNode.position)
        
        if let slot = nodesAtLocation.first(where: { $0.name?.contains("slot") == true }),
           let slotName = slot.name,
           let index = Int(slotName.split(separator: "_").last!) {
            
            // 1. Place the visual item in the slot
            let placedItem = SKSpriteNode(imageNamed: draggedNode.name!)
            placedItem.size = CGSize(width: 80, height: 80)
            placedItem.position = slot.position
            placedItem.name = "placed_item"
            placedItem.zPosition = 8
            // Store the name of the source button so we can find it later to reset
            placedItem.userData = ["sourceButton": draggedNode.name!]
            addChild(placedItem)
            
            // 2. HIDE the original draggable button at the bottom
            draggedNode.isHidden = true // This makes it disappear from the dock
            draggedNode.position = original
            
            // 3. Update data and check win
            viewModel?.slots[index] = draggedNode.name
            viewModel?.checkWinCondition()
            
            SoundManager.shared.playSoundEffect(named: "completetask_0")
            
        } else {
            // If they missed the slot, move it back and keep it visible
            draggedNode.run(SKAction.move(to: original, duration: 0.2))
        }
        
        self.draggedNode = nil
    }
    
    func handleFailure() {
        
        SoundManager.shared.playSoundEffect(named: "error_buzz")
        
        SoundManager.shared.startBackgroundMusic(track: .mainMap)
        
        // 1. Visual feedback (Flash & Shake)
        let flash = SKSpriteNode(color: .red, size: self.size)
        flash.position = CGPoint(x: frame.midX, y: frame.midY)
        flash.alpha = 0
        flash.zPosition = 100
        addChild(flash)
        
        let group = SKAction.group([
            SKAction.fadeAlpha(to: 0.5, duration: 0.1),
            SKAction.sequence([
                SKAction.moveBy(x: -15, y: 0, duration: 0.05),
                SKAction.moveBy(x: 30, y: 0, duration: 0.05),
                SKAction.moveBy(x: -15, y: 0, duration: 0.05)
            ])
        ])
        
        run(SKAction.sequence([group, SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()])) { [weak self] in
            // 1. Reset the slots first
            self?.viewModel?.slots = [nil, nil, nil, nil]
            
            // 2. Exit the minigame scene
            self?.exitMiniGame()
            
            // 3. IMPORTANT: Use a tiny delay to ensure the Main Scene has finished
            // its 'didMove' logic before we push the failure message.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.viewModel?.currentMessage = "Incorrect order! You failed to build the nest."
            }
        }
    }
}

