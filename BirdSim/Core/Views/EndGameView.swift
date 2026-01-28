//
//  EndGameView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 1/28/26.
//

import SpriteKit

class EndGameScene: SKScene {
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "Game over"
        label.fontSize = 40
        label.fontColor = .white
        label.position = CGPoint(x: frame.midX, y: frame.midY + 50)
        addChild(label)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // transition back to start menu
    
        
    }
    

    
}
