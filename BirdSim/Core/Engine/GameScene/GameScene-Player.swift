//
//  GameScene-PlayerState.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit
import GameController

extension GameScene {
    // MARK: - Player State
    // Applies visual & gameplay changes when switching flying/ground modes.
    // - Updates speed and default texture.
    // - Stops ground-walk animation when entering flight.
    // - Cross-fades the texture and plays a subtle scale pulse.
    func applyBirdState(isFlying: Bool) {
        // Adjust movement speed
        playerSpeed = isFlying ? 650.0 : 400.0

        // Choose the "base" texture for the new state
        birdImage = isFlying ? "Bird_Flying_Open" : "Bird_Ground_Right"

        // If we just entered flight, ensure we are not running the ground walk animation.
        if isFlying, let bird = self.childNode(withName: "userBird") as? SKSpriteNode {
            stopWalking(bird)
        }

        // Cross-fade to the new texture so state changes feel smooth.
        crossFadeBirdTexture(to: birdImage, duration: 0.15)

        // Subtle scale pulse around the target scale (tiny feedback that state changed).
        if let bird = self.childNode(withName: "userBird") as? SKSpriteNode {
            let finalScale: CGFloat = isFlying ? 1.1 : 1.0
            let pulseUp = SKAction.scale(to: finalScale * 1.06, duration: 0.08)
            pulseUp.timingMode = .easeOut
            let pulseDown = SKAction.scale(to: finalScale, duration: 0.12)
            pulseDown.timingMode = .easeIn
            bird.run(SKAction.sequence([pulseUp, pulseDown]), withKey: "statePulse")
        }
    }
    

    // MARK: - Player Movement and Distance Check
    // Moves the player based on joystick or controller input.
    // - Uses a deadzone so tiny joystick drift doesn't move the character.
    // - Keeps speed consistent by clamping the input vector to the unit circle.
    // - Rotates the bird to face its movement direction (with exponential damping).
    func updatePlayerPosition(deltaTime: CGFloat) {
        guard let player = self.childNode(withName: "userBird") as? SKSpriteNode else { return }

        // In map mode, we prevent walking animation and don't process movement here.
        if viewModel?.isMapMode == true {
            stopWalking(player)
            return
        }

        // Prefer SwiftUI joystick via view model (CGPoint normalized to [-1, 1])
        var inputPoint: CGPoint = viewModel?.joystickVelocity ?? .zero

        // Fallback to virtual controller if SwiftUI joystick is idle
        if inputPoint == .zero,
           let xValue = virtualController?.controller?.extendedGamepad?.leftThumbstick.xAxis.value,
           let yValue = virtualController?.controller?.extendedGamepad?.leftThumbstick.yAxis.value {
            inputPoint = CGPoint(x: CGFloat(xValue), y: CGFloat(yValue))
        }

        // Convert to vector components
        var dx = inputPoint.x
        var dy = inputPoint.y

        // Determine if the joystick is actively moving (deadzone)
        let rawMag = sqrt(dx * dx + dy * dy)
        let isMoving = rawMag > joystickDeadzone

        // MARK: Walk Animation Gating
        // Only show the ground-walk animation when:
        // - we're NOT flying, and
        // - the input magnitude is above the deadzone.
        let isFlyingNow = viewModel?.isFlying ?? false
        if isFlyingNow {
            stopWalking(player)
        } else {
            if isMoving {
                startWalking(player, speed: rawMag)
            } else {
                stopWalking(player)
            }
        }

        // Clamp to unit circle for consistent speed
        var mag = rawMag
        if mag > 1.0 {
            dx /= mag
            dy /= mag
            mag = 1.0
        }

        // Convert input to a velocity in world units
        let velocity: CGVector = isMoving
            ? CGVector(dx: dx * playerSpeed, dy: dy * playerSpeed)
            : .zero

        // Apply movement
        player.position.x += velocity.dx * deltaTime
        player.position.y += velocity.dy * deltaTime

        // Rotate the bird to face movement direction (smooth + frame-rate independent)
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        if speed > 0.001 {
            let target = atan2(velocity.dy, velocity.dx)

            // Your texture appears oriented "up" by default, so we offset by -90 degrees
            let assetOrientationOffset: CGFloat = -(.pi / 2)
            let desired = target + assetOrientationOffset

            let current = player.zRotation
            let deltaAngle = atan2(sin(desired - current), cos(desired - current))

            // Exponential damping for stable smoothing across different frame rates
            let turnStiffness: CGFloat = 12.0  // higher = snappier
            let rotationFactor = 1 - exp(-turnStiffness * deltaTime)

            player.zRotation = current + deltaAngle * rotationFactor
        }
    }
    
