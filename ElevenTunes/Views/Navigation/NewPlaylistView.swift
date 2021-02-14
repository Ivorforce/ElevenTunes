//
//  NewPlaylistView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.02.21.
//

import SwiftUI

struct NewPlaylistView: View {
	let directory: Playlist
	let selection: Set<Playlist>
	
	let position: Playlist?

	init(directory: Playlist, selection: Set<Playlist>) {
		self.directory = directory
		self.selection = selection
		
		if let only = selection.one {
			position = only.backend.contentType != .tracks ? only : nil
		}
		else if selection.isEmpty {
			position = directory
		}
		else {
			position = nil
		}
	}
	
	func createPlaylist(_ playlist: TransientPlaylist) {
		guard let position = position else {
			NSAlert.warning(title: "Internal Error", text: "Unexpected position == nil")
			return
		}
		
		let library = UninterpretedLibrary(playlists: [playlist])
		
		do {
			try position.backend.import(library: library)
		}
		catch let error {
			NSAlert.warning(
				title: "Failed to create new playlist",
				text: String(describing: error)
			)
		}
	}

    var body: some View {
		HStack {
			Button {
				let playlist = TransientPlaylist(.tracks, attributes: .unsafe([
					.title: "New Playlist"
				]))
				createPlaylist(playlist)
			} label: {
				Image(systemName: "music.note.list")
					.badge(systemName: "plus.circle.fill")
			}
				.disabled(position == nil)

			Button {
				let playlist = TransientPlaylist(.playlists, attributes: .unsafe([
					.title: "New Folder"
				]))
				createPlaylist(playlist)
			} label: {
				Image(systemName: "folder")
					.badge(systemName: "plus.circle.fill")
			}
				.disabled(position == nil)

			Button {
				let playlist = TransientPlaylist(.hybrid, attributes: .unsafe([
					.title: "New Hybrid Folder"
				]))
				createPlaylist(playlist)
			} label: {
				Image(systemName: "questionmark.folder")
					.badge(systemName: "plus.circle.fill")
			}
				.disabled(position == nil)
		}
    }
}

//struct NewPlaylistView_Previews: PreviewProvider {
//    static var previews: some View {
//        NewPlaylistView()
//    }
//}