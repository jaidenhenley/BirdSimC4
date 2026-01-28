//
//  EndGameView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 1/28/26.
//

import SpriteKit

class EndGameScene: SKScene {
    var gameDelegate: GameDelegate?

    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "Game over"
        label.fontSize = 40
        label.fontColor = .white
        label.position = CGPoint(x: frame.midX, y: frame.midY + 50)
        label.name = "GameOver"
        addChild(label)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // transition back to start menu
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if node.name == "GameOver" {
                gameDelegate?.dismissGame()
                print("Node touched")
            }
        }
    }
     

    
}
