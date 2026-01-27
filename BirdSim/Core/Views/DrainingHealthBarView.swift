//
//  HealthBarView.swift
//  BirdSim
//
//  Created by George Clinkscales on 1/27/26.
//

import SwiftUI
import Combine

struct DrainingHealthBarView: View {
    
    @State private var  health: CGFloat = 1.0
    @State private var healthWidth: CGFloat = 300
    let drainSpeed: CGFloat = 0.05
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 10) {
            
    
            ZStack(alignment: .leading){
                // Background (Gray track)
                VStack{
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 300, height: 20)
                            .foregroundStyle(.gray)
                        // Foreground (The "Health")
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: healthWidth, height: 20)
                            .foregroundColor(health > 0.6 ? .green : (health > 0.3 ? .yellow : .red))
                        // Smooths out the bar movement
                            .animation(.linear(duration: 1.0), value: health)
                    }
                    Text("Hunger: \(Int(health * 100))%")
                        .font(.caption.monospacedDigit())
                }
                
               
            }
            .onReceive(timer){ _ in
                if health > 0 {
                    health -= drainSpeed
                    healthWidth -= drainSpeed * 300
                }
            }
        }
    }
}

#Preview {
    DrainingHealthBarView()
}
