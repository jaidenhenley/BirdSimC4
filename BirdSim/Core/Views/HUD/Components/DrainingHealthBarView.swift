//
//  HealthBarView.swift
//  BirdSim
//
//  Created by George Clinkscales on 1/27/26.
//

import SwiftUI
import Combine

struct DrainingHealthBarView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
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
                            .frame(width: max(0, min(1, viewModel.health)) * 300, height: 20)
                            .foregroundColor(viewModel.health > 0.6 ? .green : (viewModel.health > 0.3 ? .yellow : .red))
                    }
                    Text("Health: \(Int(viewModel.health * 100))%")
                        .font(.caption.monospacedDigit())
                }
                
               
            }
        }
    }
}

