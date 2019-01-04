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
        
        let itemLocation: NSPoint
        switch controlSize {
        case .regular:
            itemLocation = NSPoint(x: cellFrame.origin.x - 10.0, y: cellFrame.origin.y + 1.0)
        case .small:
            itemLocation = NSPoint(x: cellFrame.origin.x - 10.0, y: cellFrame.origin.y + 1.0)
        case .mini:
            itemLocation = NSPoint(x: cellFrame.origin.x - 10.0, y: cellFrame.origin.y + 0.0)
        }
        
        _ = menu.popUpMenuPositioningItem(menuItem, atLocation: itemLocation, inView: controlView, withEvent: event, highlightMenuItem: true)
        
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
    }
    
    /*==========================================================================*/
    private func displayMenuItem(_ filteringMenuItem: OBWFilteringMenuItem) {
        
        if self.menu == nil {
            self.menu = NSMenu(title: "Placeholder")
        }
        
        self.visibleFilteringItem = filteringMenuItem
        
        self.menu?.removeAllItems()
        
        let standardMenuItem = NSMenuItem(title: filteringMenuItem.title ?? "", action: nil, keyEquivalent: "")
        standardMenuItem.image = filteringMenuItem.image
        self.menu?.addItem(standardMenuItem)
        
        self.setTitle(standardMenuItem.title)
    }
}
