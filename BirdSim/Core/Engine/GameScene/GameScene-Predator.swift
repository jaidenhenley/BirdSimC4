//
//  GameScene-Predator.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {
    
    // Returns true if the player is within threshold of any predator node
    func isPlayerNearAnyPredator(player: SKNode, threshold: CGFloat = 200) -> Bool {
        for node in children where node.name == predatorMini {
            let dx = player.position.x - node.position.x
            let dy = player.position.y - node.position.y
            let distance = sqrt(dx*dx + dy*dy)
            if distance < threshold {
                return true
            }
        }
        return false
    }
    
    func createRandomPredatorSpawn() -> CGPoint {
        guard let background = self.childNode(withName: "background") as? SKSpriteNode else {
            return .zero
        }

        let halfWidth = background.size.width / 2
        let halfHeight = background.size.height / 2

        let randomX = CGFloat.random(in: -halfWidth...halfWidth)
        let randomY = CGFloat.random(in: -halfHeight...halfHeight)

        return CGPoint(x: randomX, y: randomY)
    }
    
    // Returns a random free spawn index, or nil if all are occupied or banned
    func nextAvailablePredatorSpawnIndex() -> Int? {
        let available = (0..<predatorSpawnPoints.count).filter { !occupiedPredatorSpawns.contains($0) && !bannedPredatorSpawns.contains($0) }
        return available.randomElement()
    }
    
    // Spawns a predator at a free spot and marks it occupied.
    @discardableResult
    
    
    func spawnPredatorAtAvailableSpot() -> Bool {
        guard let index = nextAvailablePredatorSpawnIndex(),
              let background = self.childNode(withName: "background") as? SKSpriteNode else { return false }

        // Compute random point inside map bounds
        let halfWidth = background.size.width / 2
        let halfHeight = background.size.height / 2

        let randomX = CGFloat.random(in: -halfWidth...halfWidth)
        let randomY = CGFloat.random(in: -halfHeight...halfHeight)
        let position = CGPoint(x: randomX, y: randomY)

        occupiedPredatorSpawns.insert(index)
        setupPredator(at: position, spawnIndex: index, assetName: randomPredatorAsset())
        return true
    }
    
    func removePredator(_ node: SKNode, banSpawn: Bool = true) {
        if let idx = node.userData?["spawnIndex"] as? Int {
            occupiedPredatorSpawns.remove(idx)
            if banSpawn {
                bannedPredatorSpawns.insert(idx)
            }
        }
        node.removeFromParent()
    }
    
    func closestPredator(to player: SKNode, within threshold: CGFloat) -> SKNode? {
        var closest: SKNode?
        var closestDist = threshold
        for node in children where node.name == predatorMini {
            let dx = player.position.x - node.position.x
            let dy = player.position.y - node.position.y
            let dist = sqrt(dx*dx + dy*dy)
            if dist < closestDist {
                closestDist = dist
                closest = node
            }
        }
        return closest
    }
    
    func setupPredator(at position: CGPoint? = nil, spawnIndex: Int? = nil, assetName: String) {
        let predator = SKSpriteNode(imageNamed: assetName)
        predator.position = position ?? CGPoint(x: 120, y: 150)
        predator.zPosition = 4
        predator.size = CGSize(width: 150, height: 150)
        predator.name = predatorMini

        if predator.userData == nil { predator.userData = [:] }
        if let idx = spawnIndex {
            predator.userData?["spawnIndex"] = idx
        }
        predator.userData?["lastX"] = NSNumber(value: Double(predator.position.x))

        // Face right initially
        predator.xScale = abs(predator.xScale)
        predator.zRotation = -(.pi / 2)

        // Simple back-and-forth motion. Facing is handled per-frame by `updatePredatorFacingDirections()`.
        let moveRight = SKAction.moveBy(x: 4000, y: 0, duration: 12)
        let moveLeft  = moveRight.reversed()
        let sequence = SKAction.sequence([moveRight, moveLeft])
        predator.run(SKAction.repeatForever(sequence))
        addChild(predator)
    }
    func randomPredatorAsset() -> String {
        let assetName: [String] = [
            "Predator/Predator_1",
            "Predator/Predator_2",
            "Predator/Predator_3"
        ]
        
        let randomAsset = assetName.randomElement()
        
        return randomAsset!
    }
    
    func removeAllPredators() {
        for node in children where node.name == predatorMini {
            node.removeFromParent()
        }
        occupiedPredatorSpawns.removeAll()
    }
    
    func startPredatorCooldown(duration: TimeInterval = 5.0) {
        predatorHit = true
        predatorCooldownEnd = Date().addingTimeInterval(duration)
    }
    
    // Scene transition helpers for minigames.
    func transitionToPredatorGame(triggeringPredator predator: SKNode) {
        guard let view = self.view else { return }
        saveReturnState()
        removePredator(predator, banSpawn: true)
        startPredatorCooldown(duration: 5.0)
        viewModel?.controlsAreVisable = false
        // Removed these lines as per instructions:
        // self.childNode(withName: predatorMini)?.removeFromParent()
        // startPredatorTimer()
        let minigameScene = PredatorGame(size: view.bounds.size)
        minigameScene.scaleMode = .resizeFill
        minigameScene.viewModel = self.viewModel
        minigameScene.dismissAction = { [weak self] in
            DispatchQueue.main.async {
                self?.viewModel?.showGameOver = true
                self?.viewModel?.controlsAreVisable = false
            }
        }
        
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(minigameScene, transition: transition)
    }

    
    /// Makes every predator flip to face the direction it is moving.
    /// We track the last X position in `userData` and compare it each frame.
    ///
    /// NOTE: We search recursively (`//`) so this works even if predators are under `worldNode`.
    func updatePredatorFacingDirections() {
        enumerateChildNodes(withName: "//\(predatorMini)") { node, _ in
            guard let predator = node as? SKSpriteNode else { return }

            if predator.userData == nil { predator.userData = [:] }

            let currentX = predator.position.x
            let lastXNumber = predator.userData?["lastX"] as? NSNumber
            let lastX = lastXNumber.map { CGFloat($0.doubleValue) } ?? currentX

            let dx = currentX - lastX
 
            // Small threshold prevents rapid flipping from tiny jitter
            if dx > 0.5 {
                predator.zRotation = -(.pi / 2)
            } else if dx < -0.5 {
                predator.zRotation = .pi / 2
            }

            predator.userData?["lastX"] = NSNumber(value: Double(currentX))
        }
    }
    
    // Called after SpriteKit has evaluated SKActions for this frame.
    // We must flip here (not in `update`) because action-driven movement hasn't been applied yet during `update`.
    override func didEvaluateActions() {
        super.didEvaluateActions()
        updatePredatorFacingDirections()
    }

}
