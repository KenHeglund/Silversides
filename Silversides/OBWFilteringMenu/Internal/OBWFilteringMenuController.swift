/*===========================================================================
 OBWFilteringMenuController.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit
import Carbon.HIToolbox.Events

/// A class that controls the modal session of a OBWFilteringMenu.
class OBWFilteringMenuController {
    
    /// Programmatically display the menu, optionally positioning an item at a specific location.
    /// - parameter menuItem: The filtering menu item to position.  May be nil.
    /// - parameter alignment: The location within the menu item to position at `locationInView`.
    /// - parameter locationInView: The origin of the filtering menu item to position.
    /// - parameter view: The view that defines the coordinate system for `atLocation`.  If nil, then the `at` parameter is interpreted as screen coordinates.
    /// - parameter matchWidth: If `true`, the menu will be at least as wide as `view`.
    /// - parameter event: The event causing the filtering menu's appearance.  May be nil.
    /// - parameter highlightTarget: A HighlightTarget that identifies the menu item to initially highlight after the menu appears.
    /// - returns: true if a menu item was closed by selecting an item, false if no selection was made.
    class func popUpMenuPositioningItem(_ menuItem: OBWFilteringMenuItem, aligning alignment: OBWFilteringMenuItem.Alignment, atPoint locationInView: NSPoint, inView view: NSView?, matchingWidth matchWidth: Bool, with event: NSEvent?, highlighting highlightTarget: OBWFilteringMenu.HighlightTarget) -> Bool {
        
        guard let menu = menuItem.menu else {
            return false
        }
        
        guard let screen = view?.window?.screen ?? event?.screen ?? NSScreen.screens.first else {
            return false
        }
        
        let locationInScreen = view?.convertPointToScreen(locationInView) ?? locationInView
        let minimumWidth = (matchWidth ? view?.frame.width : nil)
        let controller = OBWFilteringMenuController(rootMenu: menu, onScreen: screen, minimumWidth: minimumWidth)
        
        switch alignment {
        case .baseline:
            controller.positionBaseline(of: menuItem, at: locationInScreen)
        case .topLeft:
            controller.positionTopLeftCorner(of: menuItem, at: locationInScreen)
        }
        
        controller.setupLastHitItemBasedOnCurrentCursorLocation()
        
        switch highlightTarget {
        case .none:
            break
        case .item:
            menu.highlightedItem = menuItem
        case .underCursor:
            menu.highlightedItem = controller.lastHitMenuItem
        }
        
        return controller.runModalSession()
    }
    
    /// Private initialization.
    /// - parameter rootMenu: The first menu opened during the controller's session.
    /// - parameter screen: The screen that menus will be confined to.
    /// - parameter minimumWidth: The minimum width of the root menu.  If `nil`, the menu will be its natural width.
    private init(rootMenu: OBWFilteringMenu, onScreen screen: NSScreen, minimumWidth: CGFloat?) {
        
        let rootMenuWindow = OBWFilteringMenuWindow(menu: rootMenu, onScreen: screen, minimumWidth: minimumWidth)
        
        self.rootMenu = rootMenu
        self.menuWindowArray = [rootMenuWindow]
        self.menuWindowWithKeyboardFocus = rootMenuWindow
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(OBWFilteringMenuController.axDidOpenMenuItem(_:)), name: OBWFilteringMenuController.axDidOpenMenuItemNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(OBWFilteringMenuController.menuViewTotalItemSizeDidChange(_:)), name: OBWFilteringMenuWindow.totalItemSizeChangedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(OBWFilteringMenuController.externalMenuDidBeginTracking(_:)), name: NSMenu.didBeginTrackingNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(OBWFilteringMenuController.scrollTrackingBoundsChanged(_:)), name: OBWFilteringMenuScrollTracking.boundsChangedNotification, object: nil)
    }
    
    /// Deinitialize.
    deinit {
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: OBWFilteringMenuController.axDidOpenMenuItemNotification, object: nil)
        notificationCenter.removeObserver(self, name: OBWFilteringMenuWindow.totalItemSizeChangedNotification, object: nil)
        notificationCenter.removeObserver(self, name: NSMenu.didBeginTrackingNotification, object: nil)
        notificationCenter.removeObserver(self, name: OBWFilteringMenuScrollTracking.boundsChangedNotification, object: nil)
    }
    
    
    // MARK: - OBWFilteringMenuController internal
    
    /// Runs a menu modal session.
    /// - returns: `true` if the session ended with a menu item selection, `false` if it ended without a menu item selection.
    private func runModalSession() -> Bool {
        
        NotificationCenter.default.post(name: OBWFilteringMenu.willBeginSessionNotification, object: self.rootMenu)
        
        #if DEBUG_CURSOR_TRACKING
        _ = OBWFilteringMenuDebugWindow.shared
        #endif
        
        OBWFilteringMenuDebugWindow.orderFront(self)
        
        let menuItemSelected = self.runEventLoop()
        
        OBWFilteringMenuDebugWindow.removeAllDrawingHandlers()
        OBWFilteringMenuDebugWindow.orderOut(self)
        
        NotificationCenter.default.post(name: OBWFilteringMenu.didEndSessionNotification, object: self.rootMenu)
        
        return menuItemSelected
    }
    
    
    // MARK: - Private
    
    /// Positions the menu such that the baseline of the title in the given menu item is located at the given location on the screen.
    /// - parameter menuItem: The menu item to position.
    /// - parameter locationInScreen: The location in screen coordinates where the baseline of `menuItem`'s title should be positioned.
    private func positionBaseline(of menuItem: OBWFilteringMenuItem, at locationInScreen: NSPoint) {
        
        guard
            let rootMenuWindow = self.menuWindowArray.first,
            let itemView = rootMenuWindow.menuView.viewForMenuItem(menuItem)
        else {
            assertionFailure()
            return
        }
        
        let itemViewFrame = itemView.frame
        let itemBaselineOffset = itemView.firstBaselineOffsetFromTop
        let screenAnchor = NSRect(
            x: locationInScreen.x,
            y: locationInScreen.y - itemViewFrame.height + itemBaselineOffset,
            size: itemViewFrame.size
        )
        
        rootMenuWindow.screenAnchor = screenAnchor
        
        let menuLocation = NSPoint(x: itemViewFrame.minX, y: itemViewFrame.maxY)
        let screenLocation = NSPoint(x: locationInScreen.x, y: locationInScreen.y + itemBaselineOffset)
        rootMenuWindow.displayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false)
    }
    
    /// Positions the menu such that the top-left corner of the given menu item is located at the given location on the screen.
    /// - parameter menuItem: The menu item to position.
    /// - parameter locationInScreen: The location in screen coordinates where the `menuItem` should be positioned.
    private func positionTopLeftCorner(of menuItem: OBWFilteringMenuItem, at locationInScreen: NSPoint) {
        
        guard
            let rootMenuWindow = self.menuWindowArray.first,
            let itemView = rootMenuWindow.menuView.viewForMenuItem(menuItem)
        else {
            assertionFailure()
            return
        }
        
        let adjustedLocationInScreen = NSPoint(
            x: locationInScreen.x,
            y: locationInScreen.y - itemView.firstBaselineOffsetFromTop
        )
        
        self.positionBaseline(of: menuItem, at: adjustedLocationInScreen)
    }
    
    /// Assigns the menu item currently under the cursor as the controller's `lastHitMenuItem`.
    private func setupLastHitItemBasedOnCurrentCursorLocation() {
        
        guard let rootMenuWindow = self.menuWindowArray.first else {
            assertionFailure()
            return
        }
        
        let locationInWindow = rootMenuWindow.mouseLocationOutsideOfEventStream
        let locationInView = rootMenuWindow.menuView.convert(locationInWindow, from: nil)
        let menuItemUnderCursor = rootMenuWindow.menuView.menuItemAtLocation(locationInView)
        
        self.lastHitMenuItem = menuItemUnderCursor
    }
    
    
    // MARK: - Run Loop
    
    /// Process application events.
    /// - returns: `true` if the event loop ended when a menu item was selected, `false` if the event loop ends for any other reason.
    private func runEventLoop() -> Bool {
        
        guard let rootMenuWindow = self.menuWindowArray.first else {
            return false
        }
        
        let notificationCenter = NotificationCenter.default
        
        let initialMenu = self.rootMenu
        let userInfo = [OBWFilteringMenu.Key.root : initialMenu]
        notificationCenter.post(name: OBWFilteringMenu.didBeginTrackingNotification, object: initialMenu, userInfo: userInfo)
        
        rootMenuWindow.makeKeyAndOrderFront(nil)
        
        OBWFilteringMenuEventSource.shared.isApplicationDidResignActiveEventEnabled = true
        
        let startDate = Date()
        var terminatingEvent: NSEvent? = nil
        
        var result = OBWFilteringMenu.SessionState.continue
        var lastLeftMouseDownResult = OBWFilteringMenu.SessionState.unhandled
        
        while true {
            
            autoreleasepool {
                
                #if DEBUG
                    let timeoutInterval = 10.0 * 60.0
                #else
                    let timeoutInterval = 60.0
                #endif
                
                let timeoutDate = Date(timeIntervalSinceNow: timeoutInterval)
                guard let event = NSApp.nextEvent(matching: .any, until: timeoutDate, inMode: .default, dequeue: true) else {
                    result = .cancel
                    return
                }
                
                let currentMenuWindow: OBWFilteringMenuWindow?
                if let locationInScreen = event.locationInScreen {
                    currentMenuWindow = self.menuWindowAtScreenLocation( locationInScreen )
                }
                else {
                    currentMenuWindow = nil
                }
                
                terminatingEvent = event
            
                switch event.type {
                    
                case .applicationDefined:
                    result = self.handleApplicationEvent(event)
                    
                case .keyDown:
                    self.scrollTimer?.fireDate = Date.distantFuture
                    self.endCursorTracking()
                    
                    result = self.handleKeyDownEvent(event)
                    
                    self.lastHitMenuItem = nil
                    
                case .keyUp:
                    break
                    
                case .flagsChanged:
                    result = self.handleKeyboardModifiersChangedEvent(event)
                    
                case .leftMouseDown:
                    
                    guard let currentMenuWindow = currentMenuWindow else {
                        result = .cancel
                        break
                    }
                    
                    lastLeftMouseDownResult = currentMenuWindow.menuView.handleLeftMouseButtonDownEvent(event)
                    
                    self.makeTopmostMenuWindow(currentMenuWindow, withAnimation: true)
                    
                case .rightMouseDown:
                    
                    guard let currentMenuWindow = currentMenuWindow else {
                        NSApp.postEvent(event, atStart: true)
                        result = .cancel
                        break
                    }
                    
                    self.makeTopmostMenuWindow(currentMenuWindow, withAnimation: true)
                    
                case .otherMouseDown:
                    
                    guard let currentMenuWindow = currentMenuWindow else {
                        result = .cancel
                        break
                    }
                    
                    self.makeTopmostMenuWindow(currentMenuWindow, withAnimation: true)
                    
                case .leftMouseUp:
                    
                    if Date().timeIntervalSince(startDate) < NSEvent.doubleClickInterval {
                        break
                    }
                    
                    if lastLeftMouseDownResult != .unhandled {
                        lastLeftMouseDownResult = .unhandled
                        break
                    }
                    
                    if let menuItem = self.lastHitMenuItem {
                        self.performSelectionOfItem(menuItem)
                        result = .guiSelection
                    }
                    else {
                        result = .cancel
                    }
                    
                case .mouseMoved, .leftMouseDragged:
                    self.handleMouseMovedEvent(event)
                    
                case .scrollWheel:
                    self.menuWindowWithScrollFocus = currentMenuWindow
                    currentMenuWindow?.scrollTracking.scrollEvent(event)
                    
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
                    
                case NSEvent.EventType(rawValue: 21)!:
                    // This event type does not currently have a symbolic name, but occurs when Expose is activated or deactivated.  It also occurs when right-clicking outside of the current application.
                    result = .cancel
                    
                case NSEvent.EventType(rawValue: 28)!:
                    //This is an event which appears to be related to screen zooming, but does not have a symbolic constant.
                    break
                    
                default:
                    #if DEBUG
                        Swift.print("unhandled event type:\(event.type.rawValue)")
                    #endif
                    break
                }
                
            }
            
            guard result == .continue else {
                break
            }
        }
        
        NSApp.discardEvents(matching: .any, before: terminatingEvent)
        
        self.scrollTimer?.invalidate()
        self.scrollTimer = nil
        
        self.endCursorTracking()
        OBWFilteringMenuEventSource.shared.isApplicationDidResignActiveEventEnabled = false
        self.makeTopmostMenuWindow(nil, withAnimation: result != .interrupt)
        
        return (result == .guiSelection || result == .accessibleSelection)
    }
    
    /// Handle a keyDown keyboard event.
    /// - parameter event: The event.
    /// - returns: The modal session state that results from handling the event.
    private func handleKeyDownEvent(_ event: NSEvent) -> OBWFilteringMenu.SessionState {
        
        let keyCode = Int(event.keyCode)
        
        if keyCode == kVK_Escape {
            
            let menuWindowArray = self.menuWindowArray
            
            guard let topmostMenuWindow = menuWindowArray.last else {
                return .cancel
            }
            
            guard topmostMenuWindow.accessibilityActive, menuWindowArray.count > 1 else {
                return .cancel
            }
            
            self.removeTopmostNonRootMenuWindow(withAnimation: false)
            
            return .continue
        }
        
        guard let targetMenuWindow = self.menuWindowWithKeyboardFocus else {
            return .cancel
        }
        
        let targetMenu = targetMenuWindow.filteringMenu
        let menuView = targetMenuWindow.menuView
        
        let viewKeyDownResult = menuView.handleKeyDownEvent(event)
        
        switch viewKeyDownResult {
            
        case .continue, .cancel:
            return viewKeyDownResult
            
        case .highlight:
            self.makeTopmostMenuWindow(targetMenuWindow, withAnimation: false)
            return .continue
            
        case .changeFilter:
            self.makeTopmostMenuWindow(targetMenuWindow, withAnimation: false)
            targetMenuWindow.resetScrollTracking()
            return .continue
            
        case .unhandled, .interrupt, .guiSelection, .accessibleSelection:
            break
        }
        
        let highlightedItem = targetMenu.highlightedItem
        
        switch keyCode {
            
        case kVK_ANSI_KeypadEnter:
            if let highlightedItem = highlightedItem {
                self.performSelectionOfItem(highlightedItem)
            }
            
            return .guiSelection
            
        case kVK_Space, kVK_Return, kVK_RightArrow:
            if let highlightedItem = highlightedItem, highlightedItem.submenu != nil {
                
                self.endCursorTracking()
                self.showSubmenu(ofMenuItem: highlightedItem, highlightFirstVisibleItem: true)
                self.menuWindowWithKeyboardFocus = self.menuWindowArray.last
                
                return .continue
            }
            
            if keyCode == kVK_RightArrow {
                return .continue
            }
            
            if let highlightedItem = highlightedItem {
                self.performSelectionOfItem(highlightedItem)
            }
            
            return .guiSelection
            
        case kVK_LeftArrow:
            self.removeTopmostNonRootMenuWindow(withAnimation: false)
            return .continue
            
        default:
            return .continue
        }
    }
    
    /// Handle a flagsChanged (modifiers changed) keyboard event.
    /// - parameter event: The event.
    /// - returns: The modal session state that results from handling the event.
    private func handleKeyboardModifiersChangedEvent(_ event: NSEvent) -> OBWFilteringMenu.SessionState {
        
        self.scrollTimer?.fireDate = Date.distantFuture
        
        guard let targetMenuWindow = self.menuWindowWithKeyboardFocus else {
            return .cancel
        }
        
        targetMenuWindow.menuView.handleKeyboardModifiersChangedEvent(event)
        
        guard targetMenuWindow.accessibilityActive == false else {
            return .continue
        }
        
        let locationInScreen = NSEvent.mouseLocation
        
        if
            let menuWindowWithKeyboardFocus = self.menuWindowWithKeyboardFocus,
            self.menuWindowAtScreenLocation(locationInScreen) === menuWindowWithKeyboardFocus {
            
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
                self.updateMenuWindowsBasedOnCursorLocation(in: pseudoEvent, continueCursorTracking: false)
            }
        }
        
        self.updateMenuCorners()
        
        return .continue
    }
    
    /// Handle a mouseMoved mouse event.
    /// - parameter event: The event.
    private func handleMouseMovedEvent(_ event: NSEvent) {
        
        guard let topmostMenuWindow = self.menuWindowArray.last else {
            return
        }
        
        if topmostMenuWindow.accessibilityActive, event.voiceOverModifiersPressed {
            return
        }
        
        guard let eventLocationInScreen = event.locationInScreen else {
            return
        }
        
        let locationInWindow = topmostMenuWindow.convertFromScreen(eventLocationInScreen)
        let topmostMenuPart = topmostMenuWindow.menuPartAtLocation(locationInWindow)
        
        switch topmostMenuPart {
            
        case .down:
            self.setupAutoscroll(directionKey: .scrollUp)
            
        case .up:
            self.setupAutoscroll(directionKey: .scrollDown)
            
        case .item, .filter, .none:
            self.scrollTimer?.invalidate()
            self.scrollTimer = nil
            
            topmostMenuWindow.menuView.cursorUpdate(with: event)
            self.updateMenuWindowsBasedOnCursorLocation(in: event, continueCursorTracking: true)
        }
    }
    
    /// Handle an application-defined event.
    /// - parameter event: The event.
    /// - returns: The modal session state that results from handling the event.
    private func handleApplicationEvent(_ event: NSEvent) -> OBWFilteringMenu.SessionState {
        
        guard let subtype = OBWFilteringMenuEventSubtype(event) else {
            print("Unhandled application-defined event subtype: \(event.subtype.rawValue)")
            return .continue
        }
        
        switch subtype {
            
        case .applicationDidBecomeActive:
            return .continue
            
        case .applicationDidResignActive:
            return .interrupt
            
        case .accessibleItemSelection:
            return .accessibleSelection
            
        case .periodic:
            self.updateMenuWindowsBasedOnCursorLocation(in: event, continueCursorTracking: true)
            return .continue
        }
    }
    
    
    // MARK: - Menu
    
    /// The first menu opened during the menu session.
    private let rootMenu: OBWFilteringMenu
    
    /// The most recent menu opened during the menu session.
    var topmostMenu: OBWFilteringMenu? {
        return self.menuWindowArray.last?.filteringMenu
    }
    
    /// The menu item that was most recently found to be under the cursor.
    weak private var lastHitMenuItem: OBWFilteringMenuItem? = nil
    
    /// Updates the menu window state based on the current cursor location.
    /// - parameter event: The event containing the current cursor location.
    /// - parameter continueCursorTracking: If `true`, continue tracking cursor movement toward a submenu; if `false` interrupt cursor tracking and close the topmost submenu.
    private func updateMenuWindowsBasedOnCursorLocation(in event: NSEvent, continueCursorTracking: Bool) {
        
        let cursorLocationInScreen = event.locationInScreen ?? NSEvent.mouseLocation
        
        let menuWindowUnderCursor = self.menuWindowAtScreenLocation(cursorLocationInScreen)
        let menuUnderCursor = menuWindowUnderCursor?.filteringMenu
        let cursorLocationInWindow = menuWindowUnderCursor?.convertFromScreen(cursorLocationInScreen) ?? NSPoint.zero
        let menuItemUnderCursor = menuWindowUnderCursor?.menuItemAtLocation(cursorLocationInWindow)
        
        self.lastHitMenuItem = menuItemUnderCursor
        
        if let currentMenuWindow = menuWindowUnderCursor {
            self.menuWindowWithKeyboardFocus = currentMenuWindow
        }
        
        if menuWindowUnderCursor !== self.menuWindowWithScrollFocus {
            menuWindowUnderCursor?.resetScrollTracking()
        }
        
        if let cursorTracking = self.cursorTracking {
            
            if menuUnderCursor === cursorTracking.sourceMenuItem.submenu {
                // Cursor has arrived in the submenu.
                self.endCursorTracking()
            }
            else if menuItemUnderCursor === cursorTracking.sourceMenuItem {
                // Cursor is still in the source menu item.
                menuUnderCursor?.highlightedItem = menuItemUnderCursor
                self.updateCursorTracking()
                return
            }
            else if continueCursorTracking == false {
                // The cursor is between source and submenu but must be interrupted.
                self.endCursorTracking()
                self.removeTopmostNonRootMenuWindow(withAnimation: false)
            }
            else if cursorTracking.isCursorProgressingTowardSubmenu(event) {
                // The cursor continues to make progress toward the submenu.
                return
            }
            else {
                // The cursor is no longer making progress toward the submenu.
                self.endCursorTracking()
                self.removeTopmostNonRootMenuWindow(withAnimation: true)
                self.delayedShowSubmenu(ofMenuItem: nil)
            }
        }
        
        guard let currentMenu = menuUnderCursor else {
            // The cursor is outside of all menus
            self.topmostMenu?.highlightedItem = nil
            return
        }
        
        if currentMenu === self.topmostMenu {
            
            // The cursor is somewhere in the topmost menu.
            
            currentMenu.highlightedItem = menuItemUnderCursor
            self.delayedShowSubmenu(ofMenuItem: menuItemUnderCursor)
        }
        else if let currentMenuItem = menuItemUnderCursor,
            let submenu = currentMenuItem.submenu,
            let submenuWindow = self.menuWindowForMenu(submenu) {
            
            // The cursor has circled back to an item whose submenu is already open.
            
            self.makeTopmostMenuWindow(submenuWindow, withAnimation: false)
            submenu.highlightedItem = nil
            self.beginCursorTracking(from: currentMenuItem)
        }
        else if let currentMenuWindow = self.menuWindowForMenu(currentMenu) {
            
            // The cursor has circled back to an unselected item in a menu that had already been opened.
            
            self.makeTopmostMenuWindow(currentMenuWindow, withAnimation: false)
            
            if let currentMenuItem = menuItemUnderCursor {
                self.delayedShowSubmenu(ofMenuItem: currentMenuItem)
            }
        }
    }
    
    /// The generation counter that tracks requests to open a submenu.  Incremented upon each request to open a menu item's submenu.
    private var delayedSubmenuGeneration = 0
    
    /// The most recent menu item whose submenu was requested.
    private weak var delayedSubmenuParent: OBWFilteringMenuItem? = nil
    
    /// Presents the given menu item's submenu after a delay.
    /// - parameter menuItem: The menu item whose submenu should be displayed (if any).  If `nil`, a previous request to show a submenu is cancelled.
    private func delayedShowSubmenu(ofMenuItem menuItem: OBWFilteringMenuItem?) {
        
        guard menuItem !== self.delayedSubmenuParent else {
            return
        }
        
        self.delayedSubmenuParent = menuItem
        
        let generation = self.delayedSubmenuGeneration + 1
        self.delayedSubmenuGeneration = generation
        
        guard let menuItem = menuItem, menuItem.submenu != nil else {
            return
        }
        
        let deadline = DispatchTime.now() + DispatchTimeInterval.milliseconds(100)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            [weak self] in
            
            guard
                let controller = self,
                generation == controller.delayedSubmenuGeneration,
                let submenuParent = controller.delayedSubmenuParent,
                let menu = submenuParent.menu,
                menu === controller.topmostMenu
            else {
                return
            }
            
            controller.showSubmenu(ofMenuItem: submenuParent, highlightFirstVisibleItem: false)
            controller.beginCursorTracking(from: submenuParent)
        }
    }
    
    /// Shows the submenu of the given menu item.
    /// - parameter menuItem: The parent menu item of the submenu to be shown.
    /// - parameter highlightFirstVisibleItem: If `true` the first visible item of the submenu will be highlighted.
    private func showSubmenu(ofMenuItem menuItem: OBWFilteringMenuItem, highlightFirstVisibleItem: Bool) {
        
        guard let newMenu = menuItem.submenu else {
            return
        }
        
        newMenu.finalMenuItemsAreNeededNow()
        
        guard
            newMenu.itemArray.isEmpty == false,
            let parentMenu = menuItem.menu,
            let parentMenuWindow = self.menuWindowForMenu(parentMenu),
            let screen = parentMenuWindow.screen,
            let itemView = parentMenuWindow.menuView.viewForMenuItem(menuItem)
        else {
            return
        }
        
        let newWindow = OBWFilteringMenuWindow(menu: newMenu, onScreen: screen, minimumWidth: nil)
        let newMenuView = newWindow.menuView
        
        self.menuWindowArray.append(newWindow)
        
        if highlightFirstVisibleItem {
            newMenuView.selectFirstMenuItemView()
        }
        
        let menuItemBounds = newMenuView.menuItemBounds
        let menuLocation = NSPoint(x: menuItemBounds.minX, y: menuItemBounds.maxY)
        
        newWindow.displayMenuLocation(menuLocation, adjacentToScreenArea: itemView.boundsInScreen, preferredAlignment: parentMenuWindow.alignmentFromPrevious)
        
        self.updateMenuCorners()
        
        newWindow.makeKeyAndOrderFront(nil)
        
        let userInfo = [OBWFilteringMenu.Key.root : self.rootMenu]
        NotificationCenter.default.post(name: OBWFilteringMenu.didBeginTrackingNotification, object: newMenu, userInfo: userInfo)
    }
    
    /*==========================================================================*/
    private func performSelectionOfItem(_ menuItem: OBWFilteringMenuItem) {
        
        guard
            let menu = menuItem.menu,
            let menuWindow = self.menuWindowForMenu(menu),
            let itemView = menuWindow.menuView.viewForMenuItem(menuItem)
        else {
            return
        }
        
        let blinkIntervalInSeconds = 0.025
        let blinkCount = 2
        
        for _ in 1...blinkCount {
            
            // It seems that the run loop needs to run at least once to actually get the window to redraw.  Previously, a -display message to the window was sufficient to get an immediate redraw.  This may be a side-effect of running a custom event loop in 10.11 El Capitan?
            
            menu.highlightedItem = nil
            itemView.needsDisplay = true
            menuWindow.display()
            
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: blinkIntervalInSeconds))
            Thread.sleep(forTimeInterval: blinkIntervalInSeconds)
            
            menu.highlightedItem = menuItem
            itemView.needsDisplay = true
            menuWindow.display()
            
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: blinkIntervalInSeconds))
            Thread.sleep(forTimeInterval: blinkIntervalInSeconds)
        }
        
        menuItem.performAction()
        
        let userInfo = [OBWFilteringMenu.Key.item : menuItem]
        NotificationCenter.default.post(name: OBWFilteringMenu.didSelectItemNotification, object: menuItem.menu, userInfo: userInfo)
    }
    
    
    // MARK: - Menu Windows
    
    /// The array of currently open menu windows.  The first window is associated with the root menu item, the last window is associated with the topmost visible window.
    private var menuWindowArray: [OBWFilteringMenuWindow] = []
    
    /// The window that will receive keyboard events.
    weak private var menuWindowWithKeyboardFocus: OBWFilteringMenuWindow? = nil
    
    /// Makes the given window the topmost window, closing any other windows that may currently be above it.
    /// - parameter topmostMenuWindow: The new topmost window.
    /// - parameter animate: If `true`, animate the closing of windows.
    private func makeTopmostMenuWindow(_ topmostMenuWindow: OBWFilteringMenuWindow?, withAnimation animate: Bool) {
        
        if topmostMenuWindow === self.menuWindowArray.last {
            return
        }
        
        let notificationCenter = NotificationCenter.default
        let userInfo = [OBWFilteringMenu.Key.root : self.rootMenu]
        
        for menuWindow in self.menuWindowArray.reversed() {
            
            if menuWindow === topmostMenuWindow {
                break
            }
            
            let menu = menuWindow.filteringMenu
            
            notificationCenter.post(name: OBWFilteringMenu.willEndTrackingNotification, object: menuWindow, userInfo: userInfo)
            
            menu.highlightedItem = nil
            menuWindow.animationBehavior = (animate ? .default : .none)
            menuWindow.close()
            
            self.menuWindowArray.removeLast()
        }
        
        self.updateMenuCorners()
        self.menuWindowWithKeyboardFocus = topmostMenuWindow
        
        topmostMenuWindow?.makeKeyAndOrderFront(nil)
    }
    
    /// Returns the window for the given filtering menu.
    /// - parameter menu: The menu whose window is requested.
    private func menuWindowForMenu(_ menu: OBWFilteringMenu) -> OBWFilteringMenuWindow? {
        return self.menuWindowArray.last(where: { $0.filteringMenu === menu })
    }
    
    /// Returns the window at the given screen location.
    /// - parameter screenLocation: A location in screen coordinates.
    private func menuWindowAtScreenLocation(_ screenLocation: NSPoint) -> OBWFilteringMenuWindow? {
        return self.menuWindowArray.last(where: { NSPointInRect(screenLocation, $0.frame) })
    }
    
    /// Removes the topmost menu window unless it is the root menu window.
    /// - parameter animate: If `true`, animate the removal of the topmost window.
    private func removeTopmostNonRootMenuWindow(withAnimation animate: Bool) {
        
        guard let newTopMostMenuWindow = self.menuWindowArray.dropLast(1).last else {
            return
        }
        
        self.makeTopmostMenuWindow(newTopMostMenuWindow, withAnimation: animate)
    }
    
    /// Updates the rounded/squared state of the menu windows.
    private func updateMenuCorners() {
        
        guard let firstWindow = self.menuWindowArray.last else {
            return
        }
        
        let menuCount = self.menuWindowArray.count
        
        if menuCount >= 2 {
            
            let secondWindow = self.menuWindowArray[menuCount-2]
            
            if firstWindow.alignmentFromPrevious == .right {
                self.updateRoundedCornersBetween(leftWindow: secondWindow, rightWindow: firstWindow)
                firstWindow.roundedCorners.formUnion([.topRight, .bottomRight])
            }
            else {
                self.updateRoundedCornersBetween(leftWindow: firstWindow, rightWindow: secondWindow)
                firstWindow.roundedCorners.formUnion([.topLeft, .bottomLeft])
            }
        }
        else {
            firstWindow.roundedCorners = .all
        }
    }
    
    /// Updates the rounded corners of two adjacent windows.
    /// - parameter leftWindow: The leftmost of two windows.
    /// - parameter rightWindow: The rightmost of two windows.
    private func updateRoundedCornersBetween(leftWindow: OBWFilteringMenuWindow, rightWindow: OBWFilteringMenuWindow) {
        
        if leftWindow.frame.maxY > rightWindow.frame.maxY {
            leftWindow.roundedCorners.insert(.topRight)
        }
        else {
            leftWindow.roundedCorners.remove(.topRight)
        }
        
        if leftWindow.frame.minY < rightWindow.frame.minY {
            leftWindow.roundedCorners.insert(.bottomRight)
        }
        else {
            leftWindow.roundedCorners.remove(.bottomRight)
        }
        
        if rightWindow.frame.maxY > leftWindow.frame.maxY {
            rightWindow.roundedCorners.insert(.topLeft)
        }
        else {
            rightWindow.roundedCorners.remove(.topLeft)
        }
        
        if rightWindow.frame.minY < leftWindow.frame.minY {
            rightWindow.roundedCorners.insert(.bottomLeft)
        }
        else {
            rightWindow.roundedCorners.remove(.bottomLeft)
        }
    }
    
    
    // MARK: - Cursor Tracking
    
    /// The time interval in seconds between updating the currently highlighted menu item.
    private static let periodicEventInterval = 0.025
    
    /// Used to track cursor movements between a menu item and its submenu.
    private var cursorTracking: OBWFilteringMenuCursorTracking? = nil
    
    /// Begin a new cursor tracking session.
    /// - parameter menuItem: The menu item where tracking begins.
    private func beginCursorTracking(from menuItem: OBWFilteringMenuItem) {
        
        guard
            let menu = menuItem.menu,
            let window = self.menuWindowForMenu(menu),
            let itemView = window.menuView.viewForMenuItem(menuItem),
            let submenu = menuItem.submenu,
            let submenuWindow = self.menuWindowForMenu(submenu)
        else {
            return
        }
        
        let itemViewBoundsInScreen = itemView.boundsInScreen
        
        let sourceLine = NSRect(
            x: NSEvent.mouseLocation.x,
            y: itemViewBoundsInScreen.origin.y,
            width: 0.0,
            height: itemViewBoundsInScreen.size.height
        )
        
        let destinationArea = submenuWindow.frame
        
        self.cursorTracking = OBWFilteringMenuCursorTracking(subviewOfItem: menuItem, fromSourceLine: sourceLine, toArea: destinationArea)
        
        let interval = OBWFilteringMenuController.periodicEventInterval
        OBWFilteringMenuEventSource.shared.startPeriodicApplicationEvents(afterDelay: interval, withPeriod: interval)
    }
    
    /// Updates the current cursor tracking session.
    private func updateCursorTracking() {
        
        guard let cursorTracking = self.cursorTracking else {
            return
        }
        
        let menuItem = cursorTracking.sourceMenuItem
        
        guard
            let menu = menuItem.menu,
            let window = self.menuWindowForMenu(menu),
            let itemView = window.menuView.viewForMenuItem(menuItem)
        else {
            return
        }
        
        let itemViewBoundsInScreen = itemView.boundsInScreen
        
        let sourceLine = NSRect(
            x: NSEvent.mouseLocation.x,
            y: itemViewBoundsInScreen.origin.y,
            width: 0.0,
            height: itemViewBoundsInScreen.size.height
        )
        
        cursorTracking.sourceLine = sourceLine
    }
    
    /// Ends the current cursor tracking session.
    private func endCursorTracking() {
        
        if self.cursorTracking == nil {
            return
        }
        
        OBWFilteringMenuEventSource.shared.stopPeriodicApplicationEvents()
        self.cursorTracking = nil
    }
    
    
    // MARK: - Scroll Tracking
    
    /// The offscreen scroll bounds changed.
    @objc private func scrollTrackingBoundsChanged(_ notification: Notification) {
        
        guard
            let window = self.menuWindowWithScrollFocus,
            let scrollTracking = notification.object as? OBWFilteringMenuScrollTracking,
            scrollTracking === window.scrollTracking
        else {
            return
        }
        
        guard
            let userInfo = notification.userInfo,
            let menuItemBounds = userInfo[OBWFilteringMenuScrollTracking.Key.bounds] as? NSRect
        else {
            assertionFailure()
            return
        }
        
        _ = window.displayMenuItemBounds(menuItemBounds)
        
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
        
        self.updateMenuWindowsBasedOnCursorLocation(in: pseudoEvent, continueCursorTracking: false)
        self.updateMenuCorners()
    }
    
    
    // MARK: - Auto Scrolling
    
    /// Scalar that defines the rate of scroll acceleration when automatically scrolling a menu.
    private static let scrollAccelerationFactor = 1.1
    
    /// The time interval in seconds at which automatic scrolling occurs.
    private static let scrollInterval = 0.050
    
    /// The window that currently receives auto scrolling events.
    private weak var menuWindowWithScrollFocus: OBWFilteringMenuWindow? = nil
    
    /// The timer that triggers auto scrolling events.
    private weak var scrollTimer: Timer? = nil
    
    /// The timeIntervalSinceReferenceDate when auto scrolling started.
    private var scrollStartInterval: TimeInterval = 0.0
    
    /// Setup autoscrolling in the given direction.
    /// - parameter directionKey: The notification key identifying the scroll direction.
    private func setupAutoscroll(directionKey: Key) {
        
        if
            let userInfo = self.scrollTimer?.userInfo as? [Key:Any],
            userInfo[directionKey] as? Bool == true
        {
            return
        }
        
        guard let topmostMenuWindow = self.menuWindowArray.last else {
            return
        }
        
        let topmostMenu = topmostMenuWindow.filteringMenu
        
        topmostMenu.highlightedItem = nil
        
        self.scrollTimer?.invalidate()
        
        let userInfo: [Key:Any] = [
            .window : topmostMenuWindow,
            directionKey : true
        ]
        
        self.scrollTimer = Timer.scheduledTimer(
            timeInterval: OBWFilteringMenuController.scrollInterval,
            target: self,
            selector: #selector(OBWFilteringMenuController.scrollTimerDidFire(_:)),
            userInfo: userInfo,
            repeats: true
        )
        
        guard let scrollTimer = self.scrollTimer else {
            return
        }
        
        self.scrollStartInterval = Date.timeIntervalSinceReferenceDate
        self.scrollTimerDidFire(scrollTimer)
    }
    
    /// The auto scroll timer fired, scroll the current window.
    @objc private func scrollTimerDidFire(_ timer: Timer) {
        
        guard
            let userInfo = timer.userInfo as? [Key:Any],
            let scrolledWindow = userInfo[.window] as? OBWFilteringMenuWindow
        else {
            return
        }
        
        let upDirection = userInfo[.scrollUp] as? Bool ?? false
        let downDirection = userInfo[.scrollDown] as? Bool ?? false
        assert(upDirection || downDirection)
        
        let scrollDuration = Date.timeIntervalSinceReferenceDate - self.scrollStartInterval
        
        let acceleration: Double
        if scrollDuration > 1.0 {
            acceleration = pow(OBWFilteringMenuController.scrollAccelerationFactor, (scrollDuration - 1.0))
        }
        else {
            acceleration = 1.0
        }
        
        if upDirection && scrolledWindow.menuView.scrollItemsUpWithAcceleration(acceleration) {
            self.scrollTimer?.invalidate()
            self.scrollTimer = nil
        }
        else if downDirection && scrolledWindow.menuView.scrollItemsDownWithAcceleration(acceleration) {
            self.scrollTimer?.invalidate()
            self.scrollTimer = nil
        }
        
        scrolledWindow.resetScrollTracking()
        self.updateMenuCorners()
    }
    
    
    // MARK: - External Notifications
    
    /// A menu item was selected via accessibility APIs.
    @objc private func axDidOpenMenuItem(_ notification: Notification) {
        
        guard
            let userInfo = notification.userInfo as? [Key:Any],
            let menuItem = userInfo[.menuItem] as? OBWFilteringMenuItem,
            self.topmostMenu === menuItem.menu
        else {
            return
        }
        
        if menuItem.submenu != nil {
            self.showSubmenu(ofMenuItem: menuItem, highlightFirstVisibleItem: false)
            self.menuWindowWithKeyboardFocus = self.menuWindowArray.last
        }
        else if menuItem.enabled {
            self.performSelectionOfItem(menuItem)
            OBWFilteringMenuEventSubtype.accessibleItemSelection.post(atStart: true)
        }
    }
    
    /// Filtering caused a menu to change size.
    @objc private func menuViewTotalItemSizeDidChange(_ notification: Notification) {
        self.updateMenuCorners()
    }
    
    /// A Cocoa menu began tracking.
    @objc private func externalMenuDidBeginTracking(_ notification: Notification) {
        self.makeTopmostMenuWindow(nil, withAnimation: true)
    }
}
