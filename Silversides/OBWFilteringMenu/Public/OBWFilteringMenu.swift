/*===========================================================================
 OBWFilteringMenu.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

public enum OBWFilteringMenuError: Error {
    case invalidAlternateItem(message: String)
}

/*==========================================================================*/

public protocol OBWFilteringMenuDelegate {
    func willBeginTrackingFilteringMenu(_ menu: OBWFilteringMenu)
    func filteringMenu(_ menu: OBWFilteringMenu, accessibilityHelpForItem: OBWFilteringMenuItem) -> String?
}

/*==========================================================================*/
// MARK: -

public class OBWFilteringMenu {
    
    public static let willBeginSessionNotification = Notification.Name(rawValue: "OBWFilteringMenuWillBeginSessionNotification")
    public static let didEndSessionNotification = Notification.Name(rawValue: "OBWFilteringMenuDidEndSessionNotification")
    public static let didBeginTrackingNotification = Notification.Name(rawValue: "OBWFilteringMenuDidBeginTrackingNotification")
    public static let willEndTrackingNotification = Notification.Name(rawValue: "OBWFilteringMenuWillEndTrackingNotification")
    
    public static let rootKey = "OBWFilteringMenuRootKey"
    
    // MARK: - OBWFilteringMenu public
    
    public init(title: String) {
        self.title = title
    }
    
    public convenience init() {
        self.init(title: "")
    }
    
    // MARK: -
    
    public var title: String
    public var font: NSFont? = nil
    public var representedObject: AnyObject? = nil
    
    public var actionHandler: ( (OBWFilteringMenuItem) -> Void )? = nil
    public var delegate: OBWFilteringMenuDelegate? = nil
    
    public private(set) var itemArray: [OBWFilteringMenuItem] = []
    
    public var numberOfItems: Int {
        return self.itemArray.count
    }
    
    public internal(set) var highlightedItem: OBWFilteringMenuItem? = nil {
        
        didSet (oldValue) {
            
            guard self.highlightedItem !== oldValue else {
                return
            }
            
            var userInfo: [String:AnyObject] = [:]
            
            if let currentItem = self.highlightedItem {
                userInfo[OBWFilteringMenu.currentHighlightedItemKey] = currentItem
            }
            if let previousItem = oldValue {
                userInfo[OBWFilteringMenu.previousHighlightedItemKey] = previousItem
            }
            
            NotificationCenter.default.post(name: OBWFilteringMenu.highlightedItemDidChangeNotification, object: self, userInfo: userInfo)
        }
    }
    
    var description: String {
        return "OBWFilteringMenu: \(self.title)"
    }
    
    /*==========================================================================*/
    public func popUpMenuPositioningItem(_ item: OBWFilteringMenuItem?, atLocation locationInView: NSPoint, inView view: NSView?, withEvent event: NSEvent?, highlightMenuItem: Bool?) -> Bool {
        
        // A menu delegate is allowed to populate menu items at this point
        self.willBeginTracking()
        
        guard var menuItem = self.itemArray.first else {
            return false
        }
        
        if let item = item {
            
            if self.itemArray.contains(where: { $0 === item }) {
                menuItem = item
            }
        }
        
        return OBWFilteringMenuController.popUpMenuPositioningItem(menuItem, atLocation: locationInView, inView: view, withEvent: event, highlighted: highlightMenuItem)
    }
    
    /*==========================================================================*/
    public func addItem(_ item: OBWFilteringMenuItem) {
        item.menu = self
        self.itemArray.append(item)
    }
    
    /*==========================================================================*/
    public func addItems(_ items: [OBWFilteringMenuItem]) {
        
        for item in items {
            self.addItem(item)
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
    public func itemWithTitle(_ title: String) -> OBWFilteringMenuItem? {
        
        if let index = self.itemArray.index(where: { $0.title == title }) {
            return self.itemArray[index]
        }
        
        return nil
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenu internal
    
    static let allowedModifierFlags: NSEvent.ModifierFlags = [.shift, .control, .option, .command]
    
    static let highlightedItemDidChangeNotification = Notification.Name(rawValue: "OBWFilteringMenuHighlightedItemDidChangeNotification")
    static let currentHighlightedItemKey = "OBWFilteringMenuCurrentHighlightedItemKey"
    static let previousHighlightedItemKey = "OBWFilteringMenuPreviousHighlightedItemKey"
    
    var parentItem: OBWFilteringMenuItem? = nil
    
    var displayFont: NSFont {
        return self.font ?? self.parentItem?.menu?.displayFont ?? NSFont.menuFont(ofSize: 0.0)
    }
    
    /*==========================================================================*/
    func willBeginTracking() {
        self.delegate?.willBeginTrackingFilteringMenu(self)
    }
}
