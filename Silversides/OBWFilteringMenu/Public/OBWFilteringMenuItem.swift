/*===========================================================================
 OBWFilteringMenuItem.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit

/// Represents a single item in a filtering menu.
public class OBWFilteringMenuItem {
    
    typealias AlternateKey = NSEvent.ModifierFlags.RawValue
    
    /// Initialize a regular menu item.
    public init(title: String) {
        self.title = title
    }
    
    /// Initialize a menu item that acts as a heading.
    public convenience init(headingTitled title: String) {
        self.init(title: title)
        self.enabled = false
        self.isHeadingItem = true
    }
    
    /// The title of the menu item, rendered in the standard menu font.  If both `title` and `attributedTitle` are present, `attributedTitle` is used.
    public var title: String? = nil
    
    /// An attributed menu item title.  If both `title` and `attributedTitle` are present, `attributedTitle` is used.
    @NSCopying public var attributedTitle: NSAttributedString? = nil
    
    /// The menu item's image, if any.
    public var image: NSImage? = nil
    
    /// The menu item's submenu, if any.
    public var submenu: OBWFilteringMenu? = nil {
        willSet {
            self.submenu?.parentItem = nil
        }
        didSet {
            self.submenu?.parentItem = self
        }
    }
    
    /// The menu item's checked state.
    public var state: NSControl.StateValue = .off
    
    /// The indentation level of the menu.
    public var indentationLevel: Int = 0
    
    /// The keyboard modifiers used to trigger the menu item's action.
    public var keyEquivalentModifierMask: NSEvent.ModifierFlags = []
    
    /// The menu item's enabled state.
    public var enabled = true
    
    /// An object associated with the menu item.  The menu item holds a strong reference to the object, but does not use it in any way.
    public var representedObject: Any? = nil
    
    /// A closure to be called when the menu item is selected.  Takes a reference to the menu item and returns nothing.
    public var actionHandler: ( (OBWFilteringMenuItem) -> Void )? = nil
    
    // Indicates whether the menu item is the separator item.
    public var isSeparatorItem: Bool {
        return OBWFilteringMenuItem.separatorItem === self
    }
    
    /// Indicates whether the menu item behaves as a heading item.
    public private(set) var isHeadingItem = false
    
    /// Indicates whether the menu item is the menu's highlighted item.
    public var isHighlighted: Bool {
        return self.menu?.highlightedItem === self
    }
    
    public var description: String {
        return "OBWFilteringMenuItem " + (self.title ?? "")
    }
    
    /// Returns the shared sepaartor menu item.
    public static let separatorItem: OBWFilteringMenuItem = {
        return OBWFilteringMenuItem(title: "<separator>")
    }()
    
    /// Adds an alternate menu item to the receiver.  An alternate cannot be added to a menu item that is itself an alternate.  The alternate menu item's modifier mask must be different than the receiver's mask.
    public func addAlternateItem(_ menuItem: OBWFilteringMenuItem) throws {
        
        guard self.isAlternate == false else {
            throw OBWFilteringMenuError.invalidAlternateItem(message: "Alternate item cannot be added to an item that is itself an alternate")
        }
        guard self.isSeparatorItem == false else {
            throw OBWFilteringMenuError.invalidAlternateItem(message: "A separator cannot be added as an alternate")
        }
        
        let alternateModifierMask = menuItem.keyEquivalentModifierMask.intersection(OBWFilteringMenu.allowedModifierFlags)
        let hostModifierMask = self.keyEquivalentModifierMask
        
        guard alternateModifierMask != hostModifierMask else {
            throw OBWFilteringMenuError.invalidAlternateItem(message: "Alternate modifier mask must be different than the mask of the item it is being added to")
        }
        
        menuItem.menu = self.menu
        menuItem.isAlternate = true
        
        if let itemToReplace = self.alternates[alternateModifierMask.rawValue] {
            itemToReplace.menu = nil
            itemToReplace.isAlternate = false
        }
        
        self.alternates[alternateModifierMask.rawValue] = menuItem
    }
    
    /// Returns the receiver's alternate menu item that matches the given mask.  If no alternates match, then the receiver is returned.
    public func visibleItemForModifierFlags(_ modifierFlags: NSEvent.ModifierFlags) -> OBWFilteringMenuItem? {
        
        if modifierFlags == self.keyEquivalentModifierMask {
            return self
        }
        
        if self.isAlternate {
            return nil
        }
        
        if alternates.isEmpty && self.keyEquivalentModifierMask.isEmpty == false {
            return nil
        }
        
        return alternates[modifierFlags.rawValue] ?? self
    }
    
    /// Perform the action associated with the menu item.
    public func performAction() {
        
        if let itemHandler = self.actionHandler {
            itemHandler(self)
        }
        else if let menuHandler = self.menu?.actionHandler {
            menuHandler(self)
        }
    }
    
    
    // MARK: - Internal
    
    /// The menu that the receiver belongs to.
    weak var menu: OBWFilteringMenu? = nil
    
    /// Indicates if the menu item can be highlighted.
    var canHighlight: Bool {
        return !self.isSeparatorItem && !self.isHeadingItem
    }
    
    /// The menu item's alternate items.
    private(set) var alternates: [AlternateKey:OBWFilteringMenuItem] = [:]
    
    /// Indicates whether the receiver is an alternate to another menu item.
    private(set) var isAlternate: Bool = false
    
    /// The font that should be used to display the menu item's title.
    var font: NSFont {
        return self.menu?.displayFont ?? NSFont.menuFont(ofSize: 0.0)
    }
    
    /// The template image that should be used to draw the menu item's current checked state.
    var stateTemplateImage: NSImage? {
        
        switch self.state {
        case .on:
            return NSImage(named: NSImage.menuOnStateTemplateName)
        case .mixed:
            return NSImage(named: NSImage.menuMixedStateTemplateName)
        default:
            return nil
        }
    }
    
}
