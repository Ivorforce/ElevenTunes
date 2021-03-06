//
//  NSTableView+Synchronization.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 09.03.21.
//

import Cocoa

extension NSTableView {
	class ActiveSynchronizer {
		let tableView: NSTableView
		
		var moveObserver: NSObjectProtocol?
		var resizeObserver: NSObjectProtocol?
		var visibleObserver: NSObjectProtocol?

		var key: NSTableView.AutosaveName? {
			tableView.autosaveName
		}
		
		init(tableView: NSTableView) {
			self.tableView = tableView
		}
		
		func attach() {
			moveObserver = NotificationCenter.default.addObserver(forName: NSTableView.columnDidMoveNotification, object: nil, queue: .main) { [weak tableView] notification in
				guard let tableView = tableView else { return }
				
				guard
					let updateTableView = notification.object as? NSTableView,
					updateTableView != tableView,
					updateTableView.autosaveName == tableView.autosaveName
				else {
					return
				}
				
				let oldIndex = notification.userInfo!["NSOldColumn"] as! Int
				let newIndex = notification.userInfo!["NSNewColumn"] as! Int
				let column = updateTableView.tableColumns[newIndex]

				guard tableView.column(withIdentifier: column.identifier) == oldIndex else {
					return
				}
				
				tableView.moveColumn(oldIndex, toColumn: newIndex)
			}

			resizeObserver = NotificationCenter.default.addObserver(forName: NSTableView.columnDidResizeNotification, object: nil, queue: .main) { [weak tableView] notification in
				guard let tableView = tableView else { return }
								
				guard
					let updateTableView = notification.object as? NSTableView,
					updateTableView != tableView,
					updateTableView.autosaveName == tableView.autosaveName
				else {
					return
				}

				let column = notification.userInfo!["NSTableColumn"] as! NSTableColumn
				
				guard let selfColumn = tableView.tableColumn(withIdentifier: column.identifier) else {
					print("Missing column with identifier \(column.identifier) for synchronization.")
					return
				}
				
				if selfColumn.width != column.width {
					selfColumn.width = column.width
				}
			}

			visibleObserver = NotificationCenter.default.addObserver(forName: NSTableView.columnDidChangeVisibilityNotification, object: nil, queue: .main) { [weak tableView] notification in
				guard let tableView = tableView else { return }
								
				guard
					let updateTableView = notification.object as? NSTableView,
					updateTableView != tableView,
					updateTableView.autosaveName == tableView.autosaveName
				else {
					return
				}

				let column = notification.userInfo!["NSTableColumn"] as! NSTableColumn
				guard let selfColumn = tableView.tableColumn(withIdentifier: column.identifier) else {
					print("Missing column with identifier \(column.identifier) for synchronization.")
					return
				}

				if selfColumn.isHidden != column.isHidden {
					selfColumn.isHidden = column.isHidden
				}
			}
		}
	}
}
