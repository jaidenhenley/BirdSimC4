//
//  GameSettings.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/6/26.
//

import Foundation
import SwiftData

@Model
class GameSettings {
    var soundOn: Bool
    var soundVolume: Double
    var hapticsOn: Bool
    
    init(soundOn: Bool, soundVolume: Double, hapticsOn: Bool) {
        self.soundOn = soundOn
        self.soundVolume = soundVolume
        self.hapticsOn = hapticsOn
        }
    
    }
