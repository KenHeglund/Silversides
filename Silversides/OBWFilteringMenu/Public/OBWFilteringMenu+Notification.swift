/*===========================================================================
OBWFilteringMenu+Notification.swift
OBWControls
Copyright (c) 2019 Ken Heglund. All rights reserved.
===========================================================================*/

import Foundation

/// OBWFilteringMenu-related notification names.
public extension OBWFilteringMenu {
	/// An `OBWFilteringMenu` will begin a session.
	///
	/// - parameter object: The root filtering menu.
	/// - parameter userInfo: None.
	static let willBeginSessionNotification = Notification.Name(rawValue: "OBWFilteringMenuWillBeginSessionNotification")
	
	/// An `OBWFilteringMenu` finished a session.
	///
	/// - parameter object: The root filtering menu.
	/// - parameter userInfo: None.
	static let didEndSessionNotification = Notification.Name(rawValue: "OBWFilteringMenuDidEndSessionNotification")
	
	/// An `OBWFilteringMenu` began tracking the cursor.
	///
	/// - parameter object: The filtering menu that began tracking the cursor.
	/// - parameter userInfo: `root` - The root filtering menu.
	static let didBeginTrackingNotification = Notification.Name(rawValue: "OBWFilteringMenuDidBeginTrackingNotification")
	
	/// An `OBWFilteringMenu` will stop tracking the cursor.
	///
	/// - parameter object: The filtering menu that will stop tracking the cursor.
	/// - parameter userInfo: `root` - The root filtering menu.
	static let willEndTrackingNotification = Notification.Name(rawValue: "OBWFilteringMenuWillEndTrackingNotification")
	
	/// An item was selected from a filtering menu.
	///
	/// - parameter object: The filtering menu containing the selected item.
	/// - parameter userInfo: `item` - The selected menu item.
	static let didSelectItemNotification = Notification.Name(rawValue: "OBWFilteringMenuDidSelectItem")
}

public extension OBWFilteringMenu {
	/// OBWFilteringMenu notification key type.
	struct Key: Hashable, Equatable, RawRepresentable {
		public init(rawValue: String) {
			self.rawValue = rawValue
		}
		
		public let rawValue: String
	}
}


/// `OBWFilteringMenu` notification keys.
public extension OBWFilteringMenu.Key {
	/// The associated filtering menu.
	static let root = OBWFilteringMenu.Key(rawValue: "OBWFilteringMenuRootKey")
	/// The associated filtering menu item.
	static let item = OBWFilteringMenu.Key(rawValue: "OBWFilteringMenuItemKey")
}
