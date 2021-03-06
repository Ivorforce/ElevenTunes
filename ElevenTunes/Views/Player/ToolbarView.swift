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
		VStack {
			HStack {
				PlayingTrackView(player: player)
					.frame(minWidth: 250, maxWidth: .infinity, alignment: .leading)
					.padding([.leading, .trailing])
					.layoutPriority(2)
				
				PlayerControlsView(player: player)
					.padding(.top, 8)

				PlayHistoryAccessorView()
					.padding(.top, 8)
					.padding(.trailing, 12)
			}
			
			// Top Alignment
			Spacer()
		}
    }
}
