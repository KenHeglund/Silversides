/*===========================================================================
 OBWFilteringMenu.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

public let OBWFilteringMenuWillBeginSessionNotification = "OBWFilteringMenuWillBeginSessionNotification"
public let OBWFilteringMenuDidEndSessionNotification = "OBWFilteringMenuDidEndSessionNotification"
public let OBWFilteringMenuDidBeginTrackingNotification = "OBWFilteringMenuDidBeginTrackingNotification"
public let OBWFilteringMenuWillEndTrackingNotification = "OBWFilteringMenuWillEndTrackingNotification"
public let OBWFilteringMenuRootKey = "OBWFilteringMenuRootKey"

public enum OBWFilteringMenuError: Error {
    case invalidAlternateItem( message: String )
}

/*==========================================================================*/

public protocol OBWFilteringMenuDelegate {
    func willBeginTrackingFilteringMenu( _ menu: OBWFilteringMenu )
    func filteringMenu( _ menu: OBWFilteringMenu, accessibilityHelpForItem: OBWFilteringMenuItem ) -> String?
}

/*==========================================================================*/
// MARK: -

open class OBWFilteringMenu {
    
    // MARK: - OBWFilteringMenu public
    
    public init( title: String ) {
        self.title = title
    }
    
    public convenience init() {
        self.init( title: "" )
    }
    
    // MARK: -
    
    open var title: String
    open var font: NSFont? = nil
    open var representedObject: AnyObject? = nil
    
    open var actionHandler: ( ( OBWFilteringMenuItem ) -> Void )? = nil
    open var delegate: OBWFilteringMenuDelegate? = nil
    
    open fileprivate(set) var itemArray: [OBWFilteringMenuItem] = []
    open var numberOfItems: Int { return self.itemArray.count }
    
    open internal(set) var highlightedItem: OBWFilteringMenuItem? = nil {
        
        didSet ( oldValue ) {
            
            guard self.highlightedItem !== oldValue else { return }
            
            var userInfo: [String:AnyObject] = [:]
            
            if let currentItem = self.highlightedItem {
                userInfo[OBWFilteringMenu.currentHighlightedItemKey] = currentItem
            }
            if let previousItem = oldValue {
                userInfo[OBWFilteringMenu.previousHighlightedItemKey] = previousItem
            }
            
            NotificationCenter.default.post( name: Notification.Name(rawValue: OBWFilteringMenu.highlightedItemDidChangeNotification), object: self, userInfo: userInfo )
        }
    }
    
    var description: String { return "OBWFilteringMenu: " + self.title }
    
    /*==========================================================================*/
    open func popUpMenuPositioningItem( _ item: OBWFilteringMenuItem?, atLocation locationInView: NSPoint, inView view: NSView?, withEvent event: NSEvent?, highlightMenuItem: Bool? ) -> Bool {
        
        // A menu delegate is allowed to populate menu items at this point
        self.willBeginTracking()
        
        guard var menuItem = self.itemArray.first else { return false }
        
        if let item = item {
            
            if self.itemArray.contains(where: { $0 === item }) {
                menuItem = item
            }
        }
        
        return OBWFilteringMenuController.popUpMenuPositioningItem( menuItem, atLocation: locationInView, inView: view, withEvent: event, highlighted: highlightMenuItem )
    }
    
    /*==========================================================================*/
    open func addItem( _ item: OBWFilteringMenuItem ) {
        item.menu = self
        self.itemArray.append( item )
    }
    
    /*==========================================================================*/
    open func addItems( _ items: [OBWFilteringMenuItem] ) {
        
        for item in items {
            self.addItem( item )
        }
    }
    
    /*==========================================================================*/
    open func removeAllItems() {
        
        self.highlightedItem = nil
        
        for menuItem in self.itemArray {
            menuItem.menu = nil
        }
        
        self.itemArray = []
    }
    
    /*==========================================================================*/
    open func itemWithTitle( _ title: String ) -> OBWFilteringMenuItem? {
        
        if let index = self.itemArray.index( where: { $0.title == title } ) {
            return self.itemArray[index]
        }
        
        return nil
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenu internal
    
    static let allowedModifierFlags: NSEventModifierFlags = [ .shift, .control, .option, .command ]
    
    static let highlightedItemDidChangeNotification = "OBWFilteringMenuHighlightedItemDidChangeNotification"
    static let currentHighlightedItemKey = "OBWFilteringMenuCurrentHighlightedItemKey"
    static let previousHighlightedItemKey = "OBWFilteringMenuPreviousHighlightedItemKey"
    
    var displayFont: NSFont { return self.font ?? NSFont.menuFont( ofSize: 0.0 ) }
    
    /*==========================================================================*/
    func willBeginTracking() {
        self.delegate?.willBeginTrackingFilteringMenu( self )
    }
    
}
