//
//  GameScene-Map.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {
    // Prevents the camera from leaving the map bounds.
    func clampCameraToMap() {
        guard let camera = camera,
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
    
    // Prevents the player from leaving the map bounds.
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
    
    func zoomToFitMap() {
        guard let backgroud = childNode(withName: "background") as? SKSpriteNode,
              let view = self.view else { return }
        
        let scaleX = view.bounds.width / backgroud.size.width
        let scaleY = view.bounds.height / backgroud.size.height
        
        let zoom = min(scaleX, scaleY)
        cameraNode.setScale(1 / zoom)
    }
    
    func enterMapNode() {
        viewModel?.isMapMode = true
        viewModel?.controlsAreVisable = false
        viewModel?.joystickVelocity = .zero

        
        guard let background = childNode(withName: "background") else { return }
        // center camera on map
        cameraNode.position = background.position
        // zoom out
        zoomToFitMap()
        // add player marker
        showPlayerMarker()
    }
    
    func exitMapMode() {
        viewModel?.isMapMode = false
        viewModel?.controlsAreVisable = true
        
        // Remove marker
        childNode(withName: "mapMarker")?.removeFromParent()
        
        // Snap camera back to player
        if let player = childNode(withName: "userBird") {
            cameraNode.position = player.position
            cameraNode.setScale(1.25) // your normal zoom
        }
    }
    
    func showPlayerMarker() {
        guard let player = childNode(withName: "userBird") else { return }
        
        let marker = SKShapeNode(circleOfRadius: 40)
        marker.fillColor = .orange
        marker.strokeColor = .clear
        marker.name = "mapMarker"
        marker.zPosition = 1000
        marker.position = player.position
        addChild(marker)
    }
}

struct PhysicsCategory { // Physics for male bird
    static let none:   UInt32 = 0
    static let player: UInt32 = 0b1      // 1
    static let mate:   UInt32 = 0b10     // 2
    static let nest:   UInt32 = 0b100    // 4
    static let baby:   UInt32 = 0b1000   // 8
}

