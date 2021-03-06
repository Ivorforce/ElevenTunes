//
//  FileVideo.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 28.12.20.
//

import Foundation
import CoreData
import UniformTypeIdentifiers
import Combine
import AVFoundation
import SwiftUI

import TunesUI
import TunesLogic

public struct AVTrackToken: TrackToken {
	enum InterpretationError: Error {
		case missing
	}

	let url: URL
	let isVideo: Bool
	
	public var id: String { url.absoluteString }
	public var origin: URL? { url }
	
	static func understands(url: URL) -> Bool {
		guard let type = UTType(filenameExtension: url.pathExtension) else {
			return false
		}
		return type.conforms(to: .audiovisualContent)
	}

	static func create(fromURL url: URL) throws -> AVTrackToken {
		_ = try AVAudioFile(forReading: url) // Just so we know it's readable
		let type = try UTType(filenameExtension: url.pathExtension).unwrap(orThrow: InterpretationError.missing)
		let isVideo = type.conforms(to: .movie)
		
		return AVTrackToken(url: url, isVideo: isVideo)
	}
	
	public func expand(_ context: Library) throws -> AnyTrack {
		AVTrack(url, isVideo: isVideo, caches: context.fileCaches)
	}
}

public final class AVTrack: RemoteTrack {
	enum PlayError: Error, LocalizedError {
		case fileDoesntExist
		
		var errorDescription: String? {
			"The file doesn't exist."
		}
	}
	
	enum AnalysisError: Error {
		case notImplemented
	}
	
	enum TagLibError: Error {
		case cannotRead
	}
	
	public let url: URL
	public let isVideo: Bool

	let caches: LibraryFileCaches
	var cache: DBAVTrack? = nil

	enum Request {
		case url, read, waveform
	}
	
	let mapper = Requests(relation: [
		.url: [],
		.read: [.title, .key, .tempo, .previewImage, .artists, .album, .genre, .duration],
		.waveform: [.waveform]
	])

	init(_ url: URL, isVideo: Bool, caches: LibraryFileCaches) {
		self.url = url
		self.isVideo = isVideo
		self.caches = caches
		mapper.delegate = self
		mapper.offer(.url, update: loadURL())
	}
	 
	convenience init(cache: DBAVTrack, caches: LibraryFileCaches) {
		self.init(cache.url, isVideo: cache.isVideo, caches: caches)
		self.cache = cache
	}
	 
	public var accentColor: Color { SystemUI.color }

    public var icon: Image {
		isVideo ? Image(systemName: "film") : Image(systemName: "music.note")
	}
	
	public var id: String { url.absoluteString }
	
	public var origin: URL? { url }

	public func invalidateCaches() {
		if let cache = cache {
			try? caches.avPreviewImages.delete(cache.owner.uuid)
			try? caches.avWaveforms.delete(cache.owner.uuid)

			cache.metadata?.delete()
		}
		
		invalidateSubCaches()
		mapper.invalidateCaches()
	}
	
	func loadURL() -> TrackAttributes.PartialGroupSnapshot {
		.init(.unsafe([
			.title: url.lastPathComponent
		]), state: .missing)
	}
	
	public func audioTrack(forDevice device: BranchingAudioDevice) throws -> AnyPublisher<AudioTrack, Error> {
		guard let device = device.av else {
			throw UnsupportedAudioDeviceError()
		}
		
		// TODO Return video emitter when possible
		return Future.tryOnQueue(.global(qos: .default)) { [url] in
			if !((try? url.checkResourceIsReachable()) ?? false) {
				throw PlayError.fileDoesntExist
			}
			
			let file = try AVAudioFile(forReading: url)
			let singleDevice = try device.prepare(file)
			return AVAudioPlayerEmitter(singleDevice, file: file)
		}
			.eraseToAnyPublisher()
	}
	
	public func supports(_ capability: TrackCapability) -> Bool {
		false
	}
}

