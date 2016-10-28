/*===========================================================================
 OBWFilteringMenuWindow.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

enum OBWFilteringMenuAlignment {
    case Left
    case Right
}

enum OBWFilteringMenuPart {
    case Item
    case Up
    case Down
    case Filter
    case None
}

/*==========================================================================*/
// MARK: -

class OBWFilteringMenuWindow: NSWindow {
    
    /*==========================================================================*/
    init( menu: OBWFilteringMenu, screen: NSScreen ) {
        
        self.filteringMenu = menu
        
        let menuView = OBWFilteringMenuView( menu: menu )
        self.menuView = menuView
        
        let menuViewOrigin = NSPoint( x: 0.0, y: OBWFilteringMenuWindow.interiorMargins.bottom )
        self.menuView.setFrameOrigin( menuViewOrigin )
        
        let windowContentSize = menuView.frame.size - OBWFilteringMenuWindow.interiorMargins
        let windowFrameSize = max( windowContentSize, OBWFilteringMenuWindow.minimumFrameSize )
        
        let windowOrigin = NSPoint(
            x: screen.frame.midX - floor( windowFrameSize.width / 2.0 ),
            y: screen.frame.midY - floor( windowFrameSize.height / 2.0 )
        )
        
        let contentFrame = NSRect( origin: windowOrigin, size: windowFrameSize )
        
        super.init( contentRect: contentFrame, styleMask: NSBorderlessWindowMask, backing: .Buffered, defer: false )
        
        // NSPopUpMenuWindowLevel = 101. Expose widgets seem to appear at window level 100.  This window should be above everything except Expose, including the main menu which is at level 24.
        self.level = CGWindowLevelForKey( .PopUpMenuWindowLevelKey ) - 2
        
        self.opaque = false
        self.backgroundColor = NSColor.clearColor()
        self.hasShadow = true
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.releasedWhenClosed = false
        self.animationBehavior = .UtilityWindow
        
        self.contentView = OBWFilteringMenuBackground( frame: contentFrame )
        self.contentView!.autoresizingMask = [ .ViewWidthSizable, .ViewHeightSizable ]
        self.contentView!.addSubview( menuView )
    }
    
    /*==========================================================================*/
    // MARK: - NSWindow overrides
    
    override var canBecomeKeyWindow: Bool { return true }
    override var canBecomeMainWindow: Bool { return false }
    
    /*==========================================================================*/
    override func fieldEditor( createFlag: Bool, forObject anObject: AnyObject? ) -> NSText? {
        
        guard anObject is NSSearchField else {
            return super.fieldEditor( createFlag, forObject: anObject )
        }
        
        if let fieldEditor = self.filterFieldEditor {
            return fieldEditor
        }
        
        if !createFlag {
            return nil
        }
        
        self.filterFieldEditor = OBWFilteringMenuFieldEditor()
        
        return self.filterFieldEditor
    }
    
    /*==========================================================================*/
    // MARK: - NSAccessibility implementation
    
    /*==========================================================================*/
    override func accessibilitySubrole() -> String? {
        self.accessibilityActive = true
        return NSAccessibilityStandardWindowSubrole
    }
    
    /*==========================================================================*/
    override func accessibilityRoleDescription() -> String? {
        self.accessibilityActive = true
        return NSAccessibilityRoleDescription( NSAccessibilityWindowRole, NSAccessibilityStandardWindowSubrole )
    }
    
