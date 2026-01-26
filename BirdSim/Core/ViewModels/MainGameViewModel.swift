//
//  GameViewModel.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/21/26.
//

import Combine
import SwiftUI

class MainGameViewModel: ObservableObject {
    @Published var joystickVelocity: CGPoint = .zero
    @Published var pendingScaleDelta: CGFloat = 0
    @Published var isFlying: Bool = false
    @Published var controlsAreVisable: Bool = true
    @Published var savedPlayerPosition: CGPoint?
    @Published var savedCameraPosition: CGPoint?
    
}
