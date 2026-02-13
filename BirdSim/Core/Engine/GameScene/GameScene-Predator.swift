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

        // 1. Roll a "dice" to decide movement type (50% chance for vertical)
        let shouldMoveVertical = Bool.random()

        // 2. Pass that random result into your setup function
        setupPredator(at: position,
                      spawnIndex: index,
                      assetName: "Predator/Predator",
                      isVertical: shouldMoveVertical)

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
    
    func setupPredator(at position: CGPoint? = nil, spawnIndex: Int? = nil, assetName: String, isVertical: Bool) {
        let predator = SKSpriteNode(imageNamed: assetName)
        predator.position = position ?? CGPoint(x: 120, y: 150)
        predator.zPosition = 4
        predator.size = CGSize(width: 250, height: 250)
        predator.name = predatorMini

        if predator.userData == nil { predator.userData = [:] }
        
        // Store the movement type so the update function knows what to check
        predator.userData?["isVertical"] = isVertical
        predator.userData?["lastX"] = NSNumber(value: Double(predator.position.x))
        predator.userData?["lastY"] = NSNumber(value: Double(predator.position.y))

        let moveDist: CGFloat = 4000
        let duration: TimeInterval = 12

        if isVertical {
            // UP AND DOWN
            let moveUp = SKAction.moveBy(x: 0, y: moveDist, duration: duration)
            let moveDown = moveUp.reversed()
            predator.run(SKAction.repeatForever(SKAction.sequence([moveUp, moveDown])))
        } else {
            // LEFT AND RIGHT
            let moveRight = SKAction.moveBy(x: moveDist, y: 0, duration: duration)
            let moveLeft = moveRight.reversed()
            predator.run(SKAction.repeatForever(SKAction.sequence([moveRight, moveLeft])))
        }

        addChild(predator)
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
    
    /// Makes every predator flip to face the direction it is moving.
    /// We track the last X position in `userData` and compare it each frame.
    ///
    /// NOTE: We search recursively (`//`) so this works even if predators are under `worldNode`.
    func updatePredatorFacingDirections() {
        enumerateChildNodes(withName: "//\(predatorMini)") { node, _ in
            guard let predator = node as? SKSpriteNode else { return }
            let isVertical = predator.userData?["isVertical"] as? Bool ?? false

            if isVertical {
                let currentY = predator.position.y
                let lastY = (predator.userData?["lastY"] as? NSNumber)?.doubleValue ?? Double(currentY)
                let dy = currentY - CGFloat(lastY)

                if dy > 0.5 {
                    predator.zRotation = 0 // Facing Up
                } else if dy < -0.5 {
                    predator.zRotation = .pi // Facing Down
                }
                predator.userData?["lastY"] = NSNumber(value: Double(currentY))
            } else {
                let currentX = predator.position.x
                let lastX = (predator.userData?["lastX"] as? NSNumber)?.doubleValue ?? Double(currentX)
                let dx = currentX - CGFloat(lastX)

                if dx > 0.5 {
                    predator.zRotation = -(.pi / 2) // Facing Right
                } else if dx < -0.5 {
                    predator.zRotation = .pi / 2  // Facing Left
                }
                predator.userData?["lastX"] = NSNumber(value: Double(currentX))
            }
        }
    }
    
    // Called after SpriteKit has evaluated SKActions for this frame.
    // We must flip here (not in `update`) because action-driven movement hasn't been applied yet during `update`.
    override func didEvaluateActions() {
        super.didEvaluateActions()
        updatePredatorFacingDirections()
        updateMaleFacingDirections()
    }

}
