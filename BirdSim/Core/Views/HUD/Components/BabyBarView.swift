//
//  BabyBarView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/9/26.
//

import SwiftUI

struct BabyBarView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel

    
    var body: some View {
        Text("Current Baby: \(viewModel.currentBabyAmount)")
    }
}

