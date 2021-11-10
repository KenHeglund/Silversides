/*===========================================================================
OBWFilteringMenu+Internal.swift
OBWControls
Copyright (c) 2019 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit
import OSLog

// Additional properties and functions for internal use only
extension OBWFilteringMenu {
	/// ModifierFlags that may be used to identify alternate menu items.
	static let allowedModifierFlags: NSEvent.ModifierFlags = [.shift, .control, .option, .command]
	
	/// The font to use when displaying the menu’s items.
	var displayFont: NSFont {
		return self.font ?? self.parentItem?.menu?.displayFont ?? NSFont.menuFont(ofSize: 0.0)
	}
	
	/// Prepare the menu for appearance.  The delegate may defer the menu’s
	/// appearance.
	func prepareForAppearance() -> DisplayTiming {
		return self.delegate?.filteringMenuShouldAppear(self) ?? .now
	}
}


// MARK: -

// Additional types for internal use only.
extension OBWFilteringMenu {
	/// An enum that describes which side of a menu item its submenu will appear.
	enum SubmenuAlignment {
		/// The submenu will appear on the leading side.  (The left side in a
		/// left-to-right layout direction.)
		case leading
		/// The submenu will appear on the trailing side.  (The right side in a
		/// left-to-right layout direction.)
		case trailing
	}
	
	/// An enum that describes various parts of a menu.
	enum MenuPart {
		/// A menu item.
		case item
		/// The up arrow.  Indicates more items are available above the topmost
		/// visible item.
		case up
		/// The down arrow.  Indicates more items are available below the
		/// bottommost visible item.
		case down
		/// The filter text field.
		case filter
		/// No menu part.
		case none
	}
	
	/// An enum that describes the various methods that a submenu may be opened.
	enum SubmenuOpenMethod {
		/// The cursor is hovering over a menu item.
		case cursor
		/// A keyboard arrow has been pressed to highlight a menu item.
		case keyboard
		/// Accessibility APIs were used to select a menu item.
		case accessibilityAPI
	}
}


// MARK: -

// Additional notification names for internal use only
extension OBWFilteringMenu {
	/// The currently highlighted menu item did change.
	///
	/// - parameter object: The filtering menu containing the highlighted item.
	/// - parameter userInfo: `currentHighlightedItem` - The currently
	/// highlighted item.
	/// - parameter userInfo: `previousHighlightedItem` - The previously
	/// highlighted item.
	static let highlightedItemDidChangeNotification = Notification.Name(rawValue: "OBWFilteringMenuHighlightedItemDidChangeNotification")
}


// MARK: -

// Additional notification keys for internal use only
extension OBWFilteringMenu.Key {
	/// Currently highlighted menu item.
	static let currentHighlightedItem = OBWFilteringMenu.Key(rawValue: "OBWFilteringMenuCurrentHighlightedItemKey")
	/// Previously highlighted menu item.
	static let previousHighlightedItem = OBWFilteringMenu.Key(rawValue: "OBWFilteringMenuPreviousHighlightedItemKey")
}


// MARK: -

extension OBWFilteringMenu {
	/// Holds information about the deferred appearance of a submenu.
	struct DeferredUpdate {
		/// A copy of the controller’s delayed submenu generation counter.
		let generation: Int
		/// A handler to give the delegate a chance to update the menu.
		var updateHandler: ((OBWFilteringMenu) -> Void)?
		
		init(generation: Int) {
			self.generation = generation
		}
	}
}


// MARK: -

// os_log constants
extension OSLog {
	static let filteringMenuLogger = OSLog(subsystem: "com.orderedbytes.SilversidesApp", category: "Filtering")
}

extension OSSignpostID {
	static let filteringSignpostID = OSSignpostID(log: .filteringMenuLogger)
}
