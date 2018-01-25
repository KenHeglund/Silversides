/*===========================================================================
 OBWFilteringMenuItem.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

open class OBWFilteringMenuItem {
    
    // MARK: - OBWFilteringMenuItem public
    
    public init( title: String ) {
        self.title = title
    }
    
    // MARK: -
    
    open var title: String? = nil
    @NSCopying open var attributedTitle: NSAttributedString? = nil
    open var image: NSImage? = nil
    open var submenu: OBWFilteringMenu? = nil
    open var keyEquivalentModifierMask: NSEvent.ModifierFlags = []
    
    open var enabled = true
    open var representedObject: AnyObject? = nil
    open var actionHandler: ( ( OBWFilteringMenuItem ) -> Void )? = nil
    
    open var titleOffset: NSSize {
        
        if OBWFilteringMenuItem.separatorItem === self {
            return NSZeroSize
        }
        
        return OBWFilteringMenuActionItemView.titleOffsetForMenuItem( self )
    }
    
    open var isSeparatorItem: Bool { return OBWFilteringMenuItem.separatorItem === self }
    open var isHighlighted: Bool { return self.menu?.highlightedItem === self }
    
    open var description: String {
        return "OBWFilteringMenuItem " + ( self.title ?? "" )
    }
    
    
    // MARK: -
    
    /*==========================================================================*/
    open static let separatorItem: OBWFilteringMenuItem = {
        return OBWFilteringMenuItem( title: "<separator>" )
    }()
    
    /*==========================================================================*/
    open func addAlternateItem( _ menuItem: OBWFilteringMenuItem ) throws {
        
        guard !self.isAlternate else {
            throw OBWFilteringMenuError.invalidAlternateItem( message: "Alternate item cannot be added to an item that is itself an alternate" )
        }
        guard !self.isSeparatorItem else {
            throw OBWFilteringMenuError.invalidAlternateItem( message: "A separator cannot be added as an alternate" )
        }
        
        let alternateModifierMask = menuItem.keyEquivalentModifierMask.intersection( OBWFilteringMenu.allowedModifierFlags )
        let hostModifierMask = self.keyEquivalentModifierMask
        
        guard alternateModifierMask != hostModifierMask else {
            throw OBWFilteringMenuError.invalidAlternateItem( message: "Alternate modifier mask must be different than the mask of the item it is being added to" )
        }
        
        menuItem.menu = self.menu
        menuItem.isAlternate = true
        
        let key = OBWFilteringMenuItem.dictionaryKeyWithModifierMask( alternateModifierMask )
        
        if let itemToReplace = self.alternates[key] {
            itemToReplace.menu = nil
            itemToReplace.isAlternate = false
        }
        
        self.alternates[key] = menuItem
    }
    
    /*==========================================================================*/
    open func visibleItemForModifierFlags( _ modifierFlags: NSEvent.ModifierFlags ) -> OBWFilteringMenuItem? {
        
        if modifierFlags == self.keyEquivalentModifierMask {
            return self
        }
        
        if self.isAlternate {
            return nil
        }
        
        if alternates.isEmpty && !self.keyEquivalentModifierMask.isEmpty {
            return nil
        }
        
        let key = OBWFilteringMenuItem.dictionaryKeyWithModifierMask( modifierFlags )
        return alternates[key] ?? self
    }
    
    /*==========================================================================*/
    open func performAction() {
        
        if let itemHandler = self.actionHandler {
            itemHandler( self )
        }
        else if let menuHandler = self.menu?.actionHandler {
            menuHandler( self )
        }
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuItem internal
    
    weak var menu: OBWFilteringMenu? = nil
    var canHighlight: Bool { return !self.isSeparatorItem }
    private(set) var alternates: [String:OBWFilteringMenuItem] = [:]
    private(set) var isAlternate: Bool = false
    
    var font: NSFont { return self.menu?.displayFont ?? NSFont.menuFont( ofSize: 0.0 ) }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuItem private
    
    /*==========================================================================*/
    class func dictionaryKeyWithModifierMask( _ modifierMask: NSEvent.ModifierFlags ) -> String {
        return String( format: "%lu", modifierMask.rawValue )
    }
}
