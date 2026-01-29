//
//  GameViewModel.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/21/26.
//

import Combine
import SwiftUI
import SpriteKit


extension MainGameView {
    
    
  
    class ViewModel: ObservableObject {
        @Published var joystickVelocity: CGPoint = .zero
        @Published var pendingScaleDelta: CGFloat = 0
        @Published var isFlying: Bool = false
        @Published var controlsAreVisable: Bool = true
        @Published var savedPlayerPosition: CGPoint?
        @Published var savedCameraPosition: CGPoint?
        @Published var mainScene: GameScene?
        @Published var health: CGFloat = 1
        @Published var showInventory: Bool = false
        @Published var inventory: [String: Int] = ["stick": 0, "leaf": 0]
        @Published var gameStarted: Bool = false
        @Published var showGameOver: Bool = false
        
        func collectItem(_ name: String) {
                // Standardize to lowercase to match node names
                let key = name.lowercased()
                if inventory.keys.contains(key) {
                    inventory[key, default: 0] += 1
                }
            }
        
    }
    
}

protocol GameDelegate {
    func dismissGame()
}

extension MainGameView: GameDelegate {
    func dismissGame() {
        viewModel.gameStarted = false
    }
}
