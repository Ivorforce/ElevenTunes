//
//  RemotePlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 09.01.21.
//

import Foundation
import Combine

protocol RemotePlaylist: AnyPlaylist, RequestMapperDelegate where Snapshot == PlaylistAttributes.PartialGroupSnapshot {
	typealias Requests = RequestMapper<PlaylistAttribute, PlaylistVersion, Self>

	var mapper: Requests { get }
}

extension RemotePlaylist {
	public var attributes: AnyPublisher<PlaylistAttributes.Update, Never> {
		mapper.attributes.$update.eraseToAnyPublisher()
	}
	
	public func demand(_ demand: Set<PlaylistAttribute>) -> AnyCancellable {
		mapper.demand.add(demand)
	}
	
	public var hasCaches: Bool { true }
	
	public func invalidateCaches() {
		mapper.invalidateCaches()
	}
	
	public func movePlaylists(fromIndices: IndexSet, toIndex index: Int) throws {
		throw PlaylistEditError.notSupported
	}
	
	public func `import`(library: UninterpretedLibrary, toIndex index: Int?) throws {
		throw PlaylistImportError.unimportable
	}
	
	public func delete() throws {
		throw PlaylistDeleteError.undeletable
	}
}
