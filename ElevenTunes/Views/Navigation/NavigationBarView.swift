//
//  NavigationBarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.01.21.
//

import SwiftUI

struct NavigationBarView: View {
	let playlist: Playlist
	@ObservedObject var navigator: Navigator
        
    var body: some View {
        HStack {
            Button {
                // TODO Change view
            } label: {
                Image(systemName: "sidebar.left")
            }
            .disabled(true)
            .padding(.leading, 8)
            
            Spacer()
                .frame(width: 20)
                    
            Button {
				navigator.selectRoot()
            } label: {
				playlist.backend.icon
            }
				.foregroundColor(navigator.isRootSelected ? .accentColor : .primary)

            Spacer()
                .frame(width: 20)

            Button {
				// TODO Navigator: Backward
            } label: {
                Image(systemName: "chevron.backward")
            }
			.disabled(true)

            Spacer()
                .frame(width: 15)

            Button {
                // TODO Navigator: Forward
            } label: {
                Image(systemName: "chevron.forward")
            }
            .disabled(true)

            Spacer()
            
			NewPlaylistView(directory: playlist, selection: navigator.selection)
                .padding(.trailing, 8)
        }
            .buttonStyle(BorderlessButtonStyle())
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .visualEffectBackground(material: .sidebar)
    }
}

struct NavigationBarView_Previews: PreviewProvider {
    static var previews: some View {
		NavigationBarView(playlist: Playlist(LibraryMock.playlist()), navigator: Navigator(root: Playlist(LibraryMock.directory())))
    }
}
