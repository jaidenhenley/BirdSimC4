//
//  PhysicsCategory.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import Foundation

struct PhysicsCategory { // Physics for male bird
    static let none:   UInt32 = 0
    static let player: UInt32 = 0b1      // 1
    static let mate:   UInt32 = 0b10     // 2
    static let nest:   UInt32 = 0b100    // 4
    static let baby:   UInt32 = 0b1000   // 8
}
