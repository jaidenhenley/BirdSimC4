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
    
    // This connects the ViewModel's success to the Scene's transition
    // Inside BuildNestScene.swift
    override func didMove(to view: SKView) {
        // Success path
        viewModel?.onChallengeComplete = { [weak self] in
            self?.exitMiniGame()
        }
        
        // Failure path
        viewModel?.onChallengeFailed = { [weak self] in
            self?.handleFailure()
        }
        
        setupGame()
        showMemorizationPhase()
    }

    
   
    
    func exitMiniGame() {
        // Ensure all buttons are visible for the next session
            let items = ["stick", "leaf", "spiderweb"]
            for name in items {
                self.childNode(withName: name)?.isHidden = false
            }
        guard let view = self.view, let mainScene = viewModel?.mainScene else { return }
        
        // Bring back the main game buttons/joystick
        viewModel?.controlsAreVisable = true
        
        let transition = SKTransition.doorsOpenHorizontal(withDuration: 0.5)
        view.presentScene(mainScene, transition: transition)
    }
    
    // --- 1. SETUP THE INITIAL VIEW ---
    func setupGame() {
        backgroundColor = .systemBlue
        
        let backLabel = SKLabelNode(text: "EXIT MINI-GAME")
        backLabel.position = CGPoint(x: frame.midX - 100, y: 100) // Moved slightly left
        backLabel.fontName = "AvenirNext-Bold"
        backLabel.fontSize = 20
        backLabel.name = "Back Button"
        addChild(backLabel)
        
        
        
        viewModel?.startNewChallenge()
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
        // 1. The 3 Empty Slots (These Stay)
        for i in 0..<3 {
            let slot = SKShapeNode(rectOf: CGSize(width: 90, height: 90))
            slot.name = "slot_\(i)"
            slot.position = CGPoint(x: frame.midX + CGFloat(i - 1) * 110, y: frame.midY)
            slot.strokeColor = .white
            slot.fillColor = .clear // NO yellow circle
            addChild(slot)
        }
        
        // 2. The 3 Draggable Items at the bottom (These Stay)
        let items = ["stick", "leaf", "spiderweb"]
        for (index, name) in items.enumerated() {
            let draggable = SKSpriteNode(imageNamed: name)
            draggable.name = name
            draggable.size = CGSize(width: 70, height: 70)
            // Positioned at the BOTTOM of the screen
            draggable.position = CGPoint(x: frame.midX + CGFloat(index - 1) * 110, y: 200)
            draggable.zPosition = 10
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
        } else if ["stick", "leaf", "spiderweb"].contains(node.name) {
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
            // Store the name of the source button so we can find it later to reset
            placedItem.userData = ["sourceButton": draggedNode.name!]
            addChild(placedItem)
            
            // 2. HIDE the original draggable button at the bottom
            draggedNode.isHidden = true // This makes it disappear from the dock
            draggedNode.position = original
            
            // 3. Update data and check win
            viewModel?.slots[index] = draggedNode.name
            viewModel?.checkWinCondition()
            
        } else {
            // If they missed the slot, move it back and keep it visible
            draggedNode.run(SKAction.move(to: original, duration: 0.2))
        }
        
        self.draggedNode = nil
    }
    
    func handleFailure() {
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
            self?.viewModel?.slots = [nil, nil, nil]
            
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
