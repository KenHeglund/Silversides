/*===========================================================================
 OBWFilteringMenu+Internal.swift
 OBWControls
 Copyright (c) 2019 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit

// Additional properties and functions for internal use only
extension OBWFilteringMenu {
    
    /// ModifierFlags that may be used to identify alternate menu items.
    static let allowedModifierFlags: NSEvent.ModifierFlags = [.shift, .control, .option, .command]
    
    /// The font to use when displaying the menu's items.
    var displayFont: NSFont {
        return self.font ?? self.parentItem?.menu?.displayFont ?? NSFont.menuFont(ofSize: 0.0)
    }
    
    /// Notify the delegate (if any) that the menu will begin tracking the cursor, last chance to provide the menu's items.
    func finalMenuItemsAreNeededNow() {
        self.delegate?.filteringMenuWillAppear(self)
    }
    
}


// MARK: -

// Additional types for internal use only.
extension OBWFilteringMenu {
    
    /// An enum that describes which side of a menu item its submenu will appear.
    enum SubmenuAlignment {
        /// The submenu will appear on the left side.
        case left
        /// The submenu will appear on the right side.
        case right
    }
    
    /// An enum that describes various parts of a menu.
    enum MenuPart {
        /// A menu item.
        case item
        /// The up arrow.  Indicates more items are available above the topmost visible item.
        case up
        /// The down arrow.  Indicates more items are available below the bottommost visible item.
        case down
        /// The filter text field.
        case filter
        /// No menu part.
        case none
    }
    
}


// MARK: -

// Additional notification names for internal use only
extension OBWFilteringMenu {
    /// The currently highlighted menu item did change.
    /// - parameter object: The filtering menu containing the highlighted item.
    /// - parameter userInfo: `currentHighlightedItem` - The currently highlighted item.
    /// - parameter userInfo: `previousHighlightedItem` - The previously highlighted item.
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
