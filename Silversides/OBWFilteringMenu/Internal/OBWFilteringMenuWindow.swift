/*===========================================================================
 OBWFilteringMenuWindow.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit

class OBWFilteringMenuWindow: NSWindow {
    
    /// Initialization.
    init(menu: OBWFilteringMenu, onScreen screen: NSScreen, minimumWidth: CGFloat? = nil) {
        
        self.filteringMenu = menu
        
        let menuView = OBWFilteringMenuView(menu: menu, minimumWidth: minimumWidth)
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
        #if DEBUG_MENU_ITEM_BASELINE
        self.alphaValue = 0.5
        #endif
        
        let contentView = OBWFilteringMenuBackground(frame: contentFrame)
        contentView.autoresizingMask = [.width, .height]
        contentView.addSubview(menuView)
        self.contentView = contentView
    }
    
    
    // MARK: - NSWindow
    
    /// The window can become the key window to allow text entry in the filter field.
    override var canBecomeKey: Bool {
        return true
    }
    
    /// The window cannot become a main window.
    override var canBecomeMain: Bool {
        return false
    }
    
    
    // MARK: - NSAccessibility implementation
    
    /// Returns the subrole of the window.
    override func accessibilitySubrole() -> NSAccessibility.Subrole? {
        self.accessibilityActivePre10_13 = true
        return NSAccessibility.Subrole.standardWindow
    }
    
    /// Returns the standard description of a standard window.
    override func accessibilityRoleDescription() -> String? {
        self.accessibilityActivePre10_13 = true
        return NSAccessibility.Role.window.description(with: NSAccessibility.Subrole.standardWindow)
    }
    
    /// Returns the value description of the window.
    override func accessibilityValueDescription() -> String? {
        self.accessibilityActivePre10_13 = true
        let title = self.filteringMenu.title as NSString
        return title.lastPathComponent
    }
    
    
    // MARK: - OBWFilteringMenuWindow Implementation
    
    /// Returns the margins between the frame of the window and the main menu view.
    static let interiorMargins = NSEdgeInsets(top: 4.0, left: 0.0, bottom: 4.0, right: 0.0)
    
    /// Returns the absolute minimum window size.
    static let minimumFrameSize = NSSize(
        width: 80.0 + OBWFilteringMenuBackground.roundedCornerRadius * 2.0,
        height: OBWFilteringMenuBackground.roundedCornerRadius * 2.0
    )
    
    /// The window's filtering menu.
    let filteringMenu: OBWFilteringMenu
    
    /// The main menu view.
    unowned let menuView: OBWFilteringMenuView
    
    /// This window's alignment from the previous window if this window contains a submenu.
    var alignmentFromPrevious = OBWFilteringMenu.SubmenuAlignment.right
    
    /// The window's scroll tracking object.
    let scrollTracking: OBWFilteringMenuScrollTracking = OBWFilteringMenuScrollTracking()
    
    /// The screen area that this window is bound to.  Typically the area of a menu item that opened a submenu.
    var screenAnchor: NSRect? = nil
    
    /// Returns whether accessibility is currently active.
    var accessibilityActive: Bool {
        if #available(macOS 10.13, *) {
            return NSWorkspace.shared.isVoiceOverEnabled
        }
        else {
            // Pre 10.13, this is inferred by having had an accessibility API called.
            return self.accessibilityActivePre10_13
        }
    }
    
    /// If `true` then an accessibility API has been called.
    private var accessibilityActivePre10_13 = false
    
    /// The corners of the window that have a rounded appearance.  These are the corners that are not directly adjacent to another menu window.
    var roundedCorners: OBWFilteringMenuCorners {
        
        get {
            guard let backgroundView = self.contentView as? OBWFilteringMenuBackground else {
                assertionFailure()
                return []
            }
            
            return backgroundView.roundedCorners
        }
        
        set (newValue) {
            
            guard let backgroundView = self.contentView as? OBWFilteringMenuBackground else {
                assertionFailure()
                return
            }
            
            if backgroundView.roundedCorners == newValue {
                return
            }
            
            backgroundView.roundedCorners = newValue
            self.invalidateShadow()
        }
    }
    
    /// Returns the menu item at the given location.
    /// - parameter locationInWindow: A location in the window's coordinate system.
    func menuItemAtLocation(_ locationInWindow: NSPoint) -> OBWFilteringMenuItem? {
        let locationInView = self.menuView.convert(locationInWindow, from: nil)
        return self.menuView.menuItemAtLocation(locationInView)
    }
    
    /// Returns the menu part at the given location.
    /// - parameter locationInWindow: A location in the window's coordinate system.
    func menuPartAtLocation(_ locationInWindow: NSPoint) -> OBWFilteringMenu.MenuPart {
        let locationInView = self.menuView.convert(locationInWindow, from: nil)
        return self.menuView.menuPartAtLocation(locationInView)
    }
    
    /// Position the window such that a location in the menu coincides with a screen location.
    /// - parameter menuLocation: A location in the menu view's coordinate system.
    /// - parameter screenLocation: A location in global coordinates.
    /// - parameter allowWindowToGrowUpward: If `true`, the window may appear above the requested location to avoid clipping menu items at the bottom of the screen.  If `false` and the menu is too large vertically to display all of the items, the bottom of the menu will be clipped.
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
    
    /// Position the window such that a location in the menu appears adjacent to an area on the screen.  This is used to position a submenu alongside the menu item that opened it.
    /// - parameter menuLocation: A location in the menu view's coordinate system.
    /// - parameter areaInScreen: A rectangle in global coordinates.
    /// - parameter preferredAlignment: The preferred side of `areaInScreen` that the receiver should be located.  The screen bounds may override this preference.
    func displayMenuLocation(_ menuLocation: NSPoint, adjacentToScreenArea areaInScreen: NSRect, preferredAlignment: OBWFilteringMenu.SubmenuAlignment) {
        
        let geometry = OBWFilteringMenuWindowGeometry(window: self)
        let newAlignment = geometry.updateGeometryToDisplayMenuLocation(menuLocation, adjacentToScreenArea: areaInScreen, preferredAlignment: preferredAlignment)
        
        self.applyWindowGeometry(geometry)
        self.alignmentFromPrevious = newAlignment
        self.screenAnchor = areaInScreen
        
        self.scrollTracking.reset(geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds)
    }
    
    /// Sizes the window to display the given menu item bounds.
    /// - parameter menuItemBounds: A bounds in the menu view coordinate system.
    func displayMenuItemBounds(_ menuItemBounds: NSRect) -> Bool {
        
        let windowGeometry = OBWFilteringMenuWindowGeometry(window: self)
        
        if windowGeometry.updateGeometryToDisplayMenuItemBounds(menuItemBounds) == false {
            return false
        }
        
        self.applyWindowGeometry(windowGeometry)
        
        return true
    }
    
    /// Sizes the window to display the menu after the size of its menu items changes.
    func displayUpdatedTotalMenuItemSize(constrainToAnchor: Bool) {
        
        let geometry = OBWFilteringMenuWindowGeometry(window: self)
        geometry.updateGeometryWithResizedMenu(constrainToAnchor: constrainToAnchor)
        
        self.applyWindowGeometry(geometry)
        
        self.scrollTracking.reset(geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds)
        
        NotificationCenter.default.post(name: OBWFilteringMenuWindow.totalItemSizeChangedNotification, object: self)
    }
    
    /// Sizes and positions the window according to the given geometry object.
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
            
            self.setFrame(newWindowFrame, display: false)
            self.invalidateShadow()
        }
    }
    
    /// Resets the scroll tracking object.
    func resetScrollTracking() {
        let geometry = OBWFilteringMenuWindowGeometry(window: self)
        self.scrollTracking.reset(geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds)
    }
    
}


// MARK: -

extension OBWFilteringMenuWindow {
    
    /// The total size of the menu's items changed.
    /// - parameter object: The window containing the menu.
    /// - parameter userInfo: None.
    static let totalItemSizeChangedNotification = Notification.Name(rawValue: "OBWFilteringMenuTotalItemSizeChangedNotification")
}

