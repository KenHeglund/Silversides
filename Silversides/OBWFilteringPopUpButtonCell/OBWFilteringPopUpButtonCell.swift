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
        
        let menuItem: OBWFilteringMenuItem? = nil
        let itemLocation = cellFrame.origin
        let highlightItem = true
        
        _ = menu.popUpMenuPositioningItem(menuItem, atLocation: itemLocation, inView: controlView, withEvent: event, highlightMenuItem: highlightItem)
        
        return true
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringPopUpButtonCell implementation
    
    public var filteringMenu: OBWFilteringMenu? = nil
}
