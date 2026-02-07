//
//  ToolbarButtonView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/6/26.
//

import SwiftUI
struct ToolbarButtonView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    
    let onExit: () -> Void

    
    var body: some View {
        HStack {
            Spacer()
            if viewModel.controlsAreVisable {
                InventoryView(viewModel: viewModel)
            }
            if viewModel.mapIsVisable {
                Button {
                    if viewModel.isMapMode == false {
                        viewModel.mainScene?.enterMapNode()
                    } else {
                        viewModel.mainScene?.exitMapMode()
                    }
                } label: {
                    Image(systemName: "map.fill")
                        .font(.largeTitle)
                        .padding()
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .padding()
            }
         
            
            Button {
                onExit()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .padding()
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .padding()
        }
    }
}

