//
//  TracksViewController.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import Cocoa
import Combine

class TracksViewController: NSViewController {
	@IBOutlet weak var tableView: NSTableViewContextSensitiveMenu! = nil
	var tableViewHiddenExtension: NSTableView.ColumnHiddenExtension!
	var tableViewSynchronizer: NSTableView.ActiveSynchronizer!

	var library: Library
	var player: Player

	var playlist: Playlist {
		didSet {
			updatePlaylistObserver()
		}
	}
	
	var tracks: [Track] = [] {
		didSet {
			tableView?.animateDifference(from: oldValue, to: tracks)
		}
	}
	
	var playlistObserver: AnyCancellable?
	
	var cancellables = Set<AnyCancellable>()
	
	init(_ playlist: Playlist, library: Library, player: Player) {
		self.playlist = playlist
		self.library = library
		self.player = player
		super.init(nibName: nil, bundle: .main)
		updatePlaylistObserver()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		initColumns()

		tableView.returnAction = #selector(didPressReturn(_:))

		tableView.registerForDraggedTypes(TrackInterpreter.standard.types.map { .init(rawValue: $0.identifier ) })
		tableView.registerForDraggedTypes([.init(TracksExportManager.tracksIdentifier)])

		tableView.backgroundColor = NSColor.clear
		tableView.sizeToFit()
	}
	
	private func updatePlaylistObserver() {
		playlistObserver = playlist.backend.attribute(PlaylistAttribute.tracks).sink { [weak self] tracks in
			guard let self = self else {
				return
			}
			
			self.tracks = tracks.value?.map { Track($0) } ?? []
		}
	}
}
