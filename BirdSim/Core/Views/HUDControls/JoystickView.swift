//
//  JoystickView.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/21/26.
//

import SwiftUI

struct JoystickView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    @State private var fingerLocation: CGPoint = .zero
    @State private var isDragging = false
    
    
    let radius: CGFloat
    
    
    var body: some View {
        ZStack {
            Circle() // Background
                .fill(.white.opacity(0.3))
                
            
            Circle() // Thumbstick
                .fill(.white.opacity(0.8))
                .frame(width: radius, height: radius)
                .offset(x: fingerLocation.x, y: fingerLocation.y)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true

                            let dx = value.translation.width
                            let dy = value.translation.height

                            // Clamp to joystick radius
                            let distance = hypot(dx, dy)
                            let angle = atan2(dy, dx)
                            let clamped = min(distance, radius)

                            // Knob position inside the base circle
                            let knob = CGPoint(x: cos(angle) * clamped, y: sin(angle) * clamped)
                            fingerLocation = knob

                            // Normalize and flip Y so up is positive in SpriteKit
                            viewModel.joystickVelocity = CGPoint(x: knob.x / radius, y: -knob.y / radius)
                        }
                        .onEnded  { _ in
                            isDragging = false
                            fingerLocation = .zero
                            viewModel.joystickVelocity = .zero
                        }
                )
            
            
        }
        .frame(width: radius * 2, height: radius * 2)
        .contentShape(Circle())
    }
}
