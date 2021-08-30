/*===========================================================================
OBWFilteringMenuController+Keys.swift
OBWControls
Copyright (c) 2019 OrderedBytes. All rights reserved.
===========================================================================*/

import AppKit

/// Defines internal menu controller notification names.
extension OBWFilteringMenuController {
	/// A filtering menu item was opened via accessibility APIs.
	///
	/// - parameter object: The root filtering menu.
	/// - parameter userInfo: `menuItem` - The opened menu item.
	static let axDidOpenMenuItemNotification = Notification.Name(rawValue: "OBWFilteringMenuAXDidOpenMenuItemNotification")
	
}


/// Defines a key type for notification and timer userInfo dictionaries.
extension OBWFilteringMenuController {
	/// OBWFilteringMenu notification key type.
	struct Key: Hashable, Equatable, RawRepresentable {
		let rawValue: String
	}
}


/// Defines keys associated with notification and timer userInfo dictionaries.
extension OBWFilteringMenuController.Key {
	/// The associated menu item.
	static let menuItem = OBWFilteringMenuController.Key(rawValue: "OBWFilteringMenuItemKey")
	
	/// The menu window associated with a scroll timer.
	static let window = OBWFilteringMenuController.Key(rawValue: "OBWFilteringMenuWindowKey")
	
	/// Indicates the menu content is scrolling downward.
	static let scrollUp = OBWFilteringMenuController.Key(rawValue: "OBWFilteringMenuScrollUpTimerKey")
	
	/// Indicates the menu content is scrolling upward.
	static let scrollDown = OBWFilteringMenuController.Key(rawValue: "OBWFilteringMenuScrollDownTimerKey")
}