    /*==========================================================================*/
    override func accessibilityValueDescription() -> String? {
        self.accessibilityActive = true
        let title = self.filteringMenu.title as NSString
        return title.lastPathComponent
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuWindow implementation
    
    static let interiorMargins = NSEdgeInsets( top: 4.0, left: 0.0, bottom: 4.0, right: 0.0 )
    
    static let minimumFrameSize = NSSize(
        width: 80.0 + OBWFilteringMenuBackground.roundedCornerRadius * 2.0,
        height: OBWFilteringMenuBackground.roundedCornerRadius * 2.0
    )
    
    let filteringMenu: OBWFilteringMenu
    unowned let menuView: OBWFilteringMenuView
    var alignmentFromPrevious = OBWFilteringMenuAlignment.Left
    let scrollTracking: OBWFilteringMenuScrollTracking = OBWFilteringMenuScrollTracking()
    var screenAnchor: NSRect? = nil
    var filterFieldEditor: OBWFilteringMenuFieldEditor? = nil
    var accessibilityActive = false
    
    var roundedCorners: OBWFilteringMenuCorners {
        
        get {
            let backgroundView = self.contentView as! OBWFilteringMenuBackground
            return backgroundView.roundedCorners
        }
        
        set ( newValue ) {
            let backgroundView = self.contentView as! OBWFilteringMenuBackground
            backgroundView.roundedCorners = newValue
            self.invalidateShadow()
            self.displayIfNeeded()
        }
    }
    
    /*==========================================================================*/
    func menuItemAtLocation( locationInWindow: NSPoint ) -> OBWFilteringMenuItem? {
        let locationInView = self.menuView.convertPoint( locationInWindow, fromView: nil )
        return self.menuView.menuItemAtLocation( locationInView )
    }
    
    /*==========================================================================*/
    func menuPartAtLocation( locationInWindow: NSPoint ) -> OBWFilteringMenuPart {
        let locationInView = self.menuView.convertPoint( locationInWindow, fromView: nil )
        return self.menuView.menuPartAtLocation( locationInView )
    }
    
    /*==========================================================================*/
    func displayMenuLocation( menuLocation: NSPoint, atScreenLocation screenLocation: NSPoint, allowWindowToGrowUpward: Bool, resetScrollTracking: Bool = true ) -> Bool {
        
        let geometry = OBWFilteringMenuWindowGeometry( window: self )
        if !geometry.updateGeometryToDisplayMenuLocation( menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: allowWindowToGrowUpward ) {
            return false
        }
        
        self.applyWindowGeometry( geometry )
        
        if resetScrollTracking {
            self.scrollTracking.reset( geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds )
        }
        
        return true
    }
    
    /*==========================================================================*/
    func displayMenuLocation( menuLocation: NSPoint, adjacentToScreenArea areaInScreen: NSRect, prefrerredAlignment: OBWFilteringMenuAlignment ) {
        
        let geometry = OBWFilteringMenuWindowGeometry( window: self )
        let newAlignment = geometry.updateGeometryToDisplayMenuLocation( menuLocation, adjacentToScreenArea: areaInScreen, preferredAlignment: prefrerredAlignment )
        
        self.applyWindowGeometry( geometry )
        self.alignmentFromPrevious = newAlignment
        self.screenAnchor = areaInScreen
        
        self.scrollTracking.reset( geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds )
    }
    
    /*==========================================================================*/
    func displayMenuItemBounds( menuItemBounds: NSRect ) -> Bool {
        
        let windowGeometry = OBWFilteringMenuWindowGeometry( window: self )
        
        if !windowGeometry.updateGeometryToDisplayMenuItemBounds( menuItemBounds ) {
            return false
        }
        
        self.applyWindowGeometry( windowGeometry )
        
        return true
    }
    
    /*==========================================================================*/
    func displayUpdatedTotalMenuItemSize() -> Bool {
        
        let geometry = OBWFilteringMenuWindowGeometry( window: self )
        if !geometry.updateGeometryWithResizedMenu() {
            return false
        }
        
        self.applyWindowGeometry( geometry )
        
        self.scrollTracking.reset( geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds )
        
        NSNotificationCenter.defaultCenter().postNotificationName( OBWFilteringMenuTotalItemSizeChangedNotification, object: self )
        
        return true
    }
    
    /*==========================================================================*/
    func applyWindowGeometry( windowGeometry: OBWFilteringMenuWindowGeometry ) {
        
        let currentWindowFrame = self.frame
        let newWindowFrame = windowGeometry.frame
        
        let menuView = self.menuView
        
        if currentWindowFrame == newWindowFrame {
            
            menuView.setMenuItemBoundsOriginY( windowGeometry.initialBounds.origin.y )
        }
        else {
            
            let interiorMargins = OBWFilteringMenuWindow.interiorMargins
            
            let menuViewFrame = NSRect(
                x: 0.0,
                y: currentWindowFrame.size.height - newWindowFrame.size.height + interiorMargins.bottom,
                width: newWindowFrame.size.width,
                height: newWindowFrame.size.height - interiorMargins.height
            )
            
            menuView.frame = menuViewFrame
            menuView.setMenuItemBoundsOriginY( windowGeometry.initialBounds.origin.y )
            
            self.setFrame( newWindowFrame, display: true )
            self.invalidateShadow()
        }
    }
    
    /*==========================================================================*/
    func resetScrollTracking() {
        let geometry = OBWFilteringMenuWindowGeometry( window: self )
        self.scrollTracking.reset( geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds )
    }
}
