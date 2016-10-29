/*===========================================================================
 OBWFilteringMenuController.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa
import Carbon.HIToolbox.Events

/*==========================================================================*/

enum OBWFilteringMenuEventResult {
    case Unhandled
    case Continue
    case Cancel
    case Interrupt
    case GUISelection
    case AccessibleSelection
    case Highlight
    case ChangeFilter
}

/*==========================================================================*/

private let OBWFilteringMenuWindowKey = "OBWFilteringMenuWindowKey"
private let OBWFilteringMenuScrollUpTimerKey = "OBWFilteringMenuScrollUpTimerKey"
private let OBWFilteringMenuScrollDownTimerKey = "OBWFilteringMenuScrollDownTimerKey"

let OBWFilteringMenuAXDidOpenMenuItemNotification = "OBWFilteringMenuAXDidOpenMenuItemNotification"
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
        
        rootMenuWindow.alignmentFromPrevious = .Right
        rootMenuWindow.screenAnchor = NSRect(
            x: locationInScreen.x,
            y: locationInScreen.y - itemViewFrame.size.height,
            size: itemViewFrame.size
        )
        
        let menuLocation = NSPoint( x: itemViewFrame.minX, y: itemViewFrame.maxY )
        rootMenuWindow.displayMenuLocation( menuLocation, atScreenLocation: locationInScreen, allowWindowToGrowUpward: false )
        
        let locationInWindow = rootMenuWindow.mouseLocationOutsideOfEventStream
        let locationInView = menuView.convertPoint( locationInWindow, fromView: nil )
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
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver( self, selector: #selector(OBWFilteringMenuController.axDidOpenMenuItem(_:)), name: OBWFilteringMenuAXDidOpenMenuItemNotification, object: nil )
        notificationCenter.addObserver( self, selector: #selector(OBWFilteringMenuController.menuViewTotalItemSizeDidChange(_:)), name: OBWFilteringMenuTotalItemSizeChangedNotification, object: nil )
        notificationCenter.addObserver( self, selector: #selector(OBWFilteringMenuController.externalMenuDidBeginTracking(_:)), name: NSMenuDidBeginTrackingNotification, object: nil )
        notificationCenter.addObserver( self, selector: #selector(OBWFilteringMenuController.scrollTrackingBoundsChanged(_:)), name: OBWFilteringMenuScrollTrackingBoundsChangedNotification, object: nil )
    }
    
    /*==========================================================================*/
    deinit {
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver( self, name: OBWFilteringMenuAXDidOpenMenuItemNotification, object: nil )
        notificationCenter.removeObserver( self, name: OBWFilteringMenuTotalItemSizeChangedNotification, object: nil )
        notificationCenter.removeObserver( self, name: NSMenuDidBeginTrackingNotification, object: nil )
        notificationCenter.removeObserver( self, name: OBWFilteringMenuScrollTrackingBoundsChangedNotification, object: nil )
        
        OBWFilteringMenuCursorTracking.hideDebugWindow()
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuController internal
    
    /*==========================================================================*/
    class func popUpMenuPositioningItem( menuItem: OBWFilteringMenuItem, atLocation locationInView: NSPoint, inView view: NSView?, withEvent event: NSEvent? = nil, highlighted: Bool? ) -> Bool {
        
        guard let menu = menuItem.menu else { return false }
        
        guard let screen = event?.obw_screen ?? view?.window?.screen ?? NSScreen.screens()?.first else { return false }
        
        let locationInScreen = view?.obw_convertPointToScreen( locationInView ) ?? locationInView
        
        guard let controller = OBWFilteringMenuController( menuItem: menuItem, atLocation: locationInScreen, inScreen: screen, highlighted: highlighted ) else { return false }
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.postNotificationName( OBWFilteringMenuWillBeginSessionNotification, object: menu )
        
        let menuItemSelected = controller.runEventLoop()
        
        notificationCenter.postNotificationName( OBWFilteringMenuDidEndSessionNotification, object: menu )
        
        return menuItemSelected
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuController private
    
    private let eventSource = OBWFilteringMenuEventSource()
    
    // These were all determined experimentally by "feel"
    private static let scrollAccelerationFactor = 1.1
    private static let scrollInterval = 0.050
    private static let periodicEventInterval = 0.025
    
    // MARK: Run Loop
    
    /*==========================================================================*/
    private func runEventLoop() -> Bool {
        
        guard let rootMenuWindow = self.menuWindowArray.first else { return false }
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        let initialMenu = self.rootMenu
        let userInfo = [ OBWFilteringMenuRootKey : initialMenu ]
        notificationCenter.postNotificationName( OBWFilteringMenuDidBeginTrackingNotification, object: initialMenu, userInfo: userInfo )
        
        rootMenuWindow.makeKeyAndOrderFront( nil )
        
        self.eventSource.eventMask = .ApplicationDidResignActive
        
        let startDate = NSDate()
        var terminatingEvent: NSEvent? = nil
        
        var result: OBWFilteringMenuEventResult = .Continue
        var lastLeftMouseDownResult: OBWFilteringMenuEventResult = .Unhandled
        
        while true {
            
            autoreleasepool {
                
                #if DEBUG
                    let timeoutInterval = 10.0 * 60.0
                #else
                    let timeoutInterval = 60.0
                #endif
                
                let timeoutDate = NSDate( timeIntervalSinceNow: timeoutInterval )
                guard let event = NSApp.nextEventMatchingMask( NSEventMask.Any, untilDate: timeoutDate, inMode: NSDefaultRunLoopMode, dequeue: true ) else {
                    result = .Cancel
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
                    
                case .ApplicationDefined:
                    result = self.handleApplicationEvent( event )
                    
                case .KeyDown:
                    self.scrollTimer?.fireDate = NSDate.distantFuture()
                    self.endCursorTracking()
                    
                    result = self.handleKeyboardEvent( event )
                    
                    self.lastHitMenuItem = nil
                    
                case .KeyUp:
                    break
                    
                case .FlagsChanged:
                    result = self.handleFlagsChangedEvent( event )
                    
                case .LeftMouseDown:
                    
                    guard let currentMenuWindow = currentMenuWindow else {
                        result = .Cancel
                        break
                    }
                    
                    lastLeftMouseDownResult = currentMenuWindow.menuView.handleLeftMouseButtonDownEvent( event )
                    
                    self.makeTopmostMenuWindow( currentMenuWindow, withFade: true )
                    
                case .RightMouseDown:
                    
                    guard let currentMenuWindow = currentMenuWindow else {
                        NSApp.postEvent( event, atStart: true )
                        result = .Cancel
                        break
                    }
                    
                    self.makeTopmostMenuWindow( currentMenuWindow, withFade: true )
                    
                case .OtherMouseDown:
                    
                    guard let currentMenuWindow = currentMenuWindow else {
                        result = .Cancel
                        break
                    }
                    
                    self.makeTopmostMenuWindow( currentMenuWindow, withFade: true )
                    
                case .LeftMouseUp:
                    
                    if NSDate().timeIntervalSinceDate( startDate ) < NSEvent.doubleClickInterval() {
                        break
                    }
                    
                    if lastLeftMouseDownResult != .Unhandled {
                        lastLeftMouseDownResult = .Unhandled
                        break
                    }
                    
                    if let menuItem = self.lastHitMenuItem {
                        self.performActionForItem( menuItem )
                        result = .GUISelection
                    }
                    else {
                        result = .Cancel
                    }
                    
                case .MouseMoved, .LeftMouseDragged:
                    self.handleMouseMovedEvent( event )
                    
                case .ScrollWheel:
                    if let menu = self.lastHitMenuItem?.menu {
                        self.menuWindowForMenu( menu )?.scrollTracking.scrollEvent( event )
                    }
                    
                case .MouseEntered, .MouseExited:
                    break
                    
                case .CursorUpdate:
                    break
                    
                case .SystemDefined, .AppKitDefined:
                    break
                    
                case .BeginGesture, .EndGesture:
                    break
                    
                case NSEventType( rawValue: 21 )!:
                    // This event type does not currently have a symbolic name, but occurs when Expose is activated or deactivated.  It also occurs when right-clicking outside of the current application.
                    result = .Cancel
                    
                case NSEventType( rawValue: 28 )!:
                    //This is an event which appears to be related to screen zooming, but does not have a symbolic constant.
                    break
                    
                default:
                    #if DEBUG
                        Swift.print( "unhandled event type:\(event.type.rawValue)" )
                    #endif
                    break
                }
                
            }
            
            guard result == .Continue else { break }
        }
        
        NSApp.discardEventsMatchingMask( NSEventMask.Any, beforeEvent: terminatingEvent )
        
        self.scrollTimer?.invalidate()
        self.scrollTimer = nil
        
        self.endCursorTracking()
        self.eventSource.eventMask = []
        self.makeTopmostMenuWindow( nil, withFade: result != .Interrupt )
        
        return ( result == .GUISelection || result == .AccessibleSelection )
    }
    
    /*==========================================================================*/
    private func handleKeyboardEvent( event: NSEvent ) -> OBWFilteringMenuEventResult {
        
        let keyCode = Int(event.keyCode)
        
        if keyCode == kVK_Escape {
            
            let menuWindowArray = self.menuWindowArray
            
            guard let topmostMenuWindow = menuWindowArray.last else { return .Cancel }
            
            if topmostMenuWindow.accessibilityActive && menuWindowArray.count > 1 {
                
                guard let previousWindow = self.menuWindowBefore( menuWindow: topmostMenuWindow ) else { return .Cancel }
                self.makeTopmostMenuWindow( previousWindow, withFade: false )
                return .Continue
            }
            else {
                return .Cancel
            }
        }
        
        guard let targetMenuWindow = self.menuWindowWithKeyboardFocus else { return .Cancel }
        let targetMenu = targetMenuWindow.filteringMenu
        let menuView = targetMenuWindow.menuView
        
        let result = menuView.handleKeyboardEvent( event )
        switch result {
            
        case .Continue, .Cancel:
            return result
            
        case .Highlight:
            self.makeTopmostMenuWindow( targetMenuWindow, withFade: false )
            return .Continue
            
        case .ChangeFilter:
            self.makeTopmostMenuWindow( targetMenuWindow, withFade: false )
            targetMenuWindow.resetScrollTracking()
            return .Continue
            
        case .Unhandled, .Interrupt, .GUISelection, .AccessibleSelection:
            break
        }
        
        let highlightedItem = targetMenu.highlightedItem
        
        if keyCode == kVK_ANSI_KeypadEnter {
            
            if let highlightedItem = highlightedItem {
                self.performActionForItem( highlightedItem )
            }
            
            return .GUISelection
        }
        
        if [kVK_Space, kVK_Return, kVK_RightArrow].contains( keyCode ) {
            
            if let highlightedItem = highlightedItem where highlightedItem.submenu != nil {
                
                self.endCursorTracking()
                self.showSubmenu( ofMenuItem: highlightedItem, highlightFirstVisibleItem: true )
                self.menuWindowWithKeyboardFocus = self.menuWindowArray.last
                
                return .Continue
            }
            
            if keyCode == kVK_RightArrow {
                return .Continue
            }
            
            if let highlightedItem = highlightedItem {
                self.performActionForItem( highlightedItem )
            }
            
            return .GUISelection
        }
        
        if keyCode == kVK_LeftArrow {
            
            if targetMenu !== self.rootMenu {
                self.makeTopmostMenuWindow( self.menuWindowBefore( menuWindow: targetMenuWindow ), withFade: false )
            }
            
            return .Continue
        }
        
//        Swift.print( "keyCode: \(keyCode)" )
        
        return .Continue
    }
    
    /*==========================================================================*/
    private func handleFlagsChangedEvent( event: NSEvent ) -> OBWFilteringMenuEventResult {
        
        self.scrollTimer?.fireDate = NSDate.distantFuture()
        
        guard let targetMenuWindow = self.menuWindowWithKeyboardFocus else { return .Cancel }
        
        targetMenuWindow.menuView.handleFlagsChangedEvent( event )
        
        guard !targetMenuWindow.accessibilityActive else { return .Continue }
        
        let locationInScreen = NSEvent.mouseLocation()
        
        if let menuWindowWithKeyboardFocus = self.menuWindowWithKeyboardFocus {
            
            if self.menuWindowAtScreenLocation( locationInScreen ) === menuWindowWithKeyboardFocus {
                
                self.lastHitMenuItem = nil
                
                if let pseudoEvent = NSEvent.mouseEventWithType(
                    .MouseMoved,
                    location: locationInScreen,
                    modifierFlags: [],
                    timestamp: NSProcessInfo.processInfo().systemUptime,
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
        
        return .Continue
    }
    
    /*==========================================================================*/
    private func handleMouseMovedEvent( event: NSEvent ) {
        
        guard let topmostMenuWindow = self.menuWindowArray.last else { return }
        
        if topmostMenuWindow.accessibilityActive {
            
            let modifierKeyMask: NSEventModifierFlags = [ .Shift, .Control, .Option, .Command ]
            let voiceOverKeyMask: NSEventModifierFlags = [ .Control, .Option ]
            
            let eventModifierFlags = event.modifierFlags
            let voiceOverKeysPressed = ( eventModifierFlags.intersect( modifierKeyMask ) == voiceOverKeyMask )
            
            if voiceOverKeysPressed {
                return
            }
        }
        
        guard let eventLocationInScreen = event.obw_locationInScreen else { return }
        
        let locationInWindow = topmostMenuWindow.obw_convertFromScreen( eventLocationInScreen )
        let topmostMenuPart = topmostMenuWindow.menuPartAtLocation( locationInWindow )
        
        switch topmostMenuPart {
            
        case .Down:
            
            self.setupAutoscroll( directionKey: OBWFilteringMenuScrollUpTimerKey )
            
        case .Up:
            
            self.setupAutoscroll( directionKey: OBWFilteringMenuScrollDownTimerKey )
            
        case .Item, .Filter, .None:
            
            self.scrollTimer?.invalidate()
            self.scrollTimer = nil
            
            topmostMenuWindow.menuView.cursorUpdate( event )
            self.updateCurrentMenuItem( event, continueCursorTracking: true )
        }
    }
    
    /*==========================================================================*/
    private func handleApplicationEvent( event: NSEvent ) -> OBWFilteringMenuEventResult {
        
        switch event.subtype.rawValue {
            
        case OBWApplicationEventSubtype.ApplicationDidResignActive.rawValue:
            #if CONTINUE_ON_RESIGN_ACTIVE
                return .Continue
            #else
                return .Interrupt
            #endif
            
        case OBWApplicationEventSubtype.AccessibleItemSelection.rawValue:
            return .AccessibleSelection
            
        case OBWApplicationEventSubtype.Periodic.rawValue:
            self.updateCurrentMenuItem( event, continueCursorTracking: true )
            return .Continue
            
        default:
            Swift.print( "Unhandled application-defined event subtype: \(event.subtype.rawValue)" )
            return .Continue
        }
    }
    
    // MARK: Menu
    
    private let rootMenu: OBWFilteringMenu
    
    /*==========================================================================*/
    var topmostMenu: OBWFilteringMenu? {
        return self.menuWindowArray.last?.filteringMenu
    }
    
    weak private var lastHitMenuItem: OBWFilteringMenuItem? = nil
    
    /*==========================================================================*/
    private func updateCurrentMenuItem( event: NSEvent, continueCursorTracking: Bool ) {
        
        let eventLocationInScreen = event.obw_locationInScreen ?? NSEvent.mouseLocation()
        
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
                
                if let currentMenuItem = currentMenuItem, submenu = currentMenuItem.submenu, submenuWindow = self.menuWindowForMenu( submenu ) {
                    
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
        
        guard let menuItem = menuItem where menuItem.submenu != nil else { return }
        
        let delta = 0.100 * Double(NSEC_PER_SEC)
        let when = dispatch_time( DISPATCH_TIME_NOW, Int64(delta) )
        dispatch_after( when, dispatch_get_main_queue() ) {
            
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
        NSNotificationCenter.defaultCenter().postNotificationName( OBWFilteringMenuDidBeginTrackingNotification, object: newMenu, userInfo: userInfo )
    }
    
    /*==========================================================================*/
    private func performActionForItem( menuItem: OBWFilteringMenuItem ) {
        
        guard let menu = menuItem.menu else { return }
        guard let menuWindow = self.menuWindowForMenu( menu ) else { return }
        guard let itemView = menuWindow.menuView.viewForMenuItem( menuItem ) else { return }
        
        let runLoop = NSRunLoop.currentRunLoop()
        let blinkInterval = 0.025
        let blinkCount = 2
        
        for _ in 1...blinkCount {
            
            menu.highlightedItem = nil
            itemView.needsDisplay = true
            menuWindow.display()
            
            // It seems that the run loop needs to run at least once to actually get the window to redraw.  Previously, a -display message to the window was sufficient to get an immediate redraw.  This may be a side-effect of running a custom event loop in 10.11 El Capitan.
            
            runLoop.runMode( NSDefaultRunLoopMode, beforeDate: NSDate( timeIntervalSinceNow: blinkInterval ) )
            NSThread.sleepForTimeInterval( blinkInterval )
            
            menu.highlightedItem = menuItem
            itemView.needsDisplay = true
            menuWindow.display()
            
            runLoop.runMode( NSDefaultRunLoopMode, beforeDate: NSDate( timeIntervalSinceNow: blinkInterval ) )
            NSThread.sleepForTimeInterval( blinkInterval )
        }
        
        menuItem.performAction()
    }
    
    // MARK: Menu Windows
    
    private var menuWindowArray: [OBWFilteringMenuWindow] = []
    weak private var menuWindowWithKeyboardFocus: OBWFilteringMenuWindow? = nil
    
    /*==========================================================================*/
    private func makeTopmostMenuWindow( topmostMenuWindow: OBWFilteringMenuWindow?, withFade fade: Bool ) {
        
        if topmostMenuWindow === self.menuWindowArray.last {
            return
        }
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let userInfo: [String:AnyObject] = [ OBWFilteringMenuRootKey : self.rootMenu ]
        
        var terminatedMenuWindows: [OBWFilteringMenuWindow] = []
        
        for menuWindow in self.menuWindowArray.reverse() {
            
            if menuWindow === topmostMenuWindow { break }
            
            let menu = menuWindow.filteringMenu
            
            notificationCenter.postNotificationName( OBWFilteringMenuWillEndTrackingNotification, object: menuWindow, userInfo: userInfo )
            
            menu.highlightedItem = nil
            
            if !fade {
                menuWindow.animationBehavior = .None
            }
            else {
                menuWindow.animationBehavior = .Default
            }
            
            menuWindow.close()
            
            terminatedMenuWindows.append( menuWindow )
        }
        
        for window in terminatedMenuWindows {
            guard let index = self.menuWindowArray.indexOf( window ) else { continue }
            self.menuWindowArray.removeAtIndex( index )
        }
        
        self.updateMenuCorners()
        self.menuWindowWithKeyboardFocus = topmostMenuWindow
        
        topmostMenuWindow?.makeKeyAndOrderFront( nil )
    }
    
    /*==========================================================================*/
    private func menuWindowForMenu( menu: OBWFilteringMenu ) -> OBWFilteringMenuWindow? {
        
        for window in self.menuWindowArray.reverse() {
            
            if window.filteringMenu === menu {
                return window
            }
        }
        
        return nil
    }
    
    /*==========================================================================*/
    private func menuWindowAtScreenLocation( screenLocation: NSPoint ) -> OBWFilteringMenuWindow? {
        
        for window in self.menuWindowArray.reverse() {
            
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
    private func isMenuWindow( firstWindow: OBWFilteringMenuWindow, afterMenuWindow secondWindow: OBWFilteringMenuWindow ) -> Bool {
        
        guard let firstIndex = self.menuWindowArray.indexOf( firstWindow ) else { return false }
        guard let secondIndex = self.menuWindowArray.indexOf( secondWindow ) else { return false }
        
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
            
            if firstWindow.alignmentFromPrevious == .Right {
                self.updateRoundedCornersBetween( leftWindow: secondWindow, rightWindow: firstWindow )
                firstWindow.roundedCorners.unionInPlace( [ .TopRight, .BottomRight ] )
            }
            else {
                self.updateRoundedCornersBetween( leftWindow: firstWindow, rightWindow: secondWindow )
                firstWindow.roundedCorners.unionInPlace( [ .TopLeft, .BottomLeft ] )
            }
        }
        else {
            firstWindow.roundedCorners = .All
        }
    }
    
    /*==========================================================================*/
    private func updateRoundedCornersBetween( leftWindow leftWindow: OBWFilteringMenuWindow, rightWindow: OBWFilteringMenuWindow ) {
        
        if leftWindow.frame.maxY > rightWindow.frame.maxY {
            leftWindow.roundedCorners.insert( .TopRight )
        }
        else {
            leftWindow.roundedCorners.remove( .TopRight )
        }
        
        if leftWindow.frame.minY < rightWindow.frame.minY {
            leftWindow.roundedCorners.insert( .BottomRight )
        }
        else {
            leftWindow.roundedCorners.remove( .BottomRight )
        }
        
        if rightWindow.frame.maxY > leftWindow.frame.maxY {
            rightWindow.roundedCorners.insert( .TopLeft )
        }
        else {
            rightWindow.roundedCorners.remove( .TopLeft )
        }
        
        if rightWindow.frame.minY < leftWindow.frame.minY {
            rightWindow.roundedCorners.insert( .BottomLeft )
        }
        else {
            rightWindow.roundedCorners.remove( .BottomLeft )
        }
    }
    
    // MARK: Cursor Tracking
    
    private var cursorTracking: OBWFilteringMenuCursorTracking? = nil
    
    /*==========================================================================*/
    private func beginCursorTracking( menuItem: OBWFilteringMenuItem ) {
        
        guard let menu = menuItem.menu else { return }
        guard let window = self.menuWindowForMenu( menu ) else { return }
        guard let itemView = window.menuView.viewForMenuItem( menuItem ) else { return }
        let itemViewBoundsInScreen = itemView.obw_boundsInScreen
        
        let sourceLine = NSRect(
            x: NSEvent.mouseLocation().x,
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
            x: NSEvent.mouseLocation().x,
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
    @objc private func scrollTrackingBoundsChanged( notification: NSNotification ) {
        
        let scrollTracking = notification.object as! OBWFilteringMenuScrollTracking
        let boundsValue = notification.userInfo?[OBWFilteringMenuScrollTrackingBoundsValueKey] as! NSValue
        let menuItemBounds = boundsValue.rectValue
        
        guard let windowIndex = self.menuWindowArray.indexOf({ $0.scrollTracking === scrollTracking }) else { return }
        let window = self.menuWindowArray[windowIndex]
        window.displayMenuItemBounds( menuItemBounds )
        
        guard let pseudoEvent = NSEvent.mouseEventWithType(
            .MouseMoved,
            location: NSEvent.mouseLocation(),
            modifierFlags: [],
            timestamp: NSProcessInfo.processInfo().systemUptime,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 0,
            pressure: 0.0
            ) else { return }
        
        self.updateCurrentMenuItem( pseudoEvent, continueCursorTracking: false )
        self.updateMenuCorners()
    }
    
    // MARK: Scrolling
    
    weak private var scrollTimer: NSTimer? = nil
    private var scrollStartInterval: NSTimeInterval = 0.0
    
    /*==========================================================================*/
    private func setupAutoscroll( directionKey directionKey: String ) {
        
        if self.scrollTimer?.userInfo?[directionKey] as? Bool == true {
            return
        }
        
        guard let topmostMenuWindow = self.menuWindowArray.last else { return }
        let topmostMenu = topmostMenuWindow.filteringMenu
        
        topmostMenu.highlightedItem = nil
        
        self.scrollTimer?.invalidate()
        
        let userInfo: [String:AnyObject] = [
            OBWFilteringMenuWindowKey : topmostMenuWindow,
            directionKey : true
        ]
        
        self.scrollTimer = NSTimer.scheduledTimerWithTimeInterval(
            OBWFilteringMenuController.scrollInterval,
            target: self,
            selector: #selector(OBWFilteringMenuController.scrollTimerDidFire(_:)),
            userInfo: userInfo,
            repeats: true
        )
        
        guard let scrollTimer = self.scrollTimer else { return }
        
        self.scrollStartInterval = NSDate.timeIntervalSinceReferenceDate()
        self.scrollTimerDidFire( scrollTimer )
    }
    
    /*==========================================================================*/
    @objc private func scrollTimerDidFire( timer: NSTimer ) {
        
        guard let userInfo = timer.userInfo else { return }
        guard let scrolledWindow = userInfo[OBWFilteringMenuWindowKey] as? OBWFilteringMenuWindow else { return }
        
        let upDirection = userInfo[OBWFilteringMenuScrollUpTimerKey] as? Bool ?? false
        let downDirection = userInfo[OBWFilteringMenuScrollDownTimerKey] as? Bool ?? false
        assert( upDirection || downDirection )
        
        let scrollDuration = NSDate.timeIntervalSinceReferenceDate() - self.scrollStartInterval
        
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
    
    // MARK: External Notifications
    
    /*==========================================================================*/
    @objc private func axDidOpenMenuItem( notification: NSNotification ) {
        
        guard let userInfo = notification.userInfo else { return }
        guard let menuItem = userInfo[OBWFilteringMenuItemKey] as? OBWFilteringMenuItem else { return }
        
        guard self.topmostMenu === menuItem.menu else { return }
        
        if menuItem.submenu != nil {
            self.showSubmenu( ofMenuItem: menuItem, highlightFirstVisibleItem: false )
            self.menuWindowWithKeyboardFocus = self.menuWindowArray.last
        }
        else if menuItem.enabled {
            
            self.performActionForItem( menuItem )
            
            if let pseudoEvent = NSEvent.otherEventWithType(
            .ApplicationDefined,
            location: NSZeroPoint,
            modifierFlags: [],
            timestamp: NSProcessInfo.processInfo().systemUptime,
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
    @objc private func menuViewTotalItemSizeDidChange( notification: NSNotification ) {
        self.updateMenuCorners()
    }
    
    /*==========================================================================*/
    @objc private func externalMenuDidBeginTracking( notification: NSNotification ) {
        self.makeTopmostMenuWindow( nil, withFade: true )
    }
}
