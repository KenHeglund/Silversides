/*===========================================================================
 OBWFilteringMenuItemView.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

class OBWFilteringMenuItemView: NSView {
    
    /*==========================================================================*/
    init(menuItem: OBWFilteringMenuItem) {
        
        self.menuItem = menuItem
        
        let placeholderFrame = NSRect(width: 10.0, height: 10.0)
        super.init(frame: placeholderFrame)
        
        self.autoresizingMask = NSView.AutoresizingMask.width
        
        var alternateViews: [String:OBWFilteringMenuItemView] = [:]
        
        for (key, menuItem) in menuItem.alternates {
            alternateViews[key] = OBWFilteringMenuItemView.viewWithMenuItem(menuItem)
        }
        
        if alternateViews.isEmpty == false {
            self.alternateViews = alternateViews
        }
    }
    
    /*==========================================================================*/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuItemView implementation
    
    static let minimumWidth: CGFloat = 100.0
    
    let menuItem: OBWFilteringMenuItem
    private(set) var alternateViews: [String:OBWFilteringMenuItemView]? = nil
    private(set) var filterStatus: OBWFilteringMenuItemFilterStatus? = nil
    
    /*==========================================================================*/
    var preferredSize: NSSize {
        return type(of: self).preferredSizeForMenuItem(self.menuItem)
    }
    
    /*==========================================================================*/
    class func viewWithMenuItem(_ menuItem: OBWFilteringMenuItem) -> OBWFilteringMenuItemView {
        
        if menuItem.isSeparatorItem {
            return OBWFilteringMenuSeparatorItemView(menuItem: menuItem)
        }
        
        return OBWFilteringMenuActionItemView(menuItem: menuItem)
    }
    
    /*==========================================================================*/
    class func preferredSizeForMenuItem(_ menuItem: OBWFilteringMenuItem) -> NSSize {
        
        if menuItem.isSeparatorItem {
            return OBWFilteringMenuSeparatorItemView.preferredSizeForMenuItem(menuItem)
        }
        
        return OBWFilteringMenuActionItemView.preferredSizeForMenuItem(menuItem)
    }
    
    /*==========================================================================*/
    func sizeToFit() {
        self.setFrameSize(self.preferredSize)
    }
    
    /*==========================================================================*/
    func applyFilterStatus(_ status: OBWFilteringMenuItemFilterStatus) {
        
        self.filterStatus = status
        
        guard
            let alternateStatus = status.alternateStatus,
            let alternateViews = self.alternateViews
        else {
            return
        }
        
        for (key, view) in alternateViews {
            view.filterStatus = alternateStatus[key]
        }
    }
    
}

/*==========================================================================*/
// MARK: -

class OBWFilteringMenuSeparatorItemView: OBWFilteringMenuItemView {
    
    /*==========================================================================*/
    override func draw(_ dirtyRect: NSRect) {
        
        let itemViewBounds = self.bounds
        
        let drawRect = NSRect(
            x: itemViewBounds.origin.x + 1.0,
            y: floor( itemViewBounds.midY ) - 1.0,
            width: itemViewBounds.size.width - 2.0,
            height: 1.0
        )
        
        NSColor.secondaryLabelColor.withAlphaComponent(0.25).set()
        
        if #available(macOS 10.14, *) {
            
            let knownAppearanceNames: [NSAppearance.Name] = [.darkAqua, .aqua]
            
            if NSAppearance.current.bestMatch(from: knownAppearanceNames) == .darkAqua {
                NSColor.secondaryLabelColor.withAlphaComponent(0.5).set()
            }
        }
        
        drawRect.fill()
    }
    
    /*==========================================================================*/
    override class func preferredSizeForMenuItem(_ menuItem: OBWFilteringMenuItem) -> NSSize {
        return NSSize(width: 10.0, height: 12.0)
    }
}
