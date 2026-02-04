//
//  GameScene-Camera.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {
    
       // Smooth camera follow using exponential damping and dead zone.
       func updateCameraFollow(target: CGPoint, deltaTime: CGFloat) {
           // Exponential damping for smooth, frame-rate independent following
           let stiffness: CGFloat = 6.0   // higher = snappier, lower = smoother
           let deadZone: CGFloat = 20.0   // ignore tiny movements near the center
           
           let dx = target.x - cameraNode.position.x
           let dy = target.y - cameraNode.position.y
           
           // Apply dead zone to reduce jitter
           let tx = abs(dx) > deadZone ? dx : 0
           let ty = abs(dy) > deadZone ? dy : 0
           
           // Stable interpolation factor across frame rates
           let factor = 1 - exp(-stiffness * deltaTime)
           
           cameraNode.position.x += tx * factor
           cameraNode.position.y += ty * factor
       }

}
