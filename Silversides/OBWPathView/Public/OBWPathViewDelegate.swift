/*===========================================================================
 OBWPathViewDelegate.swift
 OBWControls
 Copyright (c) 2019 OrderedBytes. All rights reserved.
 ===========================================================================*/

import AppKit

/// A protocol that delegates to OBWPathView must adopt.
public protocol OBWPathViewDelegate: AnyObject {
    
    /// The user is interacting with a Path Item and the Path View is requesting an OBWFilteringMenu for that item.
    /// - parameter pathView: The Path View that contains the Path Item.
    /// - parameter pathItem: The Path Item that the user is interacting with.
    /// - parameter interaction: The type of interaction that the user will have with the menu.
    /// - returns: An optional OBWFilteringMenu instance.
    func pathView(_ pathView: OBWPathView, filteringMenuForItem pathItem: OBWPathItem, interaction: OBWPathItem.InteractionType) -> OBWFilteringMenu?
    
    /// The user is interacting with a Path Item and the Path View is requesting an NSMenu for that item.
    /// - parameter pathView: The Path View that contains the Path Item.
    /// - parameter pathItem: The Path Item that the user is interacting with.
    /// - parameter interaction: The type of interaction that the user will have with the menu.
    /// - returns: An optional NSMenu instance.
    func pathView(_ pathView: OBWPathView, menuForItem pathItem: OBWPathItem, interaction: OBWPathItem.InteractionType) -> NSMenu?
    
    /// The Path View is requesting an accessibility description of itself.
    /// - parameter pathView: The Path View that is requesting the accessibility description.
    /// - returns: A string describing the Path View, suitable for an accessibility user.
    func pathViewAccessibilityDescription(_ pathView: OBWPathView) -> String?
    
    /// The Path View is requesting accessibility help information for itself.
    /// - parameter pathView: The Path View that is requesting the accessibility help description.
    /// - returns: A string describing how to interact with the Path View, suitable for an accessibility user.
    func pathViewAccessibilityHelp(_ pathView: OBWPathView) -> String?
    
    /// The Path View is requesting accessibility help information for a Path Item.
    /// - parameter pathView: The Path View that is requesting the accessibility help description.
    /// - parameter pathItem: The Path Item that should be described.
    /// - returns: A string describing how to interact with the Path Item, suitable for an accessibility user.
    func pathView(_ pathView: OBWPathView, accessibilityHelpForItem pathItem: OBWPathItem) -> String?
}


// MARK: -

/// Default OBWPathViewDelegate implementations.
public extension OBWPathViewDelegate {
    
    func pathView(_ pathView: OBWPathView, filteringMenuForItem pathItem: OBWPathItem, interaction: OBWPathItem.InteractionType) -> OBWFilteringMenu? {
        return nil
    }
    
    func pathView(_ pathView: OBWPathView, menuForItem pathItem: OBWPathItem, interaction: OBWPathItem.InteractionType) -> NSMenu? {
        return nil
    }
    
    func pathViewAccessibilityDescription(_ pathView: OBWPathView) -> String? {
        return nil
    }
    
    func pathViewAccessibilityHelp(_ pathView: OBWPathView) -> String? {
        return nil
    }
    
    func pathView(_ pathView: OBWPathView, accessibilityHelpForItem: OBWPathItem) -> String? {
        return nil
    }
    
}
