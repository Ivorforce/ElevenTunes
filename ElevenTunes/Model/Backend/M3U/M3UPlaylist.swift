//
//  M3UPlaylist+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//
//

import Foundation
import CoreData
import SwiftUI
import Combine

public class M3UPlaylistToken: FilePlaylistToken {
    enum InterpretationError: Error {
        case noFile
    }

	static func create(fromURL url: URL) throws -> M3UPlaylistToken {
        if try url.isFileDirectory() {
            throw InterpretationError.noFile
        }
        
        return M3UPlaylistToken(url)
    }
    
    override func expand(_ context: Library) -> AnyPlaylist {
        M3UPlaylist(self, library: context)
    }
}

public final class M3UPlaylist: RemotePlaylist {
    let library: Library
    let token: M3UPlaylistToken
    
	enum Request {
		case url, read
	}
	
	let mapper = Requests(relation: [
		.url: [.title],
		.read: [.tracks, .children]
	])
	let loading = FeatureSet<Request, Set<Request>>()

    init(_ token: M3UPlaylistToken, library: Library) {
        self.library = library
        self.token = token
		loadURLAttributes()
        loading.insert(.url)
    }
    
    public var icon: Image { Image(systemName: "doc.text") }
    
    public var accentColor: Color { SystemUI.color }
	
	public var contentType: PlaylistContentType { .hybrid }
    
    public static func interpretFile(_ file: String, relativeTo directory: URL) -> [URL] {
        let lines = file.split(whereSeparator: \.isNewline)
        
        var urls: [URL] = []
        
        for line in lines {
            let string = line.trimmingCharacters(in: .whitespaces)
            let fileURL = URL(fileURLWithPath: string, relativeTo: directory).absoluteURL
            do {
                if try fileURL.isFileDirectory() {
                    let dirURLs = try FileManager.default.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: [.isDirectoryKey])
                    
                    // Append all file URLs
                    urls += dirURLs.filter { !((try? $0.isFileDirectory()) ?? true) }
                }
                else {
                    urls.append(fileURL)
                }
            }
            catch {
                // On crash, it wasn't a file URL
                if let url = URL(string: string) {
                    urls.append(url)
                }
            }
        }
        
        return urls
    }
    
    func loadURLAttributes() {
		guard let modificationDate = try? token.url.modificationDate() else {
			return
		}
		
		mapper.attributes.update(.init([
			.title: token.url.lastPathComponent
		]), state: .version(modificationDate.isoFormat))
    }
    
//    public override func load(atLeast mask: PlaylistContentMask) {
//        contentSet.promise(mask) { promise in
//            let url = token.url
//            let library = self.library
//            let interpreter = library.interpreter
//
//            promise.fulfillingAny(.attributes) {
//                loadAttributes()
//            }
//
//            guard promise.includesAny([.tracks, .children]) else {
//                return
//            }
//
//            Future {
//                try String(contentsOf: url)
//            }
//            .map { file in
//                M3UPlaylist.interpretFile(file, relativeTo: url)
//            }
//            .flatMap {
//                interpreter.interpret(urls: $0)
//                    ?? Just([]).eraseError().eraseToAnyPublisher()
//            }
//            .map { (contents: [Content]) -> ([AnyTrack], [AnyPlaylist]) in
//                let (tracks, children) = ContentInterpreter.collect(fromContents: contents)
//
//                return (tracks.map { $0.expand(library) }, children.map { $0.expand(library) })
//            }
//            .onMain()
//            .fulfillingAny([.tracks, .children], of: promise)
//            .tryMap { ($0, $1, try url.modificationDate().isoFormat) }
//            .sink(receiveCompletion: appLogErrors(_:)) { [unowned self] (tracks, children, date) in
//				self.tracks.update(tracks, version: date)
//				self.children.update(children, version: date)
//            }.store(in: &cancellables)
//        }
//    }
}

extension M3UPlaylist: RequestMapperDelegate {
	func onDemand(_ requests: Set<Request>) {
		// TODO
	}
}
