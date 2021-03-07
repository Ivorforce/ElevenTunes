//
//  OriginView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI
import Combine

struct ArtistCellView: View {
    let artist: Playlist

	@State var title: PlaylistAttributes.ValueSnapshot<String> = .missing()

    var body: some View {
        HStack {
			if title.state == .valid {
                if let url = artist.backend.origin {
                    UnderlinedLink(
                        description: title.value ?? "Unknown Artist",
                        destination: url
                    )
                }
                else {
                    Text(title.value ?? "Unknown Artist")
                }
            }
            else {
				Text(title.value ?? "...")
                    .opacity(0.5)
            }
        }
		.whileActive(artist.backend.demand([.title]))
		.onReceive(artist.backend.attribute(PlaylistAttribute.title)) { title = $0 }
		.id(artist.id)
    }
}

struct AlbumCellView: View {
    let album: Playlist
    
	@State var title: PlaylistAttributes.ValueSnapshot<String> = .missing()
    
    var body: some View {
		HStack {
            album.backend.icon
            
			if title.state == .valid {
                if let url = album.backend.origin {
                    UnderlinedLink(
						description: title.value ?? "Unknown Album",
                        destination: url
                    )
                }
                else {
                    Text(title.value ?? "Unknown Album")
                }
            }
            else {
                Text(title.value ?? "...")
                    .opacity(0.5)
            }
        }
		.whileActive(album.backend.demand([.title]))
		.onReceive(album.backend.attribute(PlaylistAttribute.title)) { title = $0 }
		.id(album.id)
    }
}

struct TrackArtistsView: View {
	let track: Track
	
	@State var artists: [Playlist]?

	var body: some View {
		HStack {
			if let artists = artists {
				if artists.isEmpty {
					Text("Unknown Artist")
						.opacity(0.5)
				}
				else {
					ForEach(artists, id: \.id) {
						ArtistCellView(artist: $0)
					}
				}
			}
			else {
				Text("...")
					.opacity(0.5)
			}
		}
			.foregroundColor(.secondary)
			.whileActive(track.backend.demand([.artists]))
			.onReceive(track.backend.attribute(TrackAttribute.artists)) {
				artists = $0.value?.map { Playlist($0) }
			}
	}
}

struct TrackAlbumView: View {
	let track: Track
	
	@State var album: Playlist?

	var body: some View {
		Group {
			if let album = album {
				AlbumCellView(album: album)
			}
		}
			.foregroundColor(.secondary)
			.whileActive(track.backend.demand([.album]))
			.onReceive(track.backend.attribute(TrackAttribute.album)) {
				album = $0.value.map { Playlist($0) }
			}
	}
}
