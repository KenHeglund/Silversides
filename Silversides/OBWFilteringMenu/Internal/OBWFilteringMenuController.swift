/*===========================================================================
 OBWFilteringMenuController.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa
import Carbon.HIToolbox.Events

/*==========================================================================*/

enum OBWFilteringMenuEventResult {
    case unhandled
    case `continue`
    case cancel
    case interrupt
    case guiSelection
    case accessibleSelection
    case highlight
    case changeFilter
}

/*==========================================================================*/

private let OBWFilteringMenuWindowKey = "OBWFilteringMenuWindowKey"
private let OBWFilteringMenuScrollUpTimerKey = "OBWFilteringMenuScrollUpTimerKey"
private let OBWFilteringMenuScrollDownTimerKey = "OBWFilteringMenuScrollDownTimerKey"

let OBWFilteringMenuAXDidOpenMenuItemNotification = Notification.Name(rawValue: "OBWFilteringMenuAXDidOpenMenuItemNotification")
let OBWFilteringMenuKey = "OBWFilteringMenuKey"
let OBWFilteringMenuItemKey = "OBWFilteringMenuItemKey"

/*==========================================================================*/

class OBWFilteringMenuController {
    
    /*==========================================================================*/
    private init?( menuItem: OBWFilteringMenuItem, atLocation locationInScreen: NSPoint, inScreen screen: NSScreen, highlighted: Bool? ) {
        
        guard let rootMenu = menuItem.menu else { return nil }
        
        let rootMenuWindow = OBWFilteringMenuWindow( menu: rootMenu, screen: screen )
        let menuView = rootMenuWindow.menuView
        
        guard let itemView = menuView.viewForMenuItem( menuItem ) else { return nil }
        let itemViewFrame = itemView.frame
        
        rootMenuWindow.alignmentFromPrevious = .right
        rootMenuWindow.screenAnchor = NSRect(
            x: locationInScreen.x,
            y: locationInScreen.y - itemViewFrame.size.height,
            size: itemViewFrame.size
        )
        
        let menuLocation = NSPoint( x: itemViewFrame.minX, y: itemViewFrame.maxY )
        _ = rootMenuWindow.displayMenuLocation( menuLocation, atScreenLocation: locationInScreen, allowWindowToGrowUpward: false )
        
        let locationInWindow = rootMenuWindow.mouseLocationOutsideOfEventStream
        let locationInView = menuView.convert( locationInWindow, from: nil )
        let menuItemUnderCursor = menuView.menuItemAtLocation( locationInView )
        
        self.lastHitMenuItem = menuItemUnderCursor
        
        if highlighted == true {
            rootMenu.highlightedItem = menuItem
        }
        else if highlighted == nil {
            rootMenu.highlightedItem = menuItemUnderCursor
        }
        
        self.rootMenu = rootMenu
        self.menuWindowArray = [ rootMenuWindow ]
        self.menuWindowWithKeyboardFocus = rootMenuWindow
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver( self, selector: #selector(OBWFilteringMenuController.axDidOpenMenuItem(_:)), name: OBWFilteringMenuAXDidOpenMenuItemNotification, object: nil )
        notificationCenter.addObserver( self, selector: #selector(OBWFilteringMenuController.menuViewTotalItemSizeDidChange(_:)), name: OBWFilteringMenuTotalItemSizeChangedNotification, object: nil )
        notificationCenter.addObserver( self, selector: #selector(OBWFilteringMenuController.externalMenuDidBeginTracking(_:)), name: NSMenu.didBeginTrackingNotification, object: nil )
        notificationCenter.addObserver( self, selector: #selector(OBWFilteringMenuController.scrollTrackingBoundsChanged(_:)), name: OBWFilteringMenuScrollTrackingBoundsChangedNotification, object: nil )
    }
    
    /*==========================================================================*/
    deinit {
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver( self, name: OBWFilteringMenuAXDidOpenMenuItemNotification, object: nil )
        notificationCenter.removeObserver( self, name: OBWFilteringMenuTotalItemSizeChangedNotification, object: nil )
        notificationCenter.removeObserver( self, name: NSMenu.didBeginTrackingNotification, object: nil )
        notificationCenter.removeObserver( self, name: OBWFilteringMenuScrollTrackingBoundsChangedNotification, object: nil )
        
        OBWFilteringMenuCursorTracking.hideDebugWindow()
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuController internal
    
    /*==========================================================================*/
    class func popUpMenuPositioningItem( _ menuItem: OBWFilteringMenuItem, atLocation locationInView: NSPoint, inView view: NSView?, withEvent event: NSEvent? = nil, highlighted: Bool? ) -> Bool {
        
        guard let menu = menuItem.menu else { return false }
        
        guard let screen = event?.obw_screen ?? view?.window?.screen ?? NSScreen.screens.first else { return false }
        
        let locationInScreen = view?.obw_convertPointToScreen( locationInView ) ?? locationInView
        
        guard let controller = OBWFilteringMenuController( menuItem: menuItem, atLocation: locationInScreen, inScreen: screen, highlighted: highlighted ) else { return false }
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.post( name: Notification.Name(rawValue: OBWFilteringMenuWillBeginSessionNotification), object: menu )
        
        let menuItemSelected = controller.runEventLoop()
        
        notificationCenter.post( name: Notification.Name(rawValue: OBWFilteringMenuDidEndSessionNotification), object: menu )
        
        return menuItemSelected
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuController private
    
    private let eventSource = OBWFilteringMenuEventSource()
    
    // These were all determined experimentally by "feel"
    private static let scrollAccelerationFactor = 1.1
    private static let scrollInterval = 0.050
    private static let periodicEventInterval = 0.025
    
    // MARK: - Run Loop
    
    /*==========================================================================*/
    private func runEventLoop() -> Bool {
        
        guard let rootMenuWindow = self.menuWindowArray.first else { return false }
        
        let notificationCenter = NotificationCenter.default
        
        let initialMenu = self.rootMenu
        let userInfo = [ OBWFilteringMenuRootKey : initialMenu ]
        notificationCenter.post( name: Notification.Name(rawValue: OBWFilteringMenuDidBeginTrackingNotification), object: initialMenu, userInfo: userInfo )
        
        rootMenuWindow.makeKeyAndOrderFront( nil )
        
        self.eventSource.eventMask = .ApplicationDidResignActive
        
        let startDate = Date()
        var terminatingEvent: NSEvent? = nil
        
        var result: OBWFilteringMenuEventResult = .continue
        var lastLeftMouseDownResult: OBWFilteringMenuEventResult = .unhandled
        
        while true {
            
            autoreleasepool {
                
                #if DEBUG
                    let timeoutInterval = 10.0 * 60.0
                #else
                    let timeoutInterval = 60.0
                #endif
                
                let timeoutDate = Date( timeIntervalSinceNow: timeoutInterval )
                guard let event = NSApp.nextEvent( matching: NSEvent.EventTypeMask.any, until: timeoutDate, inMode: RunLoop.Mode.default, dequeue: true ) else {
                    result = .cancel
                    return
                }
                
                let currentMenuWindow: OBWFilteringMenuWindow?
                if let locationInScreen = event.obw_locationInScreen {
                    currentMenuWindow = self.menuWindowAtScreenLocation( locationInScreen )
                }
                else {
                    currentMenuWindow = nil
                }
                
                terminatingEvent = event
            
                switch event.type {
                    
                case .applicationDefined:
                    result = self.handleApplicationEvent( event )
                    
                case .keyDown:
                    self.scrollTimer?.fireDate = Date.distantFuture
                    self.endCursorTracking()
                    
                    result = self.handleKeyboardEvent( event )
                    
                    self.lastHitMenuItem = nil
                    
                case .keyUp:
                    break
                    
                case .flagsChanged:
                    result = self.handleFlagsChangedEvent( event )
                    
                case .leftMouseDown:
                    
                    guard let currentMenuWindow = currentMenuWindow else {
                        result = .cancel
                        break
                    }
                    
                    lastLeftMouseDownResult = currentMenuWindow.menuView.handleLeftMouseButtonDownEvent( event )
                    
                    self.makeTopmostMenuWindow( currentMenuWindow, withFade: true )
                    
                case .rightMouseDown:
                    
                    guard let currentMenuWindow = currentMenuWindow else {
                        NSApp.postEvent( event, atStart: true )
                        result = .cancel
                        break
                    }
                    
                    self.makeTopmostMenuWindow( currentMenuWindow, withFade: true )
                    
                case .otherMouseDown:
                    
                    guard let currentMenuWindow = currentMenuWindow else {
                        result = .cancel
                        break
                    }
                    
                    self.makeTopmostMenuWindow( currentMenuWindow, withFade: true )
                    
                case .leftMouseUp:
                    
                    if Date().timeIntervalSince( startDate ) < NSEvent.doubleClickInterval {
                        break
                    }
                    
                    if lastLeftMouseDownResult != .unhandled {
                        lastLeftMouseDownResult = .unhandled
                        break
                    }
                    
                    if let menuItem = self.lastHitMenuItem {
                        self.performActionForItem( menuItem )
                        result = .guiSelection
                    }
                    else {
                        result = .cancel
                    }
                    
                case .mouseMoved, .leftMouseDragged:
                    self.handleMouseMovedEvent( event )
                    
                case .scrollWheel:
                    if let menu = self.lastHitMenuItem?.menu {
                        self.menuWindowForMenu( menu )?.scrollTracking.scrollEvent( event )
                    }
                    
                case .mouseEntered, .mouseExited:
                    break
                    
                case .cursorUpdate:
                    break
                    
                case .systemDefined, .appKitDefined:
                    break
                    
                case .beginGesture, .endGesture:
                    break
                    
                case .pressure:
                    break
                    
                case NSEvent.EventType( rawValue: 21 )!:
                    // This event type does not currently have a symbolic name, but occurs when Expose is activated or deactivated.  It also occurs when right-clicking outside of the current application.
                    result = .cancel
                    
                case NSEvent.EventType( rawValue: 28 )!:
                    //This is an event which appears to be related to screen zooming, but does not have a symbolic constant.
                    break
                    
                default:
                    #if DEBUG
                        Swift.print( "unhandled event type:\(event.type.rawValue)" )
                    #endif
                    break
                }
                
            }
            
            guard result == .continue else { break }
        }
        
        NSApp.discardEvents( matching: NSEvent.EventTypeMask.any, before: terminatingEvent )
        
        self.scrollTimer?.invalidate()
        self.scrollTimer = nil
        
        self.endCursorTracking()
        self.eventSource.eventMask = []
        self.makeTopmostMenuWindow( nil, withFade: result != .interrupt )
        
        return ( result == .guiSelection || result == .accessibleSelection )
    }
    
    /*==========================================================================*/
    private func handleKeyboardEvent( _ event: NSEvent ) -> OBWFilteringMenuEventResult {
        
        let keyCode = Int(event.keyCode)
        
        if keyCode == kVK_Escape {
            
            let menuWindowArray = self.menuWindowArray
            
            guard let topmostMenuWindow = menuWindowArray.last else { return .cancel }
            
            if topmostMenuWindow.accessibilityActive && menuWindowArray.count > 1 {
                
                guard let previousWindow = self.menuWindowBefore( menuWindow: topmostMenuWindow ) else { return .cancel }
                self.makeTopmostMenuWindow( previousWindow, withFade: false )
                return .continue
            }
            else {
                return .cancel
            }
        }
        
        guard let targetMenuWindow = self.menuWindowWithKeyboardFocus else { return .cancel }
        let targetMenu = targetMenuWindow.filteringMenu
        let menuView = targetMenuWindow.menuView
        
        let result = menuView.handleKeyboardEvent( event )
        switch result {
            
        case .continue, .cancel:
            return result
            
        case .highlight:
            self.makeTopmostMenuWindow( targetMenuWindow, withFade: false )
            return .continue
            
        case .changeFilter:
            self.makeTopmostMenuWindow( targetMenuWindow, withFade: false )
            targetMenuWindow.resetScrollTracking()
            return .continue
            
        case .unhandled, .interrupt, .guiSelection, .accessibleSelection:
            break
        }
        
        let highlightedItem = targetMenu.highlightedItem
        
        if keyCode == kVK_ANSI_KeypadEnter {
            
            if let highlightedItem = highlightedItem {
                self.performActionForItem( highlightedItem )
            }
            
            return .guiSelection
        }
        
        if [kVK_Space, kVK_Return, kVK_RightArrow].contains( keyCode ) {
            
            if let highlightedItem = highlightedItem, highlightedItem.submenu != nil {
                
                self.endCursorTracking()
                self.showSubmenu( ofMenuItem: highlightedItem, highlightFirstVisibleItem: true )
                self.menuWindowWithKeyboardFocus = self.menuWindowArray.last
                
                return .continue
            }
            
            if keyCode == kVK_RightArrow {
                return .continue
            }
            
            if let highlightedItem = highlightedItem {
                self.performActionForItem( highlightedItem )
            }
            
            return .guiSelection
        }
        
        if keyCode == kVK_LeftArrow {
            
            if targetMenu !== self.rootMenu {
                self.makeTopmostMenuWindow( self.menuWindowBefore( menuWindow: targetMenuWindow ), withFade: false )
            }
            
            return .continue
        }
        
//        Swift.print( "keyCode: \(keyCode)" )
        
        return .continue
    }
    
    /*==========================================================================*/
    private func handleFlagsChangedEvent( _ event: NSEvent ) -> OBWFilteringMenuEventResult {
        
        self.scrollTimer?.fireDate = Date.distantFuture
        
        guard let targetMenuWindow = self.menuWindowWithKeyboardFocus else { return .cancel }
        
        targetMenuWindow.menuView.handleFlagsChangedEvent( event )
        
        guard !targetMenuWindow.accessibilityActive else { return .continue }
        
        let locationInScreen = NSEvent.mouseLocation
        
        if let menuWindowWithKeyboardFocus = self.menuWindowWithKeyboardFocus {
            
            if self.menuWindowAtScreenLocation( locationInScreen ) === menuWindowWithKeyboardFocus {
                
                self.lastHitMenuItem = nil
                
                if let pseudoEvent = NSEvent.mouseEvent(
                    with: .mouseMoved,
                    location: locationInScreen,
                    modifierFlags: [],
                    timestamp: ProcessInfo().systemUptime,
                    windowNumber: 0,
                    context: nil,
                    eventNumber: 0,
                    clickCount: 0,
                    pressure: 0.0
                    ) {
                    self.updateCurrentMenuItem( pseudoEvent, continueCursorTracking: false )
                }
            }
        }
        
        self.updateMenuCorners()
        
        return .continue
    }
    
    /*==========================================================================*/
    private func handleMouseMovedEvent( _ event: NSEvent ) {
        
        guard let topmostMenuWindow = self.menuWindowArray.last else { return }
        
        if topmostMenuWindow.accessibilityActive {
            
            let modifierKeyMask: NSEvent.ModifierFlags = [ NSEvent.ModifierFlags.shift, NSEvent.ModifierFlags.control, NSEvent.ModifierFlags.option, NSEvent.ModifierFlags.command ]
            let voiceOverKeyMask: NSEvent.ModifierFlags = [ NSEvent.ModifierFlags.control, NSEvent.ModifierFlags.option ]
            
            let eventModifierFlags = event.modifierFlags
            let voiceOverKeysPressed = ( eventModifierFlags.intersection( modifierKeyMask ) == voiceOverKeyMask )
            
            if voiceOverKeysPressed {
                return
            }
        }
        
        guard let eventLocationInScreen = event.obw_locationInScreen else { return }
        
        let locationInWindow = topmostMenuWindow.obw_convertFromScreen( eventLocationInScreen )
        let topmostMenuPart = topmostMenuWindow.menuPartAtLocation( locationInWindow )
        
        switch topmostMenuPart {
            
        case .down:
            
            self.setupAutoscroll( directionKey: OBWFilteringMenuScrollUpTimerKey )
            
        case .up:
            
            self.setupAutoscroll( directionKey: OBWFilteringMenuScrollDownTimerKey )
            
        case .item, .filter, .none:
            
            self.scrollTimer?.invalidate()
            self.scrollTimer = nil
            
            topmostMenuWindow.menuView.cursorUpdate( with: event )
            self.updateCurrentMenuItem( event, continueCursorTracking: true )
        }
    }
    
    /*==========================================================================*/
    private func handleApplicationEvent( _ event: NSEvent ) -> OBWFilteringMenuEventResult {
        
        switch event.subtype.rawValue {
            
        case OBWApplicationEventSubtype.ApplicationDidResignActive.rawValue:
            #if CONTINUE_ON_RESIGN_ACTIVE
                return .Continue
            #else
                return .interrupt
            #endif
            
        case OBWApplicationEventSubtype.AccessibleItemSelection.rawValue:
            return .accessibleSelection
            
        case OBWApplicationEventSubtype.Periodic.rawValue:
            self.updateCurrentMenuItem( event, continueCursorTracking: true )
            return .continue
            
        default:
            Swift.print( "Unhandled application-defined event subtype: \(event.subtype.rawValue)" )
            return .continue
        }
    }
    
    // MARK: - Menu
    
    private let rootMenu: OBWFilteringMenu
    
    /*==========================================================================*/
    var topmostMenu: OBWFilteringMenu? {
        return self.menuWindowArray.last?.filteringMenu
    }
    
    weak private var lastHitMenuItem: OBWFilteringMenuItem? = nil
    
    /*==========================================================================*/
    private func updateCurrentMenuItem( _ event: NSEvent, continueCursorTracking: Bool ) {
        
        let eventLocationInScreen = event.obw_locationInScreen ?? NSEvent.mouseLocation
        
        let currentMenuWindow = self.menuWindowAtScreenLocation( eventLocationInScreen )
        let currentMenu = currentMenuWindow?.filteringMenu
        let locationInWindow = currentMenuWindow?.obw_convertFromScreen( eventLocationInScreen ) ?? NSZeroPoint
        let currentMenuItem = currentMenuWindow?.menuItemAtLocation( locationInWindow )
        
        let previousMenuItem = self.lastHitMenuItem
        let previousMenu = previousMenuItem?.menu
        let previousMenuWindow = ( previousMenu != nil ? self.menuWindowForMenu( previousMenu! ) : nil )
        
        self.lastHitMenuItem = currentMenuItem
        
        if let currentMenuWindow = currentMenuWindow {
            self.menuWindowWithKeyboardFocus = currentMenuWindow
        }
        
        if currentMenuWindow !== previousMenuWindow {
            currentMenuWindow?.resetScrollTracking()
        }
        
        if let cursorTracking = self.cursorTracking {
            
            if currentMenu === cursorTracking.sourceMenuItem.submenu {
                // Cursor has arrived in the submenu
                self.endCursorTracking()
            }
            else if currentMenuItem === cursorTracking.sourceMenuItem {
                // Cursor is still in the source menu item
                currentMenu?.highlightedItem = currentMenuItem
                self.updateCursorTracking()
                return
            }
            else if !continueCursorTracking {
                // The cursor is between source and submenu but must be interrupted
                self.endCursorTracking()
                self.removeTopmostMenuWindow( withFade: false )
            }
            else if cursorTracking.isCursorProgressingTowardSubmenu( event ) {
                // The cursor continues to make progress toward the submenu
                return
            }
            else {
                // The cursor is no longer making progress toward the submenu
                self.endCursorTracking()
                self.removeTopmostMenuWindow( withFade: true )
                self.delayedShowSubmenu( ofMenuItem: nil )
            }
        }
        
        if let currentMenu = currentMenu {
            
            if currentMenu === self.topmostMenu {
                
                // The cursor is somewhere in the topmost menu
                
                currentMenu.highlightedItem = currentMenuItem
                
                self.delayedShowSubmenu( ofMenuItem: currentMenuItem )
            }
            else {
                
                if let currentMenuItem = currentMenuItem, let submenu = currentMenuItem.submenu, let submenuWindow = self.menuWindowForMenu( submenu ) {
                    
                    // The cursor has circled back to an item whose submenu is already open
                    
                    self.makeTopmostMenuWindow( submenuWindow, withFade: false )
                    
                    submenu.highlightedItem = nil
                    
                    self.beginCursorTracking( currentMenuItem )
                }
                else if let currentMenuWindow = self.menuWindowForMenu( currentMenu ) {
                    
                    // The cursor has circled back to an unselected item in a menu that had already been opened
                    
                    self.makeTopmostMenuWindow( currentMenuWindow, withFade: false )
                    
                    if let currentMenuItem = currentMenuItem {
                        self.delayedShowSubmenu( ofMenuItem: currentMenuItem )
                    }
                }
            }
        }
        else {
            
            // The cursor is outside of all menus
            
            self.topmostMenu?.highlightedItem = nil
        }
    }
    
    private var delayedSubmenuGeneration = 0
    private weak var delayedSubmenuParent: OBWFilteringMenuItem? = nil
    
    /*==========================================================================*/
    private func delayedShowSubmenu( ofMenuItem menuItem: OBWFilteringMenuItem? ) {
        
        guard menuItem !== self.delayedSubmenuParent else { return }
        
        self.delayedSubmenuParent = menuItem
        
        let generation = self.delayedSubmenuGeneration + 1
        self.delayedSubmenuGeneration = generation
        
        guard let menuItem = menuItem, menuItem.submenu != nil else { return }
        
        let delta = 0.100 * Double(NSEC_PER_SEC)
        let when = DispatchTime.now() + Double(Int64(delta)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter( deadline: when) {
            
            guard generation == self.delayedSubmenuGeneration else { return }
            guard let menu = menuItem.menu else { return }
            guard menu === self.topmostMenu else { return }
            
            self.showSubmenu( ofMenuItem: menuItem, highlightFirstVisibleItem: false )
            self.beginCursorTracking( menuItem )
        }
    }
    
    /*==========================================================================*/
    private func showSubmenu( ofMenuItem menuItem: OBWFilteringMenuItem, highlightFirstVisibleItem: Bool ) {
        
        guard let newMenu = menuItem.submenu else { return }
        
        // A menu delegate is allowed to populate menu items at this point
        newMenu.willBeginTracking()
        
        if newMenu.itemArray.isEmpty { return }
        
        guard let parentMenu = menuItem.menu else { return }
        guard let parentMenuWindow = self.menuWindowForMenu( parentMenu ) else { return }
        guard let screen = parentMenuWindow.screen else { return }
        guard let itemView = parentMenuWindow.menuView.viewForMenuItem( menuItem ) else { return }
        
        let newWindow = OBWFilteringMenuWindow( menu: newMenu, screen: screen )
        let newMenuView = newWindow.menuView
        
        self.menuWindowArray.append( newWindow )
        
        if highlightFirstVisibleItem {
            newMenuView.selectFirstMenuItemView()
        }
        
        let menuItemBounds = newMenuView.menuItemBounds
        let menuLocation = NSPoint( x: menuItemBounds.minX, y: menuItemBounds.maxY )
        
        newWindow.displayMenuLocation( menuLocation, adjacentToScreenArea: itemView.obw_boundsInScreen, prefrerredAlignment: parentMenuWindow.alignmentFromPrevious )
        
        self.updateMenuCorners()
        
        newWindow.makeKeyAndOrderFront( nil )
        
        let userInfo: [String:AnyObject] = [ OBWFilteringMenuRootKey : self.rootMenu ]
        NotificationCenter.default.post( name: Notification.Name(rawValue: OBWFilteringMenuDidBeginTrackingNotification), object: newMenu, userInfo: userInfo )
    }
    
    /*==========================================================================*/
    private func performActionForItem( _ menuItem: OBWFilteringMenuItem ) {
        
        guard let menu = menuItem.menu else { return }
        guard let menuWindow = self.menuWindowForMenu( menu ) else { return }
        guard let itemView = menuWindow.menuView.viewForMenuItem( menuItem ) else { return }
        
        let runLoop = RunLoop.current
        let blinkInterval = 0.025
        let blinkCount = 2
        
        for _ in 1...blinkCount {
            
            menu.highlightedItem = nil
            itemView.needsDisplay = true
            menuWindow.display()
            
            // It seems that the run loop needs to run at least once to actually get the window to redraw.  Previously, a -display message to the window was sufficient to get an immediate redraw.  This may be a side-effect of running a custom event loop in 10.11 El Capitan.
            
            runLoop.run( mode: RunLoop.Mode.default, before: Date( timeIntervalSinceNow: blinkInterval ) )
            Thread.sleep( forTimeInterval: blinkInterval )
            
            menu.highlightedItem = menuItem
            itemView.needsDisplay = true
            menuWindow.display()
            
            runLoop.run( mode: RunLoop.Mode.default, before: Date( timeIntervalSinceNow: blinkInterval ) )
            Thread.sleep( forTimeInterval: blinkInterval )
        }
        
        menuItem.performAction()
    }
    
    // MARK: - Menu Windows
    
    private var menuWindowArray: [OBWFilteringMenuWindow] = []
    weak private var menuWindowWithKeyboardFocus: OBWFilteringMenuWindow? = nil
    
    /*==========================================================================*/
    private func makeTopmostMenuWindow( _ topmostMenuWindow: OBWFilteringMenuWindow?, withFade fade: Bool ) {
        
        if topmostMenuWindow === self.menuWindowArray.last {
            return
        }
        
        let notificationCenter = NotificationCenter.default
        let userInfo: [String:AnyObject] = [ OBWFilteringMenuRootKey : self.rootMenu ]
        
        var terminatedMenuWindows: [OBWFilteringMenuWindow] = []
        
        for menuWindow in self.menuWindowArray.reversed() {
            
            if menuWindow === topmostMenuWindow { break }
            
            let menu = menuWindow.filteringMenu
            
            notificationCenter.post( name: Notification.Name(rawValue: OBWFilteringMenuWillEndTrackingNotification), object: menuWindow, userInfo: userInfo )
            
            menu.highlightedItem = nil
            
            if !fade {
                menuWindow.animationBehavior = .none
            }
            else {
                menuWindow.animationBehavior = .default
            }
            
            menuWindow.close()
            
            terminatedMenuWindows.append( menuWindow )
        }
        
        for window in terminatedMenuWindows {
            guard let index = self.menuWindowArray.index( of: window ) else { continue }
            self.menuWindowArray.remove( at: index )
        }
        
        self.updateMenuCorners()
        self.menuWindowWithKeyboardFocus = topmostMenuWindow
        
        topmostMenuWindow?.makeKeyAndOrderFront( nil )
    }
    
    /*==========================================================================*/
    private func menuWindowForMenu( _ menu: OBWFilteringMenu ) -> OBWFilteringMenuWindow? {
        
        for window in self.menuWindowArray.reversed() {
            
            if window.filteringMenu === menu {
                return window
            }
        }
        
        return nil
    }
    
    /*==========================================================================*/
    private func menuWindowAtScreenLocation( _ screenLocation: NSPoint ) -> OBWFilteringMenuWindow? {
        
        for window in self.menuWindowArray.reversed() {
            
            if NSPointInRect( screenLocation, window.frame ) {
                return window
            }
        }
        
        return nil
    }
    
    /*==========================================================================*/
    private func menuWindowBefore( menuWindow anchorWindow: OBWFilteringMenuWindow ) -> OBWFilteringMenuWindow? {
        
        var window: OBWFilteringMenuWindow? = nil
        
        for testWindow in self.menuWindowArray {
            
            if testWindow === anchorWindow {
                return window
            }
            
            window = testWindow
        }
        
        return nil
    }
    
    /*==========================================================================*/
    private func isMenuWindow( _ firstWindow: OBWFilteringMenuWindow, afterMenuWindow secondWindow: OBWFilteringMenuWindow ) -> Bool {
        
        guard let firstIndex = self.menuWindowArray.index( of: firstWindow ) else { return false }
        guard let secondIndex = self.menuWindowArray.index( of: secondWindow ) else { return false }
        
        return firstIndex > secondIndex
    }
    
    /*==========================================================================*/
    private func removeTopmostMenuWindow( withFade fade: Bool ) {
        
        guard let topmostMenuWindow = self.menuWindowArray.last else { return }
        guard let newTopMostMenuWindow = self.menuWindowBefore( menuWindow: topmostMenuWindow ) else { return }
        self.makeTopmostMenuWindow( newTopMostMenuWindow, withFade: fade )
    }
    
    /*==========================================================================*/
    private func updateMenuCorners() {
        
        guard let firstWindow = self.menuWindowArray.last else { return }
        
        let menuCount = self.menuWindowArray.count
        
        if menuCount >= 2 {
            
            let secondWindow = self.menuWindowArray[menuCount-2]
            
            if firstWindow.alignmentFromPrevious == .right {
                self.updateRoundedCornersBetween( leftWindow: secondWindow, rightWindow: firstWindow )
                firstWindow.roundedCorners.formUnion( [ .topRight, .bottomRight ] )
            }
            else {
                self.updateRoundedCornersBetween( leftWindow: firstWindow, rightWindow: secondWindow )
                firstWindow.roundedCorners.formUnion( [ .topLeft, .bottomLeft ] )
            }
        }
        else {
            firstWindow.roundedCorners = .all
        }
    }
    
    /*==========================================================================*/
    private func updateRoundedCornersBetween( leftWindow: OBWFilteringMenuWindow, rightWindow: OBWFilteringMenuWindow ) {
        
        if leftWindow.frame.maxY > rightWindow.frame.maxY {
            leftWindow.roundedCorners.insert( .topRight )
        }
        else {
            leftWindow.roundedCorners.remove( .topRight )
        }
        
        if leftWindow.frame.minY < rightWindow.frame.minY {
            leftWindow.roundedCorners.insert( .bottomRight )
        }
        else {
            leftWindow.roundedCorners.remove( .bottomRight )
        }
        
        if rightWindow.frame.maxY > leftWindow.frame.maxY {
            rightWindow.roundedCorners.insert( .topLeft )
        }
        else {
            rightWindow.roundedCorners.remove( .topLeft )
        }
        
        if rightWindow.frame.minY < leftWindow.frame.minY {
            rightWindow.roundedCorners.insert( .bottomLeft )
        }
        else {
            rightWindow.roundedCorners.remove( .bottomLeft )
        }
    }
    
    // MARK: - Cursor Tracking
    
    private var cursorTracking: OBWFilteringMenuCursorTracking? = nil
    
    /*==========================================================================*/
    private func beginCursorTracking( _ menuItem: OBWFilteringMenuItem ) {
        
        guard let menu = menuItem.menu else { return }
        guard let window = self.menuWindowForMenu( menu ) else { return }
        guard let itemView = window.menuView.viewForMenuItem( menuItem ) else { return }
        let itemViewBoundsInScreen = itemView.obw_boundsInScreen
        
        let sourceLine = NSRect(
            x: NSEvent.mouseLocation.x,
            y: itemViewBoundsInScreen.origin.y,
            width: 0.0,
            height: itemViewBoundsInScreen.size.height
        )
        
        guard let submenu = menuItem.submenu else { return }
        guard let submenuWindow = self.menuWindowForMenu( submenu ) else { return }
        let destinationArea = submenuWindow.frame
        
        self.cursorTracking = OBWFilteringMenuCursorTracking( subviewOfItem: menuItem, fromSourceLine: sourceLine, toArea: destinationArea )
        
        let interval = OBWFilteringMenuController.periodicEventInterval
        self.eventSource.startPeriodicApplicationEventsAfterDelay( interval, withPeriod: interval )
    }
    
    /*==========================================================================*/
    private func updateCursorTracking() {
        
        guard let cursorTracking = self.cursorTracking else { return }
        
        let menuItem = cursorTracking.sourceMenuItem
        guard let menu = menuItem.menu else { return }
        guard let window = self.menuWindowForMenu( menu ) else { return }
        guard let itemView = window.menuView.viewForMenuItem( menuItem ) else { return }
        
        let itemViewBoundsInScreen = itemView.obw_boundsInScreen
        
        let sourceLine = NSRect(
            x: NSEvent.mouseLocation.x,
            y: itemViewBoundsInScreen.origin.y,
            width: 0.0,
            height: itemViewBoundsInScreen.size.height
        )
        
        cursorTracking.sourceLine = sourceLine
    }
    
    /*==========================================================================*/
    private func endCursorTracking() {
        
        if self.cursorTracking == nil { return }
        
        self.eventSource.stopPeriodicApplicationEvents()
        self.cursorTracking = nil
    }
    
    /*==========================================================================*/
    @objc private func scrollTrackingBoundsChanged( _ notification: Notification ) {
        
        let scrollTracking = notification.object as! OBWFilteringMenuScrollTracking
        let boundsValue = notification.userInfo?[OBWFilteringMenuScrollTrackingBoundsValueKey] as! NSValue
        let menuItemBounds = boundsValue.rectValue
        
        guard let windowIndex = self.menuWindowArray.index(where: { $0.scrollTracking === scrollTracking }) else { return }
        let window = self.menuWindowArray[windowIndex]
        _ = window.displayMenuItemBounds( menuItemBounds )
        
        guard let pseudoEvent = NSEvent.mouseEvent(
            with: .mouseMoved,
            location: NSEvent.mouseLocation,
            modifierFlags: [],
            timestamp: ProcessInfo().systemUptime,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 0,
            pressure: 0.0
            ) else { return }
        
        self.updateCurrentMenuItem( pseudoEvent, continueCursorTracking: false )
        self.updateMenuCorners()
    }
    
    // MARK: - Scrolling
    
    weak private var scrollTimer: Timer? = nil
    private var scrollStartInterval: TimeInterval = 0.0
    
    /*==========================================================================*/
    private func setupAutoscroll( directionKey: String ) {
        
        if
            let userInfo = self.scrollTimer?.userInfo as? [String:Any],
            userInfo[directionKey] as? Bool == true {
            return
        }
        
        guard let topmostMenuWindow = self.menuWindowArray.last else { return }
        let topmostMenu = topmostMenuWindow.filteringMenu
        
        topmostMenu.highlightedItem = nil
        
        self.scrollTimer?.invalidate()
        
        let userInfo: [String:AnyObject] = [
            OBWFilteringMenuWindowKey : topmostMenuWindow,
            directionKey : true as AnyObject
        ]
        
        self.scrollTimer = Timer.scheduledTimer(
            timeInterval: OBWFilteringMenuController.scrollInterval,
            target: self,
            selector: #selector(OBWFilteringMenuController.scrollTimerDidFire(_:)),
            userInfo: userInfo,
            repeats: true
        )
        
        guard let scrollTimer = self.scrollTimer else { return }
        
        self.scrollStartInterval = Date.timeIntervalSinceReferenceDate
        self.scrollTimerDidFire( scrollTimer )
    }
    
    /*==========================================================================*/
    @objc private func scrollTimerDidFire( _ timer: Timer ) {
        
        guard let userInfo = timer.userInfo as? [String:Any] else { return }
        guard let scrolledWindow = userInfo[OBWFilteringMenuWindowKey] as? OBWFilteringMenuWindow else { return }
        
        let upDirection = userInfo[OBWFilteringMenuScrollUpTimerKey] as? Bool ?? false
        let downDirection = userInfo[OBWFilteringMenuScrollDownTimerKey] as? Bool ?? false
        assert( upDirection || downDirection )
        
        let scrollDuration = Date.timeIntervalSinceReferenceDate - self.scrollStartInterval
        
        let acceleration: Double
        if scrollDuration > 1.0 {
            acceleration = pow( OBWFilteringMenuController.scrollAccelerationFactor, ( scrollDuration - 1.0 ) )
        }
        else {
            acceleration = 1.0
        }
        
        if upDirection && scrolledWindow.menuView.scrollItemsUpWithAcceleration( acceleration ) {
            self.scrollTimer?.invalidate()
            self.scrollTimer = nil
        }
        else if downDirection && scrolledWindow.menuView.scrollItemsDownWithAcceleration( acceleration ) {
            self.scrollTimer?.invalidate()
            self.scrollTimer = nil
        }
        
        scrolledWindow.resetScrollTracking()
        self.updateMenuCorners()
    }
    
    // MARK: - External Notifications
    
    /*==========================================================================*/
    @objc private func axDidOpenMenuItem( _ notification: Notification ) {
        
        guard let userInfo = notification.userInfo else { return }
        guard let menuItem = userInfo[OBWFilteringMenuItemKey] as? OBWFilteringMenuItem else { return }
        
        guard self.topmostMenu === menuItem.menu else { return }
        
        if menuItem.submenu != nil {
            self.showSubmenu( ofMenuItem: menuItem, highlightFirstVisibleItem: false )
            self.menuWindowWithKeyboardFocus = self.menuWindowArray.last
        }
        else if menuItem.enabled {
            
            self.performActionForItem( menuItem )
            
            if let pseudoEvent = NSEvent.otherEvent(
            with: .applicationDefined,
            location: NSZeroPoint,
            modifierFlags: [],
            timestamp: ProcessInfo().systemUptime,
            windowNumber: 0,
            context: nil,
            subtype: OBWApplicationEventSubtype.AccessibleItemSelection.rawValue,
            data1: 0,
            data2: 0
                ) {
                NSApp.postEvent( pseudoEvent, atStart: true )
            }
        }
    }
    
    /*==========================================================================*/
    @objc private func menuViewTotalItemSizeDidChange( _ notification: Notification ) {
        self.updateMenuCorners()
    }
    
    /*==========================================================================*/
    @objc private func externalMenuDidBeginTracking( _ notification: Notification ) {
        self.makeTopmostMenuWindow( nil, withFade: true )
    }
}
