//
//  UserScoreView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/3/26.
//

import SwiftUI

struct UserScoreView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    
    var body: some View {
        Text("\(viewModel.userScore)")
            .font(.system(size: 30))
    }
}
