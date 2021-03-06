//
//  JustCacheTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.01.21.
//

import Foundation
import Combine
import SwiftUI

final class JustCacheTrack: RemoteTrack {
	let cache: DBTrack
	
	enum Request {
		case attributes
	}

	let mapper = Requests(relation: [
		.attributes: [.title],
	])

	init(_ cache: DBTrack) {
		self.cache = cache
		mapper.delegate = self
		
		NotificationCenter.default.addObserver(self, selector: #selector(objectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: cache.managedObjectContext!)
	}
			
	@objc func objectsDidChange(_ notification: NSNotification) {
		guard let userInfo = notification.userInfo else { return }

		// awakeFromInsert is only called on the original context. Not when it's inserted here
		let updates = (userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? []).union(userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? [])
		
		if updates.contains(cache) {
			mapper.invalidateCaches()  // TODO invalidate only what's needed
		}
	}

	/// TODO Use UUID
	var id: String { cache.objectID.description }
	
	var origin: URL? { nil }
	
	var accentColor: Color { .primary }
	
	func invalidateCaches() { }
		
	func audioTrack(forDevice device: BranchingAudioDevice) throws -> AnyPublisher<AudioTrack, Error> {
		throw UnsupportedAudioDeviceError()
	}
	
	public func supports(_ capability: TrackCapability) -> Bool {
		switch capability {
		case .delete:
			return true
		}
	}
	
	func delete() throws {
		cache.delete()
	}
}

extension JustCacheTrack: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<TrackAttributes.PartialGroupSnapshot, Error> {
		switch request {
		case .attributes:
			return Just(.init(.unsafe([
				.title: "Unknown Track"
			]), state: .valid)
			).eraseError().eraseToAnyPublisher()
		}
	}
	
	func onUpdate(_ snapshot: VolatileAttributes<TrackAttribute, String>.PartialGroupSnapshot, from request: Request) {
		// TODO
	}
}

extension JustCacheTrack: BranchableTrack {
	func store(in track: DBTrack) throws -> DBTrack.Representation {
		.none
	}
}
