//
//  Minigame1.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/22/26.
//

import SpriteKit

class PredatorGame: SKScene {
    var mainViewModel: MainGameViewModel?
    
    override func didMove(to view: SKView) {
        backgroundColor = .red
        
        let backLabel = SKLabelNode(text: "Mini Game active tap to go back")
        backLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        backLabel.fontColor = .white
        backLabel.fontSize = 28
        backLabel.name = "Back Button"
        backLabel.zPosition = 10
        addChild(backLabel)
    
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //add logic to go back to the map scene
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if node.name == "Back Button" {
                guard let view = self.view else { return }
                let mapScene = GameScene(size: view.bounds.size)
                mapScene.scaleMode = .resizeFill
                mapScene.viewModel = self.mainViewModel
                mainViewModel?.joystickVelocity = .zero
                mainViewModel?.controlsAreVisable = true
                let transition = SKTransition.crossFade(withDuration: 0.5)
                view.presentScene(mapScene, transition: transition)
            }
        }
    }
}

