//
//  BranchingPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//

import Foundation
import Combine
import CombineExt
import SwiftUI

protocol SelfChangeWatcher {
	func onSelfChange()
}

enum PartialPlaylistMask {
	case full
	case none
}

public class BranchingPlaylist: AnyPlaylist {
	private(set) var cache: DBPlaylist
	
	let primary: AnyPlaylist
	let secondary: [AnyPlaylist]
	
	var cancellables: Set<AnyCancellable> = []
	
	init(cache: DBPlaylist, primary: AnyPlaylist, secondary: [AnyPlaylist], contentType: PlaylistContentType) {
		self.cache = cache
		self.primary = primary
		self.secondary = secondary
	}
	
	public var id: String { primary.id }
	
	public var origin: URL? { primary.origin }
	
	public var icon: Image { primary.icon }
	
	public var accentColor: Color { primary.accentColor }
	
	public var hasCaches: Bool { primary.hasCaches }
	
	public func invalidateCaches() { primary.invalidateCaches() }

	public var attributes: AnyPublisher<PlaylistAttributes.Update, Never> {
		primary.attributes
	}
	
	public func demand(_ demand: Set<PlaylistAttribute>) -> AnyCancellable {
		primary.demand(demand)
	}
	
	public var contentType: PlaylistContentType {
		primary.contentType
	}
	
	public func supports(_ capability: PlaylistCapability) -> Bool {
		primary.supports(capability)
	}
	
	public func `import`(tracks: [TrackToken], toIndex index: Int?) throws {
		try primary.import(tracks: tracks, toIndex: index)
	}
	
	public func `import`(playlists: [PlaylistToken], toIndex index: Int?) throws {
		try primary.import(playlists: playlists, toIndex: index)
	}
	
	public func delete() throws {
		try primary.delete()
		secondary.forEach { try? $0.delete() }
		cache.delete()
	}
}

extension BranchingPlaylist: Hashable {
	public static func == (lhs: BranchingPlaylist, rhs: BranchingPlaylist) -> Bool {
		lhs.id == rhs.id
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

extension AnyPlaylist {
	var primary: AnyPlaylist {
		(self as? BranchingPlaylist)?.primary ?? self
	}
}
