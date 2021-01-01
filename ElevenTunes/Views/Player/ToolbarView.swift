//
//  ToolbarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI

struct ToolbarView: View {
    @State var player: Player

    var body: some View {
        HStack {
            PlayingTrackView(player: player)
                .frame(width: 300, alignment: .leading)
                .padding(.leading)
            
            PlayerControlsView(player: player)
        }
    }
}