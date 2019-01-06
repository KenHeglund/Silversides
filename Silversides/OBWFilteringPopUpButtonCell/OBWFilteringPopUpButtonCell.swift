/*===========================================================================
 OBWFilteringPopUpButtonCell.swift
 Silversides
 Copyright (c) 2018 OrderedBytes. All rights reserved.
 ===========================================================================*/

import AppKit

/*==========================================================================*/

public class OBWFilteringPopUpButtonCell: NSPopUpButtonCell {
    
    /*==========================================================================*/
    // MARK: - NSPopUpButtonCell overrides
    
    /*==========================================================================*/
    public override func trackMouse(with event: NSEvent, in cellFrame: NSRect, of controlView: NSView, untilMouseUp flag: Bool) -> Bool {
        
        guard let menu = self.filteringMenu else {
            return false
        }
        
        let controlSize = self.controlSize
        let fontSize = NSFont.systemFontSize(for: controlSize)
        menu.font = NSFont.menuFont(ofSize: fontSize)
        
        let menuItem = self.visibleFilteringItem
        
        for item in menu.itemArray {
            if item === menuItem {
                item.state = .on
            }
            else {
                item.state = .off
            }
        }
        
        let itemLocation: NSPoint
        switch controlSize {
        case .regular:
            itemLocation = NSPoint(x: cellFrame.origin.x - 10.0, y: cellFrame.origin.y + 1.0)
        case .small:
            itemLocation = NSPoint(x: cellFrame.origin.x - 10.0, y: cellFrame.origin.y + 1.0)
        case .mini:
            itemLocation = NSPoint(x: cellFrame.origin.x - 10.0, y: cellFrame.origin.y + 0.0)
        }
        
        _ = menu.popUpMenuPositioningItem(menuItem, atLocation: itemLocation, inView: controlView, matchingHostViewWidth: true, withEvent: event, highlightMenuItem: true)
        
        return true
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringPopUpButtonCell implementation
    
    public var filteringMenu: OBWFilteringMenu? = nil {
        
        willSet {
            self.visibleFilteringItem = nil
            NotificationCenter.default.removeObserver(self, name: OBWFilteringMenu.didSelectItem, object: self.filteringMenu)
        }
        didSet {
            NotificationCenter.default.addObserver(self, selector: #selector(OBWFilteringPopUpButtonCell.didSelectMenuItem(_:)), name: OBWFilteringMenu.didSelectItem, object: self.filteringMenu)
            
            if let firstMenuItem = self.filteringMenu?.itemArray.first {
                self.displayMenuItem(firstMenuItem)
            }
        }
    }
    
    /*==========================================================================*/
    public func select(_ filteringItem: OBWFilteringMenuItem?) {
        self.displayMenuItem(filteringItem)
    }
    
    /*==========================================================================*/
    public var selectedFilteringItem: OBWFilteringMenuItem? {
        return self.visibleFilteringItem
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringPopUpButtonCell private
    
    private var visibleFilteringItem: OBWFilteringMenuItem? = nil
    
    /*==========================================================================*/
    @objc private func didSelectMenuItem(_ notification: Notification) {
        
        guard
            let menu = notification.object as? OBWFilteringMenu,
            menu === self.filteringMenu,
            let menuItem = notification.userInfo?[OBWFilteringMenu.itemKey] as? OBWFilteringMenuItem
        else {
            return
        }
        
        self.displayMenuItem(menuItem)
        
        if let target = self.target, let action = self.action {
            _ = target.perform(action, with: self.controlView)
        }
    }
    
    /*==========================================================================*/
    private func displayMenuItem(_ filteringMenuItem: OBWFilteringMenuItem?) {
        
        if self.menu == nil {
            self.menu = NSMenu(title: "Placeholder")
        }
        
        self.visibleFilteringItem = filteringMenuItem
        
        self.menu?.removeAllItems()
        
        if let item = filteringMenuItem {
            
            let standardMenuItem = NSMenuItem(title: item.title ?? "", action: nil, keyEquivalent: "")
            standardMenuItem.image = item.image
            self.menu?.addItem(standardMenuItem)
            
            self.setTitle(standardMenuItem.title)
        }
        else {
            
            self.setTitle("")
        }
        
    }
}
