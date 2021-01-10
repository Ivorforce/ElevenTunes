//
//  AnyPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation
import SwiftUI
import Combine

@objc public enum PlaylistContentType: Int16 {
    /// Can only contain tracks
    case tracks
    /// Can only contain playlists (as children)
    case playlists
    /// Can contain both tracks and playlists (e.g. filesystem folders, artists)
    case hybrid
}

public protocol AnyPlaylist: AnyObject {
    var id: String { get }
    var asToken: PlaylistToken { get }

    var contentType: PlaylistContentType { get }
    
    var origin: URL? { get }
    
    var icon: Image { get }
    var accentColor: Color { get }

    var hasCaches: Bool { get }
	func invalidateCaches()

	/// Registers a persistent demand for some attributes. The playlist promises that it will try to
	/// evolve the attribute's `State.missing` to some other state.
	func demand(_ demand: Set<PlaylistAttribute>) -> AnyCancellable
	/// A stream of attributes, and the last changed attribute identifiers. The identifiers are useful for ignoring
	/// irrelevant updates.
    var attributes: AnyPublisher<PlaylistAttributes.Update, Never> { get }

    @discardableResult
    func `import`(library: AnyLibrary) -> Bool
}

extension AnyPlaylist {
	public var icon: Image { Image(systemName: "music.note.list") }
    var accentColor: Color { .primary }
}

class PlaylistBackendTypedCodable: TypedCodable<String> {
    static let _registry = CodableRegistry<String>()
        .register(TransientPlaylist.self, for: "transient")
        .register(DirectoryPlaylistToken.self, for: "directory")
        .register(M3UPlaylistToken.self, for: "m3u")
        .register(SpotifyPlaylistToken.self, for: "spotify")
        .register(SpotifyUserToken.self, for: "spotify-user")
        .register(SpotifyAlbumToken.self, for: "spotify-album")
        .register(SpotifyArtistToken.self, for: "spotify-artist")

    override class var registry: CodableRegistry<String> { _registry }
}

extension NSValueTransformerName {
    static let playlistBackendName = NSValueTransformerName(rawValue: "PlaylistBackendTransformer")
}

@objc(PlaylistBackendTransformer)
class PlaylistBackendTransformer: TypedJSONCodableTransformer<String, PlaylistBackendTypedCodable> {}