    // Single distance check function to reduce code duplication
    // Proximity-based interaction messages
    func checkDistance(to nodeName: String, threshold: CGFloat = 200) -> Bool {
        
        guard let player = self.childNode(withName: "userBird") as? SKSpriteNode else { return false }
        // Special-case baby because it lives under the nest.
        if nodeName == "babyBird", let baby = babyBirdNode() {
            // Convert the baby's center (zero) to the scene's coordinate system
            let babyWorldPos = baby.convert(CGPoint.zero, to: self)
            let dx = player.position.x - babyWorldPos.x
            let dy = player.position.y - babyWorldPos.y
            return sqrt(dx*dx + dy*dy) < threshold
        }

        guard let node = self.childNode(withName: nodeName) else { return false }
        let dx = player.position.x - node.position.x
        let dy = player.position.y - node.position.y
        return sqrt(dx*dx + dy*dy) < threshold
    }

    
    // MARK: Player Spawn
    func setupUserBird() {
        if self.childNode(withName: "userBird") != nil { return }
        
        let player = SKSpriteNode(imageNamed: birdImage)
        let shadow = SKSpriteNode(imageNamed: birdImage)
        
        player.size = CGSize(width: 100, height: 100)
        player.position = defaultPlayerStartPosition
        player.zPosition = 10
        player.name = "userBird"
        
        shadow.size = CGSize(width: 100, height: 100)
        shadow.color = .black
        shadow.colorBlendFactor = 1.0
        shadow.alpha = 0.3
        shadow.zPosition = -1 // relative to player
        shadow.position = CGPoint(x: 0, y: -8)
        
        player.addChild(shadow)
        
        // --- ADD PHYSICS HERE ---
        // Create a circular physics body slightly smaller than the bird for "fair" collisions
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width * 0.4)
        
        // 'isDynamic' must be true for the bird to trigger contact events while moving
        player.physicsBody?.isDynamic = true
        
        // Turn off gravity so your bird doesn't fall off the screen
        player.physicsBody?.affectedByGravity = false
        
        // Assign its identity
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        
        // Tell it to "report" hits with the male bird and baby bird
        player.physicsBody?.contactTestBitMask = PhysicsCategory.mate | PhysicsCategory.baby
        
        // 'collisionBitMask' at .none ensures you fly THROUGH the male bird instead of bouncing off
        player.physicsBody?.collisionBitMask = PhysicsCategory.none
        // -------------------------
        
        self.addChild(player)
    }
    
    func crossFadeBirdTexture(to imageName: String, duration: TimeInterval = 0.15) {
        // If the bird doesn't exist yet, create it with the target texture
        guard let existing = self.childNode(withName: "userBird") as? SKSpriteNode else {
            let node = SKSpriteNode(imageNamed: imageName)
            node.name = "userBird"
            node.zPosition = 10
            addChild(node)
            return
        }
        
        // Avoid work if the texture already matches
        if let tex = existing.texture, tex.description.contains(imageName) {
            return
        }
        
        let newTexture = SKTexture(imageNamed: imageName)
        SKTexture.preload([newTexture]) { [weak self] in
            guard let self = self,
                  let bird = self.childNode(withName: "userBird") as? SKSpriteNode else { return }
            DispatchQueue.main.async {
                // Remove any previous temp overlay
                self.childNode(withName: "userBird_crossfade_temp")?.removeFromParent()
                
                // Create an overlay sprite with the new texture, matching the bird's transform and size
                let overlay = SKSpriteNode(texture: newTexture)
                overlay.name = "userBird_crossfade_temp"
                overlay.position = bird.position
                overlay.zPosition = bird.zPosition + 1
                overlay.zRotation = bird.zRotation
                overlay.anchorPoint = bird.anchorPoint
                overlay.size = bird.size
                overlay.xScale = bird.xScale
                overlay.yScale = bird.yScale
                overlay.alpha = 0
                self.addChild(overlay)
                
                let fadeIn = SKAction.fadeIn(withDuration: duration)
                let fadeOut = SKAction.fadeOut(withDuration: duration)
                
                bird.run(fadeOut, withKey: "crossfadeOut")
                overlay.run(fadeIn, completion: { [weak self] in
                    guard let self = self,
                          let bird = self.childNode(withName: "userBird") as? SKSpriteNode else { return }
                    bird.texture = newTexture
//                    bird.size = newTexture.size()
                    bird.alpha = 1.0
                    overlay.removeFromParent()
                })
            }
        }
    }
    
    func adjustPlayerScale(by delta: CGFloat) {
        guard let circle = self.childNode(withName: "userBird") as? SKShapeNode else { return }
        
        let targetScale = max(0.7, min(1.1, circle.xScale + delta))
        
        guard abs(targetScale - circle.xScale) > .ulpOfOne else { return }
        
        // Stop any in-flight scale animation to avoid stacking
        circle.removeAction(forKey: "scaleEase")
        
        // Animate scale with ease-in-out timing
        let duration: TimeInterval = 1
        let scaleAction = SKAction.scale(to: targetScale, duration: duration)
        scaleAction.timingMode = .easeInEaseOut
        circle.run(scaleAction, withKey: "scaleEase")
        
    }


}
