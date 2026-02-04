//
//  GameScene-InitializeGame.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {
    // Initializes or resets the entire world state.
    // Spawns background, player, predators, items, and restores save state.
    func initializeGame(resetState: Bool = false) {
        viewModel?.joystickVelocity = .zero
        
        if resetState {
            viewModel?.showGameWin = false
            viewModel?.savedCameraPosition = nil
            viewModel?.savedPlayerPosition = nil
            viewModel?.health = 1
            viewModel?.isFlying = false
            viewModel?.gameStarted = true
            viewModel?.inventory = ["stick": 0, "leaf": 0, "spiderweb": 0,"dandelion": 0]
            viewModel?.collectedItems.removeAll()
            viewModel?.savedPlayerPosition = nil
            viewModel?.showGameWin = false
            viewModel?.clearNestAndBabyState()
            babySpawnTime = nil
        }
        
        self.removeAllChildren()
        
        setupBackground()
        setupUserBird()
        self.predatorHit = false
        self.predatorCooldownEnd = nil
        occupiedPredatorSpawns.removeAll()
        bannedPredatorSpawns.removeAll()
        // Spawn up to desiredPredatorCount unique predators
        var spawned = 0
        while spawned < min(desiredPredatorCount, predatorSpawnPoints.count) && spawnPredatorAtAvailableSpot() {
            spawned += 1
        }
        setupBuildNestSpot()
        setupFeedUserBirdSpot()
        setupFeedBabyBirdSpot()
        setupLeaveIslandSpot()
        
        spawnItem(at: CGPoint(x: 400, y: 100), type: "leaf")
        spawnItem(at: CGPoint(x: 200, y: 100), type: "stick")
        spawnItem(at: CGPoint(x: -600, y: 100), type: "stick")
        spawnItem(at: CGPoint(x: -400, y: 300), type: "leaf")
        spawnItem(at: CGPoint(x: -700, y: 400), type: "spiderweb")
        spawnItem(at: CGPoint(x: 700, y: 200), type: "spiderweb")
        spawnItem(at: CGPoint(x: -500, y: 200), type: "dandelion")
        spawnItem(at: CGPoint(x: -4500, y: 300), type: "dandelion")
        
        
        spawnItem(at: CGPoint(x: 900, y: 900), type: "tree1")

        // If we're resetting, force the player + camera back to defaults and
        // overwrite any previously persisted return state.
        if resetState {
            if let player = self.childNode(withName: "userBird") {
                player.position = defaultPlayerStartPosition
            }
            cameraNode.position = defaultPlayerStartPosition
            cameraNode.setScale(defaultCameraScale)

            viewModel?.savedPlayerPosition = defaultPlayerStartPosition
            viewModel?.savedCameraPosition = defaultPlayerStartPosition
        }
        
        hasInitializedWorld = true
        
        viewModel?.mainScene = self
        // Only restore persisted positions when NOT doing a full reset.
        if !resetState {
            restoreReturnStateIfNeeded()
            restorePersistedNestAndBaby()
        }
    }
    
    func setupLeaveIslandSpot() {
        if self.childNode(withName: leaveIslandMini) != nil { return }
        let spot = SKSpriteNode(color: .systemCyan, size: CGSize(width: 50, height: 50))
        spot.position = CGPoint(x: 200, y: -450)
        spot.name = leaveIslandMini
        addChild(spot)
    }
    
    func setupBuildNestSpot() {
        if self.childNode(withName: buildNestMini) != nil { return }
        let spot = SKSpriteNode(color: .blue, size: CGSize(width: 50, height: 50))
        spot.position = CGPoint(x: -200, y: -150)
        spot.name = buildNestMini
        addChild(spot)
    }
    
    func setupFeedUserBirdSpot() {
        if self.childNode(withName: feedUserBirdMini) != nil { return }
        let spot = SKSpriteNode(color: .green, size: CGSize(width: 50, height: 50))
        spot.position = CGPoint(x: -200, y: 150)
        spot.name = feedUserBirdMini
        addChild(spot)
    }
    
    func setupFeedBabyBirdSpot() {
        if self.childNode(withName: feedBabyBirdMini) != nil { return }
        let spot = SKSpriteNode(color: .yellow, size: CGSize(width: 50, height: 50))
        spot.position = CGPoint(x: 200, y: -150)
        spot.name = feedBabyBirdMini
        addChild(spot)
    }
}
