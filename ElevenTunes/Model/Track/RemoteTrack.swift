//
//  RemoteTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine
import SwiftUI

protocol RemoteTrack: AnyTrack, RequestMapperDelegate where Snapshot == TrackAttributes.PartialGroupSnapshot {
	typealias Requests = RequestMapper<TrackAttribute, TrackVersion, Self>

	var mapper: Requests { get }
}

extension RemoteTrack {
	public var attributes: AnyPublisher<TrackAttributes.Update, Never> {
		mapper.attributes.updates.eraseToAnyPublisher()
	}
	
	public func demand(_ demand: Set<TrackAttribute>) -> AnyCancellable {
		mapper.demand.add(demand)
	}
	
	public var hasCaches: Bool { true }
	
	public func invalidateSubCaches() {
		let attributes = mapper.attributes.snapshot.attributes
		attributes[TrackAttribute.artists]?.forEach { $0.invalidateCaches() }
		attributes[TrackAttribute.album]?.invalidateCaches()
	}
	
	public func invalidateCaches() {
		invalidateSubCaches()
		mapper.invalidateCaches()
	}
	
	public func delete() throws {
		throw PlaylistDeleteError.undeletable
	}
}
