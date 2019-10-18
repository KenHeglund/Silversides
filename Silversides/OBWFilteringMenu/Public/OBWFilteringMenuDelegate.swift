/*===========================================================================
 OBWFilteringMenuDelegate.swift
 OBWControls
 Copyright (c) 2019 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Foundation

/// The protocol that OBWFilteringMenu delegates adopt.
public protocol OBWFilteringMenuDelegate {
    /// The given menu will appear.  Menu items may be added or removed at this point.
    func filteringMenuShouldAppear(_ menu: OBWFilteringMenu) -> OBWFilteringMenu.DisplayTiming
    /// Requests an accessibility string for an item in the given menu.
    func filteringMenu(_ menu: OBWFilteringMenu, accessibilityHelpForItem: OBWFilteringMenuItem) -> String?
}

public extension OBWFilteringMenuDelegate {
    func filteringMenuShouldAppear(_ menu: OBWFilteringMenu) -> OBWFilteringMenu.DisplayTiming { return .now }
    func filteringMenu(_ menu: OBWFilteringMenu, accessibilityHelpForItem: OBWFilteringMenuItem) -> String? { return nil }
}

/// Delegate-specific extensions to OBWFilteringMenu.
public extension OBWFilteringMenu {
    
    /// Value returned by a delegate to indicate whether a menu should appear now or at a later time.
    enum DisplayTiming {
        /// The menu is ready to appear now.
        case now
        /// The menu will be ready to appear later with a call to OBWFilteringMenu.appearNow(with:).
        case later
    }
    
}
