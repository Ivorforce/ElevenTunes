//
//  PlaylistsViewController.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.02.21.
//

import Cocoa

class PlaylistsViewController: NSViewController {
	@IBOutlet weak var outlineView: NSOutlineView! = nil
		
	var directory: Playlist {
		didSet {
			directoryItem = Item(playlist: directory.backend, parent: nil, delegate: self)
			print("Did Set")
		}
	}
	
	var directoryItem: Item! {
		didSet {
			outlineView?.reloadData()
		}
	}
	
	var selectionObserver: (Set<Playlist>) -> Void
	
	var dummyPlaylist: Item!
	
	init(_ directory: Playlist, selectionObserver: @escaping (Set<Playlist>) -> Void) {
		self.directory = directory
		self.selectionObserver = selectionObserver
		super.init(nibName: nil, bundle: .main)
		directoryItem = Item(playlist: directory.backend, parent: nil, delegate: self)
		directoryItem.isDemanding = true
		dummyPlaylist = Item(playlist: TransientPlaylist(.tracks, attributes: .init()), parent: nil, delegate: self)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}