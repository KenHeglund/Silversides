/*===========================================================================
 OBWFilteringMenuDelegate.swift
 OBWControls
 Copyright (c) 2019 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Foundation

/// The protocol that OBWFilteringMenu delegates adopt.
public protocol OBWFilteringMenuDelegate {
    /// The given menu will appear.  Menu items may be added or removed at this point.
    func filteringMenuWillAppear(_ menu: OBWFilteringMenu)
    /// Requests an accessibility string for an item in the given menu.
    func filteringMenu(_ menu: OBWFilteringMenu, accessibilityHelpForItem: OBWFilteringMenuItem) -> String?
}

public extension OBWFilteringMenuDelegate {
    func filteringMenuWillAppear(_ menu: OBWFilteringMenu) { }
    func filteringMenu(_ menu: OBWFilteringMenu, accessibilityHelpForItem: OBWFilteringMenuItem) -> String? { return nil }
}
