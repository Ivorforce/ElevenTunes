//
//  PersistentPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation
import Combine
import SwiftUI

public protocol PlaylistToken {
	var id: String { get }
	
	var origin: URL? { get }

	func expand(_ context: Library) throws -> AnyPlaylist
}
