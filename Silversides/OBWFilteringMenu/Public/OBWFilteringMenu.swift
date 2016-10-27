/*===========================================================================
 OBWFilteringMenu.swift
 Silversides
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

public let OBWFilteringMenuWillBeginSessionNotification = "OBWFilteringMenuWillBeginSessionNotification"
public let OBWFilteringMenuDidEndSessionNotification = "OBWFilteringMenuDidEndSessionNotification"
public let OBWFilteringMenuDidBeginTrackingNotification = "OBWFilteringMenuDidBeginTrackingNotification"
public let OBWFilteringMenuWillEndTrackingNotification = "OBWFilteringMenuWillEndTrackingNotification"
public let OBWFilteringMenuRootKey = "OBWFilteringMenuRootKey"

public enum OBWFilteringMenuError: ErrorType {
    case InvalidAlternateItem( message: String )
}

/*==========================================================================*/

public protocol OBWFilteringMenuDelegate {
    func willBeginTrackingFilteringMenu( menu: OBWFilteringMenu )
    func filteringMenu( menu: OBWFilteringMenu, accessibilityHelpForItem: OBWFilteringMenuItem ) -> String?
}

/*==========================================================================*/
// MARK: -

public class OBWFilteringMenu {
    
    // MARK: - OBWFilteringMenu public
    
    public init( title: String ) {
        self.title = title
    }
    
    public convenience init() {
        self.init( title: "" )
    }
    
    // MARK: -
    
    public var title: String
    public var font: NSFont? = nil
    public var representedObject: AnyObject? = nil
    
    public var actionHandler: ( ( OBWFilteringMenuItem ) -> Void )? = nil
    public var delegate: OBWFilteringMenuDelegate? = nil
    
    public private(set) var itemArray: [OBWFilteringMenuItem] = []
    public var numberOfItems: Int { return self.itemArray.count }
    
    public internal(set) var highlightedItem: OBWFilteringMenuItem? = nil {
        
        didSet ( oldValue ) {
            
            guard self.highlightedItem !== oldValue else { return }
            
            var userInfo: [String:AnyObject] = [:]
            
            if let currentItem = self.highlightedItem {
                userInfo[OBWFilteringMenu.currentHighlightedItemKey] = currentItem
            }
            if let previousItem = oldValue {
                userInfo[OBWFilteringMenu.previousHighlightedItemKey] = previousItem
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName( OBWFilteringMenu.highlightedItemDidChangeNotification, object: self, userInfo: userInfo )
        }
    }
    
    var description: String { return "OBWFilteringMenu: " + self.title }
    
    /*==========================================================================*/
    public func popUpMenuPositioningItem( item: OBWFilteringMenuItem?, atLocation locationInView: NSPoint, inView view: NSView?, withEvent event: NSEvent?, highlightMenuItem: Bool? ) -> Bool {
        
        // A menu delegate is allowed to populate menu items at this point
        self.willBeginTracking()
        
        guard var menuItem = self.itemArray.first else { return false }
        
        if let item = item {
            
            if self.itemArray.contains({ $0 === item }) {
                menuItem = item
            }
        }
        
        return OBWFilteringMenuController.popUpMenuPositioningItem( menuItem, atLocation: locationInView, inView: view, withEvent: event, highlighted: highlightMenuItem )
    }
    
    /*==========================================================================*/
    public func addItem( item: OBWFilteringMenuItem ) {
        item.menu = self
        self.itemArray.append( item )
    }
    
    /*==========================================================================*/
    public func addItems( items: [OBWFilteringMenuItem] ) {
        
        for item in items {
            self.addItem( item )
        }
    }
    
    /*==========================================================================*/
    public func removeAllItems() {
        
        self.highlightedItem = nil
        
        for menuItem in self.itemArray {
            menuItem.menu = nil
        }
        
        self.itemArray = []
    }
    
    /*==========================================================================*/
    public func itemWithTitle( title: String ) -> OBWFilteringMenuItem? {
        
        if let index = self.itemArray.indexOf( { $0.title == title } ) {
            return self.itemArray[index]
        }
        
        return nil
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenu internal
    
    static let allowedModifierFlags: NSEventModifierFlags = [ .Shift, .Control, .Option, .Command ]
    
    static let highlightedItemDidChangeNotification = "OBWFilteringMenuHighlightedItemDidChangeNotification"
    static let currentHighlightedItemKey = "OBWFilteringMenuCurrentHighlightedItemKey"
    static let previousHighlightedItemKey = "OBWFilteringMenuPreviousHighlightedItemKey"
    
    var displayFont: NSFont { return self.font ?? NSFont.menuFontOfSize( 0.0 ) }
    
    /*==========================================================================*/
    func willBeginTracking() {
        self.delegate?.willBeginTrackingFilteringMenu( self )
    }
    
}
