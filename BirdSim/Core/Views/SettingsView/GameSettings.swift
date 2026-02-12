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
    var soundOn: Bool = true
    var soundVolume: Double = 0.8
    var hapticsOn: Bool = true
    var tutorialOn: Bool = true
    
    init(soundOn: Bool = true, soundVolume: Double = 0.8, hapticsOn: Bool = true, tutorialOn: Bool = true) {
        self.soundOn = soundOn
        self.soundVolume = soundVolume
        self.hapticsOn = hapticsOn
        self.tutorialOn = tutorialOn
    }
    
}
