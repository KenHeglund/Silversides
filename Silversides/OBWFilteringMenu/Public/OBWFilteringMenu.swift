/*===========================================================================
OBWFilteringMenu.swift
Silversides
Copyright (c) 2016, 2019 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

/// The OBWFilteringMenu class.
public class OBWFilteringMenu {
	
	// MARK: - OBWFilteringMenu public
	
	public init(title: String = "") {
		self.title = title
	}
	
	
	// MARK: -
	
	/// The current title of the filtering menu.
	public var title: String
	
	/// The font used to display filtering menu items.  If `nil`, then the
	/// system menu font is used.
	public var font: NSFont?
	
	/// When `true`, menu item separators may be shown when the menu is filtered.
	public var showSeparatorsWhileFiltered = false
	
	/// An object that may be associated with the menu.  The menu does not get
	/// or set this value.
	public var representedObject: Any?
	
	/// An action that is performed when a menu item is selected and that item
	/// does not have its own action.
	public var actionHandler: ((OBWFilteringMenuItem) -> Void )?
	
	/// The filtering menu’s delegate.
	public var delegate: OBWFilteringMenuDelegate?
	
	/// The menu’s filtering menu items.
	public private(set) var itemArray: [OBWFilteringMenuItem] = []
	
	/// The total number of items in the menu.
	public var numberOfItems: Int {
		return self.itemArray.count
	}
	
	/// The parent filtering menu item (if any).  Will be non-`nil` only if the
	/// receiver is a submenu.
	public internal(set) var parentItem: OBWFilteringMenuItem?
	
	/// The currently highlighted menu item (if any).
	public var highlightedItem: OBWFilteringMenuItem? {
		didSet (oldValue) {
			guard self.highlightedItem !== oldValue else {
				return
			}
			
			var userInfo: [OBWFilteringMenu.Key: Any] = [:]
			
			if let currentItem = self.highlightedItem {
				userInfo[.currentHighlightedItem] = currentItem
			}
			if let previousItem = oldValue {
				userInfo[.previousHighlightedItem] = previousItem
			}
			
			NotificationCenter.default.post(name: OBWFilteringMenu.highlightedItemDidChangeNotification, object: self, userInfo: userInfo)
		}
	}
	
	/// Programmatically display the menu, optionally positioning an item at a
	/// specific location.
	///
	/// - Parameters:
	///   - menuItem: The filtering menu item to position.  May be `nil`.
	///   - alignment: The location within the menu item to position at
	///   `locationInView`.
	///   - locationInView: The origin of the filtering menu item to position.
	///   - view: The view that defines the coordinate system for
	///   `locationInView`.  If `nil`, then the `locationInView` parameter is
	///   interpreted as screen coordinates.
	///   - matchWidth: If `true`, the menu will be at least as wide as `view`.
	///   - event: The event causing the filtering menu’s appearance.  May be
	///   `nil`.
	///   - highlightTarget: A `HighlightTarget` that identifies the menu item
	///   to initially highlight after the menu appears.
	///
	/// - returns: `true` if a menu was closed by selecting an item, `false` if
	/// no selection was made.
	@discardableResult
	public func popUpMenuPositioningItem(_ menuItem: OBWFilteringMenuItem?, aligning alignment: OBWFilteringMenuItem.Alignment, atPoint locationInView: NSPoint, inView view: NSView?, matchingWidth: Bool, withEvent event: NSEvent?, highlighting highlightTarget: OBWFilteringMenu.HighlightTarget) -> Bool {
		
		guard self.prepareForAppearance() == .now else {
			assertionFailure("Menu should be ready to appear before calling popUpMenuPositioningItem()")
			return false
		}
		
		// Sanity check to make sure the given item isn’t used unless it is actually in the receiver.
		guard let itemToDisplay = self.itemArray.first(where: { $0 === menuItem }) ?? self.itemArray.first else {
			return false
		}
		
		return OBWFilteringMenuController.popUpMenuPositioningItem(itemToDisplay, aligning: alignment, atPoint: locationInView, inView: view, matchingWidth: matchingWidth, with: event, highlighting: highlightTarget)
	}
	
	/// Add a filtering item to the menu.
	public func addItem(_ item: OBWFilteringMenuItem) {
		item.menu = self
		self.itemArray.append(item)
	}
	
	/// Add multiple filtering items to the menu.
	public func addItems(_ items: [OBWFilteringMenuItem]) {
		for item in items {
			self.addItem(item)
		}
	}
	
	/// Adds a heading menu item with the given title to the menu.
	@discardableResult
	public func addHeadingItem(withTitle title: String) -> OBWFilteringMenuItem {
		let item = OBWFilteringMenuItem(headingTitled: title)
		self.addItem(item)
		return item
	}
	
	/// Adds a separator item to the menu.
	@discardableResult
	public func addSeparatorItem() -> OBWFilteringMenuItem {
		let item = OBWFilteringMenuItem.separatorItem
		self.addItem(item)
		return item
	}
	
	/// Remove all filtering menus from the menu.
	public func removeAllItems() {
		self.highlightedItem = nil
		
		for menuItem in self.itemArray {
			menuItem.menu = nil
		}
		
		self.itemArray = []
	}
	
	/// Show a menu that the delegate had delayed by returning `.defer` from the
	/// `filteringMenuShouldAppear(_:)` function.
	///
	/// - parameter updateHandler: A closure that should be called to finish
	/// configuring the menu.  The closure receives a reference to the receiver.
	public func appearNow(with updateHandler: @escaping (OBWFilteringMenu) -> Void) {
		guard let updateGeneration = self.deferredUpdate?.generation else {
			return
		}
		
		self.deferredUpdate?.updateHandler = updateHandler
		
		OBWFilteringMenuEventSubtype.deferredMenuUpdateReady.post(atStart: true, data1: updateGeneration)
	}
	
	/// Returns the filtering item with the given title (if any).
	public func itemWithTitle(_ title: String) -> OBWFilteringMenuItem? {
		return self.itemArray.first(where: { $0.title == title })
	}
	
	/// Returns the preferred icon point size for the given control size.
	public static func iconSize(for controlSize: NSControl.ControlSize) -> NSSize {
		switch controlSize {
			case .small:
				return NSSize(width: 15.0, height: 15.0)
			case .mini:
				return NSSize(width: 13.0, height: 13.0)
			case .regular,
				 .large:
				fallthrough
			@unknown default:
				return NSSize(width: 17.0, height: 17.0)
		}
	}
	
	
	// MARK: - Internal
	
	/// Information about this menu’s deferred update.
	var deferredUpdate: DeferredUpdate? = nil
	
	/// The cause for displaying this menu as a submenu.
	var submenuOpenMethod: SubmenuOpenMethod? = nil
}


extension OBWFilteringMenu: CustomDebugStringConvertible {
	/// Instance debug description.
	public var debugDescription: String {
		let address = Unmanaged.passUnretained(self).toOpaque()
		return "OBWFilteringMenu <\(address)>: \(self.title)"
	}
}
