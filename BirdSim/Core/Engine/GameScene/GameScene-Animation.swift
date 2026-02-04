//
//  GameScene-Animation.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {
    // MARK: - Walk Animation
    // Creates a repeat-forever walk action where `speedMultiplier` (0..1)
    // affects how quickly we step between frames.
    private func makeWalkAction(speedMultiplier: CGFloat) -> SKAction {
        let minFrameTime: CGFloat = 0.30    // slower steps
        let maxFrameTime: CGFloat = 0.18    // faster steps

        // Clamp multiplier into a safe range
        let t = max(0.1, min(speedMultiplier, 1.0))

        // Linearly interpolate timePerFrame (lower time = faster animation)
        let frameTime = minFrameTime - (minFrameTime - maxFrameTime) * t

        let animate = SKAction.animate(
            with: walkFrames,
            timePerFrame: frameTime,
            resize: false,
            restore: false
        )

        return SKAction.repeatForever(animate)
    }

    // Starts (or updates) the ground-walk animation.
    // We avoid restarting the action every frame by only refreshing when
    // the speed meaningfully changes.
    func startWalking(_ player: SKSpriteNode, speed: CGFloat) {
        let didSpeedChange = abs((lastWalkSpeed ?? 0) - speed) > 0.05

        // Only start walking action if not already running OR speed changed significantly
        if player.action(forKey: walkKey) == nil || didSpeedChange {
            let walk = makeWalkAction(speedMultiplier: speed)
            player.removeAction(forKey: walkKey)
            player.run(walk, withKey: walkKey)
            lastWalkSpeed = speed
        }
    }

    // Stops the ground-walk animation and clears cached speed.
    func stopWalking(_ player: SKSpriteNode) {
        player.removeAction(forKey: walkKey)
        lastWalkSpeed = nil
    }


}
