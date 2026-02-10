//
//  GameScene-Map.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit
import GameController

extension GameScene {
    
    // --- Keyboard State Tracking ---
    // Using a static variable to track the toggle state across frames
    private static var lastMKeyState: Bool = false

    /// Monitors keyboard input to toggle map mode with the 'M' key
    /// This MUST be called in the main GameScene's update(_:) method.
    func handleKeyboardMapInput() {
        if let keyboard = GCKeyboard.coalesced?.keyboardInput {
            // GCKeyCode.keyM is the correct member for the 'M' key
            let isMPressed = keyboard.button(forKeyCode: .keyM)?.isPressed ?? false
            
            // Only trigger the toggle when the key is first pressed (transition from false to true)
            if isMPressed && !GameScene.lastMKeyState {
                if viewModel?.isMapMode == true {
                    exitMapMode()
                } else {
                    enterMapNode()
                }
            }
            // Update the state tracker for the next frame
            GameScene.lastMKeyState = isMPressed
        }
    }

    // --- Camera & Map Constraints ---

    func clampCameraToMap() {
        guard let camera = self.camera,
              let background = self.childNode(withName: "background") as? SKSpriteNode,
              let view = self.view else { return }
        
        let halfWidth = (view.bounds.width * 0.5) * camera.xScale
        let halfHeight = (view.bounds.height * 0.5) * camera.yScale
        
        let mapRect = CGRect(
            x: background.position.x - background.size.width/2,
            y: background.position.y - background.size.height/2,
            width: background.size.width,
            height: background.size.height
        )
        
        var pos = camera.position
        pos.x = max(mapRect.minX + halfWidth, min(pos.x, mapRect.maxX - halfWidth))
        pos.y = max(mapRect.minY + halfHeight, min(pos.y, mapRect.maxY - halfHeight))
        camera.position = pos
    }
    
    func clampPlayerToMap() {
        guard let player = self.childNode(withName: "userBird"),
              let background = self.childNode(withName: "background") as? SKSpriteNode else { return }
        
        let halfWidth = background.size.width / 2
        let halfHeight = background.size.height / 2
        
        let minX = background.position.x - halfWidth
        let maxX = background.position.x + halfWidth
        let minY = background.position.y - halfHeight
        let maxY = background.position.y + halfHeight
        
        player.position.x = max(minX, min(player.position.x, maxX))
        player.position.y = max(minY, min(player.position.y, maxY))
    }
    
    // --- Map Mode Logic ---

    func zoomToFitMap() {
        // Ensure the node is actually named "background" in your scene editor
        guard let background = childNode(withName: "background") as? SKSpriteNode,
              let view = self.view else { return }
        
        let scaleX = view.bounds.width / background.size.width
        let scaleY = view.bounds.height / background.size.height
        
        // Calculate the zoom level to fit the entire background sprite
        let zoom = min(scaleX, scaleY)
        self.camera?.setScale(1 / zoom)
    }
    
    func enterMapNode() {
        viewModel?.isMapMode = true
        viewModel?.controlsAreVisable = false
        viewModel?.joystickVelocity = .zero

        
        HapticManager.shared.trigger(.light)
        
        guard let background = childNode(withName: "background") else {
            print("Error: Background node not found")
            return
        }
        
        // Center camera and zoom
        self.camera?.position = background.position
        zoomToFitMap()
        
        showPlayerMarker()
    }
    
    func exitMapMode() {
        viewModel?.isMapMode = false
        viewModel?.controlsAreVisable = true
        
        HapticManager.shared.trigger(.light)
        
        childNode(withName: "mapMarker")?.removeFromParent()
        
        if let player = childNode(withName: "userBird") {
            self.camera?.position = player.position
            self.camera?.setScale(1.25)
        }
    }
    
    func showPlayerMarker() {
        guard let player = childNode(withName: "userBird") else { return }
        
        let marker = SKShapeNode(circleOfRadius: 40)
        marker.fillColor = .orange
        marker.strokeColor = .white
        marker.lineWidth = 4
        marker.name = "mapMarker"
        marker.zPosition = 1000
        marker.position = player.position
        
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        marker.run(SKAction.repeatForever(pulse))
        
        addChild(marker)
    }
}

// --- Physics Categories ---

struct PhysicsCategory {
    static let none:   UInt32 = 0
    static let player: UInt32 = 0b1
    static let mate:   UInt32 = 0b10
    static let nest:   UInt32 = 0b100
    static let baby:   UInt32 = 0b1000
}
