//
//  NavigatorView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI
import Combine

struct NavigatorView: View {
    let directory: Playlist
	let navigator: Navigator
	
    @Environment(\.library) private var library: Library!

    var body: some View {
        VStack(spacing: 0) {
			NavigationSearchBar()
				.padding()
				.visualEffectBackground(material: .sidebar)

			PlaylistsView(directory: directory, navigator: navigator)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.layoutPriority(2)

			NavigationBarView(playlist: directory, navigator: navigator)
        }
    }
}

//struct NavigatorView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigatorView(directory: Playlist(LibraryMock.directory()))
//    }
//}