extension AVTrack: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<TrackAttributes.PartialGroupSnapshot, Error> {
		switch request {
		case .url:
			return Future.tryOnQueue(.global(qos: .default)) {
				self.loadURL()
			}.eraseToAnyPublisher()
		case .read:
			return Future.tryOnQueue(.global(qos: .default)) {
				try self.readFile()
			}
			.eraseToAnyPublisher()
		case .waveform:
			return Future.tryOnQueue(.global(qos: .default)) {
				try self.analyzeWaveform()
			}
			.eraseError().eraseToAnyPublisher()
		}
	}

	func readFile() throws -> TrackAttributes.PartialGroupSnapshot {
		let caches = self.caches

		if
			let cache = cache,
			let snapshot: TrackAttributes.PartialGroupSnapshot = cache.managedObjectContext!.withChildTaskTranslate(cache, ({ cache in
				guard let metadata = cache.metadata else { return nil }
				
				return .init(.unsafe([
					.title: metadata.title,
					.previewImage: try? caches.avPreviewImages.get(cache.owner.uuid),
					.tempo: metadata.tempo.truePositiveOrNil.map { Tempo(beatsPerMinute: $0) },
					.key: metadata.key.flatMap { MusicalKey.parse($0) },
					.album: metadata.album.map { TransientAlbum(attributes: .unsafe([
						.title: $0
					])) },
					.artists: metadata.artists.map {
						let artists = TransientArtist.splitNames($0)
						
						return artists.map {
							TransientArtist(attributes: .unsafe([
								.title: $0
							]))
						}
					},
					.genre: metadata.genre,
					.year: Int(metadata.year).nonZeroOrNil,
					.duration: metadata.duration
				]), state: .valid)
			}))
		{
			return snapshot
		}
				
		let file = try TagLibFile(url: url).unwrap(orThrow: TagLibError.cannotRead)
		let avImporter = AVFoundationImporter(AVURLAsset(url: url))
		
		let image = file.image.flatMap { NSImage(data: $0) }
		let duration = TimeInterval(CMTimeGetSeconds(avImporter.duration))
		
		let bpm = file.bpm
			?? avImporter.string(withKey: .id3MetadataKeyBeatsPerMinute, keySpace: .id3)
			?? avImporter.string(withKey: .iTunesMetadataKeyBeatsPerMin, keySpace: .iTunes)
		let key = file.initialKey
			?? avImporter.string(withKey: .id3MetadataKeyInitialKey, keySpace: .id3)

		if let cache = cache {
			cache.managedObjectContext?.trySaveOnChildTask { context in
				guard let cache = context.translate(cache) else { return }
				
				if let image = image {
					try caches.avPreviewImages.insert(image, for: cache.owner.uuid)
				}
				
				let metadata = DBFileMetadata(context: context)
				metadata.title = file.title
				metadata.tempo = bpm.flatMap { Double($0) } ?? 0
				metadata.key = key
				metadata.album = file.album
				metadata.artists = file.artist
				metadata.genre = file.genre
				metadata.year = Int32(file.year)
				metadata.duration = duration
				
				cache.metadata = metadata
			}
		}
		
		return .init(.unsafe([
			.title: file.title,
			.previewImage: image,
			.tempo: bpm.flatMap { Double($0) }.map { Tempo(beatsPerMinute: $0) },
			.key: key.flatMap { MusicalKey.parse($0) },
			.album: file.album.map { TransientAlbum(attributes: .unsafe([
				.title: $0
			])) },
			.artists: file.artist.map {
				let artists = TransientArtist.splitNames($0)
				
				return artists.map {
					TransientArtist(attributes: .unsafe([
						.title: $0
					]))
				}
			},
			.genre: file.genre,
			.year: Int(file.year).nonZeroOrNil,
			.duration: duration,
		]), state: .valid)
	}
	
	func analyzeWaveform() throws -> TrackAttributes.PartialGroupSnapshot {
		let caches = self.caches
		
		if
			let cache = cache,
			let waveform = cache.managedObjectContext!.withChildTaskTranslate(cache, { cache in
				try? caches.avWaveforms.get(cache.owner.uuid)
			})
		{
			return .init(.unsafe([
				.waveform: waveform,
			]), state: .valid)
		}
		
		let file = EssentiaFile(url: url)
		let waveform = try AppDelegate.heavyWork.waitAndDo {
			try AppDelegate.essentiaWork.waitAndDo {
				Waveform.from(try file.analyzeWaveform(Int32(Waveform.desiredLength)))
			}
		}
		
		cache?.managedObjectContext!.withChildTaskTranslate(cache, { cache in
			try? caches.avWaveforms.insert(waveform, for: cache.owner.uuid)
		})

		return .init(.unsafe([
			.waveform: waveform,
		]), state: .valid)
	}
	
	func onUpdate(_ snapshot: VolatileAttributes<TrackAttribute, String>.PartialGroupSnapshot, from request: Request) {
		// TODO
	}
}

extension AVTrack: BranchableTrack {
	func store(in track: DBTrack) throws -> DBTrack.Representation {
		guard
			let context = track.managedObjectContext,
			let model = context.persistentStoreCoordinator?.managedObjectModel,
			let trackModel = model.entitiesByName["DBAVTrack"]
		else {
			fatalError("Failed to find model in MOC")
		}

		let cache = DBAVTrack(entity: trackModel, insertInto: context)
		cache.url = url
		cache.isVideo = isVideo
		
		track.avRepresentation = cache
		
		self.cache = cache
		
		return .av
	}
}
