/*===========================================================================
 OBWFilteringMenuWindow.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

enum OBWFilteringMenuAlignment {
    case left
    case right
}

enum OBWFilteringMenuPart {
    case item
    case up
    case down
    case filter
    case none
}

/*==========================================================================*/
// MARK: -

class OBWFilteringMenuWindow: NSWindow {
    
    /*==========================================================================*/
    init(menu: OBWFilteringMenu, screen: NSScreen) {
        
        self.filteringMenu = menu
        
        let menuView = OBWFilteringMenuView(menu: menu)
        self.menuView = menuView
        
        let menuViewOrigin = NSPoint(x: 0.0, y: OBWFilteringMenuWindow.interiorMargins.bottom)
        self.menuView.setFrameOrigin(menuViewOrigin)
        
        let windowContentSize = menuView.frame.size - OBWFilteringMenuWindow.interiorMargins
        let windowFrameSize = max(windowContentSize, OBWFilteringMenuWindow.minimumFrameSize)
        
        let windowOrigin = NSPoint(
            x: screen.frame.midX - floor(windowFrameSize.width / 2.0),
            y: screen.frame.midY - floor(windowFrameSize.height / 2.0)
        )
        
        let contentFrame = NSRect(origin: windowOrigin, size: windowFrameSize)
        
        super.init(contentRect: contentFrame, styleMask: .borderless, backing: .buffered, defer: false)
        
        // NSPopUpMenuWindowLevel = 101. Expose widgets seem to appear at window level 100.  This window should be above everything except Expose, including the main menu which is at level 24.
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.popUpMenuWindow)) - 2)
        
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.hasShadow = true
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.isReleasedWhenClosed = false
        self.animationBehavior = .utilityWindow
        
        let contentView = OBWFilteringMenuBackground(frame: contentFrame)
        contentView.autoresizingMask = [.width, .height]
        contentView.addSubview(menuView)
        self.contentView = contentView
    }
    
    /*==========================================================================*/
    // MARK: - NSWindow overrides
    
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return false }
    
    /*==========================================================================*/
    override func fieldEditor(_ createFlag: Bool, for anObject: Any?) -> NSText? {
        
        guard let searchField = anObject as? NSSearchField else {
            return super.fieldEditor(createFlag, for: anObject)
        }
        
        if let fieldEditor = self.filterFieldEditor {
            return fieldEditor
        }
        
        if createFlag == false {
            return nil
        }
        
        self.filterFieldEditor = OBWFilteringMenuFieldEditor(frame: searchField.frame, textContainer: nil)
        
        return self.filterFieldEditor
    }
    
    /*==========================================================================*/
    // MARK: - NSAccessibility implementation
    
    /*==========================================================================*/
    override func accessibilitySubrole() -> NSAccessibility.Subrole? {
        self.accessibilityActive = true
        return NSAccessibility.Subrole.standardWindow
    }
    
    /*==========================================================================*/
    override func accessibilityRoleDescription() -> String? {
        self.accessibilityActive = true
        return NSAccessibility.Role.window.description(with: NSAccessibility.Subrole.standardWindow)
    }
    
    /*==========================================================================*/
    override func accessibilityValueDescription() -> String? {
        self.accessibilityActive = true
        let title = self.filteringMenu.title as NSString
        return title.lastPathComponent
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuWindow implementation
    
    static let interiorMargins = NSEdgeInsets(top: 4.0, left: 0.0, bottom: 4.0, right: 0.0)
    
    static let minimumFrameSize = NSSize(
        width: 80.0 + OBWFilteringMenuBackground.roundedCornerRadius * 2.0,
        height: OBWFilteringMenuBackground.roundedCornerRadius * 2.0
    )
    
    let filteringMenu: OBWFilteringMenu
    unowned let menuView: OBWFilteringMenuView
    var alignmentFromPrevious = OBWFilteringMenuAlignment.left
    let scrollTracking: OBWFilteringMenuScrollTracking = OBWFilteringMenuScrollTracking()
    var screenAnchor: NSRect? = nil
    var filterFieldEditor: OBWFilteringMenuFieldEditor? = nil
    var accessibilityActive = false
    
    var roundedCorners: OBWFilteringMenuCorners {
        
        get {
            let backgroundView = self.contentView as! OBWFilteringMenuBackground
            return backgroundView.roundedCorners
        }
        
        set (newValue) {
            let backgroundView = self.contentView as! OBWFilteringMenuBackground
            if backgroundView.roundedCorners == newValue {
                return
            }
            backgroundView.roundedCorners = newValue
            self.invalidateShadow()
            self.displayIfNeeded()
        }
    }
    
    /*==========================================================================*/
    func menuItemAtLocation(_ locationInWindow: NSPoint) -> OBWFilteringMenuItem? {
        let locationInView = self.menuView.convert(locationInWindow, from: nil)
        return self.menuView.menuItemAtLocation(locationInView)
    }
    
    /*==========================================================================*/
    func menuPartAtLocation(_ locationInWindow: NSPoint) -> OBWFilteringMenuPart {
        let locationInView = self.menuView.convert(locationInWindow, from: nil)
        return self.menuView.menuPartAtLocation(locationInView)
    }
    
    /*==========================================================================*/
    @discardableResult
    func displayMenuLocation(_ menuLocation: NSPoint, atScreenLocation screenLocation: NSPoint, allowWindowToGrowUpward: Bool, resetScrollTracking: Bool = true) -> Bool {
        
        let geometry = OBWFilteringMenuWindowGeometry(window: self)
        if geometry.updateGeometryToDisplayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: allowWindowToGrowUpward) == false {
            return false
        }
        
        self.applyWindowGeometry(geometry)
        
        if resetScrollTracking {
            self.scrollTracking.reset(geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds)
        }
        
        return true
    }
    
    /*==========================================================================*/
    func displayMenuLocation(_ menuLocation: NSPoint, adjacentToScreenArea areaInScreen: NSRect, prefrerredAlignment: OBWFilteringMenuAlignment) {
        
        let geometry = OBWFilteringMenuWindowGeometry(window: self)
        let newAlignment = geometry.updateGeometryToDisplayMenuLocation(menuLocation, adjacentToScreenArea: areaInScreen, preferredAlignment: prefrerredAlignment)
        
        self.applyWindowGeometry(geometry)
        self.alignmentFromPrevious = newAlignment
        self.screenAnchor = areaInScreen
        
        self.scrollTracking.reset(geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds)
    }
    
    /*==========================================================================*/
    func displayMenuItemBounds(_ menuItemBounds: NSRect) -> Bool {
        
        let windowGeometry = OBWFilteringMenuWindowGeometry(window: self)
        
        if windowGeometry.updateGeometryToDisplayMenuItemBounds(menuItemBounds) == false {
            return false
        }
        
        self.applyWindowGeometry(windowGeometry)
        
        return true
    }
    
    /*==========================================================================*/
    func displayUpdatedTotalMenuItemSize() -> Bool {
        
        let geometry = OBWFilteringMenuWindowGeometry(window: self)
        if geometry.updateGeometryWithResizedMenu() == false {
            return false
        }
        
        self.applyWindowGeometry(geometry)
        
        self.scrollTracking.reset(geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds)
        
        NotificationCenter.default.post(name: OBWFilteringMenuTotalItemSizeChangedNotification, object: self)
        
        return true
    }
    
    /*==========================================================================*/
    func applyWindowGeometry(_ windowGeometry: OBWFilteringMenuWindowGeometry) {
        
        let currentWindowFrame = self.frame
        let newWindowFrame = windowGeometry.frame
        
        let menuView = self.menuView
        
        if currentWindowFrame == newWindowFrame {
            
            menuView.setMenuItemBoundsOriginY(windowGeometry.initialBounds.origin.y)
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
            menuView.setMenuItemBoundsOriginY(windowGeometry.initialBounds.origin.y)
            
            self.setFrame(newWindowFrame, display: true)
            self.invalidateShadow()
        }
    }
    
    /*==========================================================================*/
    func resetScrollTracking() {
        let geometry = OBWFilteringMenuWindowGeometry(window: self)
        self.scrollTracking.reset(geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds)
    }
}

