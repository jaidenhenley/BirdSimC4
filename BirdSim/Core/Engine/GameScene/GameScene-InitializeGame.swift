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
    func initializeGame(resetState: Bool = false, tutorialOn: Bool) {
        viewModel?.joystickVelocity = .zero
        
        if viewModel?.tutorialIsOn == true {
            viewModel?.showMainGameInstructions(type: .hunger)
        }
        
        if resetState {
            viewModel?.controlsAreVisable = true
            viewModel?.showGameWin = false
            viewModel?.savedCameraPosition = nil
            viewModel?.savedPlayerPosition = nil
            viewModel?.hunger = 5
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
        
        if tutorialOn {
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                var spawned = 0
                while spawned < min(self.desiredPredatorCount, self.predatorSpawnPoints.count) && self.spawnPredatorAtAvailableSpot() {
                    spawned += 1
                }
            }
        } else {
            // Spawn up to desiredPredatorCount unique predators
            var spawned = 0
            while spawned < min(desiredPredatorCount, predatorSpawnPoints.count) && spawnPredatorAtAvailableSpot() {
                spawned += 1
            }
        }
        setupBuildNestTree(in: CGPoint(x: -200, y: 0))
        setupBuildNestTree(in: CGPoint(x: -2000, y: 1100))
        setupBuildNestTree(in: CGPoint(x: -1600, y: -1000))
        setupBuildNestTree(in: CGPoint(x: 2900, y: -180))
        setupBuildNestTree(in: CGPoint(x: 1709, y: 378))

        setupFeedUserBirdSpot(in: CGPoint(x: 180, y: -1600))
        setupFeedUserBirdSpot(in: CGPoint(x: -3000, y: 100))
        setupFeedUserBirdSpot(in: CGPoint(x: 1621, y: 1539))


        setupLeaveIslandSpot()
        
        spawnItem(at: CGPoint(x: 400, y: 100), type: "leaf")
        spawnItem(at: CGPoint(x: 200, y: 100), type: "stick")
        spawnItem(at: CGPoint(x: -600, y: 100), type: "stick")
        spawnItem(at: CGPoint(x: -400, y: 300), type: "leaf")
        spawnItem(at: CGPoint(x: -700, y: 400), type: "spiderweb")
        spawnItem(at: CGPoint(x: 700, y: 200), type: "spiderweb")
        spawnItem(at: CGPoint(x: -500, y: 200), type: "dandelion")
        spawnItem(at: CGPoint(x: -4500, y: 300), type: "dandelion")
        
        
        //Spawns building
        spawnItem(at: CGPoint(x: -1650, y: -1100), type: "aquarium")
        spawnItem(at: CGPoint(x: -500, y: -1100), type: "casino")
        spawnItem(at: CGPoint(x: -865, y: 1000), type: "fountain")

        
        
        //Spawns the path
        
        
        
        spawnItem(at: CGPoint(x: -450, y: -1313), type: "stonePath")
        spawnItem(at: CGPoint(x: -550, y: -1313), type: "stonePath")
        spawnItem(at: CGPoint(x: -650, y: -1313), type: "stonePath")
        spawnItem(at: CGPoint(x: -750, y: -1313), type: "stonePath")
        spawnItem(at: CGPoint(x: -850, y: -1313), type: "stonePath")
        spawnItem(at: CGPoint(x: -950, y: -1313), type: "stonePath")
        
        spawnItem(at: CGPoint(x: -950, y: -1213), type: "stonePath")
        spawnItem(at: CGPoint(x: -950, y: -1113), type: "stonePath")
        spawnItem(at: CGPoint(x: -950, y: -1013), type: "stonePath")
        spawnItem(at: CGPoint(x: -950, y: -913), type: "stonePath")
        spawnItem(at: CGPoint(x: -950, y: -813), type: "stonePath")

        spawnItem(at: CGPoint(x: -1050, y: -1313), type: "stonePath")
        spawnItem(at: CGPoint(x: -1150, y: -1313), type: "stonePath")
        spawnItem(at: CGPoint(x: -1250, y: -1313), type: "stonePath")
        
        spawnItem(at: CGPoint(x: -1350, y: -1313), type: "stonePath")
        spawnItem(at: CGPoint(x: -1450, y: -1313), type: "stonePath")
        spawnItem(at: CGPoint(x: -1550, y: -1313), type: "stonePath")
        spawnItem(at: CGPoint(x: -1650, y: -1313), type: "stonePath")
        spawnItem(at: CGPoint(x: -1750, y: -1313), type: "stonePath")
        spawnItem(at: CGPoint(x: -1850, y: -1313), type: "stonePath")
        spawnItem(at: CGPoint(x: -1950, y: -1313), type: "stonePath")

        
        
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
            
            if viewModel?.hasNest == true && viewModel?.hasFoundMale == false {
                spawnMaleBird()
            }
        }
    }
    
    func setupLeaveIslandSpot() {
        if self.childNode(withName: leaveIslandMini) != nil { return }
        let spot = SKSpriteNode(imageNamed: "bridge")
        spot.position = CGPoint(x: 0, y: -2150)
        spot.name = leaveIslandMini
        addChild(spot)
    }
    
    func setupBuildNestTree(in position: CGPoint) {
        let tree = SKSpriteNode(imageNamed: "tree1")
        tree.position = position
        tree.name = buildNestMini
        addChild(tree)
    }
    
    func setupFeedUserBirdSpot(in position: CGPoint) {
        let spot = SKSpriteNode(imageNamed: "caterpiller")
        spot.position = position
        spot.name = feedUserBirdMini
        spot.size = CGSize(width: 120, height: 120)
        addChild(spot)
    }
    
}
