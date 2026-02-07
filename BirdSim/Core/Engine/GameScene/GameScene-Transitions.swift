//
//  GameScene-Transitions.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {
    // Scene transition helpers for minigames.
    func transitionToLeaveIslandMini() {
        guard let view = self.view else { return }
        saveReturnState()
        let minigameScene = LeaveIslandScene(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.viewModel = self.viewModel
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(minigameScene, transition: transition)
    }
    
    
    // Scene transition helpers for minigames.
    func transitionToBuildNestScene() {
        guard let vm = viewModel, let view = self.view else { return }
        
        // 1. Prepare UI
        vm.controlsAreVisable = false
        vm.mapIsVisable = false

        saveReturnState()
        
        // 2. Clear the items BEFORE moving (Consuming the materials)
        vm.collectedItems.removeAll()
        
        // 3. Initialize and transition
        let minigameScene = BuildNestScene(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.viewModel = vm
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(minigameScene, transition: transition)
        
        print("Transitioning to Nest Scene...")
    }
    
    // Scene transition helpers for minigames.
    func transitionToFeedUserScene() {
        guard let view = self.view else { return }
        saveReturnState()
        let minigameScene = FeedUserScene(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.viewModel = self.viewModel
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(minigameScene, transition: transition)
    }
    
    func transitionToFeedBabyScene() {
        guard let view = self.view else { return }

        saveReturnState()
        let minigameScene = FeedBabyScene(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.viewModel = self.viewModel

        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(minigameScene, transition: transition)
    }

    

}
