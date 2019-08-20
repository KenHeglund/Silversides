/*===========================================================================
 OBWFilteringMenuScrollTracking.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit

/// A function that (if assigned) will print an NSEvent for debugging purposes.
var scrollTrackingEventPrinter: ((NSEvent) -> Void)? = nil

/// A class to track the response to scroll wheel events in menus.  Depending on the size of the menu and the area that is currently visible, the response might be to scroll the menu contents, resize the menu window, or nothing at all.
class OBWFilteringMenuScrollTracking {
    
    /// Initialization.
    init() {
        
        let initialDocumentFrame = NSRect(
            width: OBWFilteringMenuScrollTracking.scrollViewWidth,
            height: 100.0
        )
        
        let windowContentFrame = NSRect(
            width: OBWFilteringMenuScrollTracking.scrollViewWidth * 2.0,
            height: initialDocumentFrame.height
        )
        
        let window = NSWindow(
            contentRect: windowContentFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: true
        )
        
        self.window = window
        
        let smallScrollViewFrame = initialDocumentFrame
        let smallScrollView = NSScrollView(frame: smallScrollViewFrame)
        smallScrollView.hasVerticalScroller = true
        smallScrollView.verticalScrollElasticity = .allowed
        smallScrollView.documentView = NSView(frame: initialDocumentFrame)
        smallScrollView.contentView.postsBoundsChangedNotifications = true
        window.contentView?.addSubview(smallScrollView)
        self.smallScrollView = smallScrollView
        
        let largeScrollViewFrame = NSRect(
            origin: NSPoint(x: smallScrollViewFrame.maxX, y: 0.0),
            size: initialDocumentFrame.size
        )
        
        let largeScrollView = NSScrollView(frame: largeScrollViewFrame)
        largeScrollView.hasVerticalScroller = true
        largeScrollView.verticalScrollElasticity = .allowed
        largeScrollView.documentView = NSView(frame: initialDocumentFrame)
        largeScrollView.contentView.postsBoundsChangedNotifications = true
        window.contentView?.addSubview(largeScrollView)
        self.largeScrollView = largeScrollView
        
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(OBWFilteringMenuScrollTracking.smallScrollViewBoundsChanged(_:)), name: NSView.boundsDidChangeNotification, object: smallScrollView.contentView)
        notificationCenter.addObserver(self, selector: #selector(OBWFilteringMenuScrollTracking.largeScrollViewBoundsChanged(_:)), name: NSView.boundsDidChangeNotification, object: largeScrollView.contentView)
    }
    
    /// Deinitialization.
    deinit {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSView.boundsDidChangeNotification, object: nil)
        self.smallScrollView.contentView.postsBoundsChangedNotifications = false
        self.largeScrollView.contentView.postsBoundsChangedNotifications = false
    }
    
    
    // MARK: - OBWFilteringScrollTracking Implementation
    
    /// Reset scroll tracking with the given initial conditions.
    /// - parameter totalMenuItemSize: The size of all menu items.
    /// - parameter initialBounds: The initial visible area of the menu item view.
    /// - parameter finalBounds: The maximum visible area of the menu item view.
    func reset(_ totalMenuItemSize: NSSize, initialBounds: NSRect, finalBounds: NSRect) {
        
        if self.totalMenuItemSize == totalMenuItemSize, self.initialVisibleBounds == initialBounds, self.finalVisibleBounds == finalBounds {
            return
        }
        
        self.adjustingBounds = true
        
        self.totalMenuItemSize = totalMenuItemSize
        self.initialVisibleBounds = initialBounds
        self.finalVisibleBounds = finalBounds
        
        let smallScrollViewContentSize = NSSize(
            width: OBWFilteringMenuScrollTracking.scrollViewWidth,
            height: initialBounds.height
        )
        
        let largeScrollViewContentSize = NSSize(
            width: OBWFilteringMenuScrollTracking.scrollViewWidth,
            height: finalBounds.height
        )
        
        let smallScrollViewSize = NSScrollView.frameSize(
            forContentSize: smallScrollViewContentSize,
            horizontalScrollerClass: nil,
            verticalScrollerClass: NSScroller.self,
            borderType: .noBorder,
            controlSize: .small,
            scrollerStyle: .overlay
        )
        
        let largeScrollViewSize = NSScrollView.frameSize(
            forContentSize: largeScrollViewContentSize,
            horizontalScrollerClass: nil,
            verticalScrollerClass: NSScroller.self,
            borderType: .noBorder,
            controlSize: .small,
            scrollerStyle: .overlay
        )
        
        let window = self.window
        let windowContentFrame = NSRect(
            width: OBWFilteringMenuScrollTracking.scrollViewWidth * 3.0,
            height: max(smallScrollViewSize.height, largeScrollViewSize.height)
        )
        
        let windowFrame = window.frame
        if windowFrame.width < windowContentFrame.width || windowFrame.height < windowContentFrame.height {
            window.setFrame(windowContentFrame, display: true)
        }
        
        let smallScrollView = self.smallScrollView
        let largeScrollView = self.largeScrollView
        
        guard
            let smallDocumentView = smallScrollView.documentView,
            let largeDocumentView = largeScrollView.documentView
        else {
            return
        }
        
        let smallDocumentFrame = NSRect(
            width: OBWFilteringMenuScrollTracking.scrollViewWidth,
            height: totalMenuItemSize.height
        )
        smallDocumentView.frame = smallDocumentFrame
        
        let smallScrollViewFrame = NSRect(
            width: OBWFilteringMenuScrollTracking.scrollViewWidth,
            height: smallScrollViewSize.height
        )
        smallScrollView.frame = smallScrollViewFrame
        
        let largeDocumentFrame = NSRect(
            width: OBWFilteringMenuScrollTracking.scrollViewWidth,
            height: totalMenuItemSize.height - initialBounds.height + finalBounds.height
        )
        largeDocumentView.frame = largeDocumentFrame
        
        let largeScrollViewFrame = NSRect(
            x: OBWFilteringMenuScrollTracking.scrollViewWidth,
            y: 0.0,
            width: OBWFilteringMenuScrollTracking.scrollViewWidth,
            height: largeScrollViewSize.height
        )
        largeScrollView.frame = largeScrollViewFrame
        
        if initialBounds.height == totalMenuItemSize.height {
            self.clipMode = .none
        }
        else if initialBounds.minY == 0.0 {
            self.clipMode = .top
        }
        else if initialBounds.minY + initialBounds.height == totalMenuItemSize.height {
            self.clipMode = .bottom
        }
        else {
            self.clipMode = .topAndBottom
        }
        
        smallScrollView.contentView.scroll(to: initialBounds.origin)
        smallScrollView.reflectScrolledClipView(smallScrollView.contentView)
        
        largeScrollView.contentView.scroll(to: initialBounds.origin)
        largeScrollView.reflectScrolledClipView(largeScrollView.contentView)
        
        self.action = .scrolling
        self.adjustingBounds = false
    }
    
    /// Handle a scroll wheel event.
    /// - parameter event: The event to handle.
    func scrollEvent(_ rawEvent: NSEvent) {
        
        scrollTrackingEventPrinter?(rawEvent)
        
        let clampedEvent = self.clampedEvent(fromEvent: rawEvent)
        let scrollingDeltaY = clampedEvent.effectiveScrollDeltaY
        
        let clipMode = self.clipMode
        let action = self.action
        let smallScrollBoundsSize = self.smallScrollView.contentView.bounds.size
        let finalBoundsSize = self.finalVisibleBounds.size
        
        if smallScrollBoundsSize.height == self.totalMenuItemSize.height {
            // don't bounce when the entire menu is visible
        }
        else if scrollingDeltaY == 0.0 {
            
            if action == .bottomStretch || action == .topStretch {
                self.smallScrollView.scrollWheel(with: clampedEvent)
            }
            else if action == .resizeUp || action == .resizeDown {
                self.largeScrollView.scrollWheel(with: clampedEvent)
            }
        }
        else if scrollingDeltaY < 0.0 {
            
            // Content up
            
            if clipMode == .top || smallScrollBoundsSize.height == finalBoundsSize.height {
                self.action = .bottomStretch
                self.smallScrollView.scrollWheel(with: clampedEvent)
            }
            else {
                self.action = .resizeUp
                self.largeScrollView.scrollWheel(with: clampedEvent)
            }
        }
        else if scrollingDeltaY > 0.0 {
            
            // Content down
            
            if clipMode == .bottom || smallScrollBoundsSize.height == finalBoundsSize.height {
                self.action = .topStretch
                self.smallScrollView.scrollWheel(with: clampedEvent)
            }
            else {
                self.action = .resizeDown
                self.largeScrollView.scrollWheel(with: clampedEvent)
            }
        }
    }
    
    
    // MARK: - Private
    
    /// An enum to describe which ends of a menu are being clipped by the top or bottom of the screen.
    private enum ScrollTrackingClipMode {
        /// The menu is not being clipped, it is completely visible.
        case none
        /// The top of the menu is clipped.
        case top
        /// The bottom of the menu is clipped.
        case bottom
        /// Both the top and bottom of the menu are being clipped.
        case topAndBottom
    }
    
    /// An enum to describe how the menu is currently responding to scroll events.
    private enum ScrollTrackingAction {
        /// The content of the menu is scrolling.
        case scrolling
        /// The content has scrolled up as far as possible and is being stretched upward.
        case bottomStretch
        /// The content has scroll down as far as possible and is being strecched downward.
        case topStretch
        /// The menu is resizing upward.
        case resizeUp
        /// The menu is resizing downward.
        case resizeDown
    }
    
    /// Width of the offscreen scroll views.
    private static let scrollViewWidth: CGFloat = 10.0
    
    /// The offscreen window containing scroll views.
    private let window: NSWindow
    
    /// Offscreen scroll view used to generate an elastic response.
    unowned private let smallScrollView: NSScrollView
    
    /// Offscreen scroll view used to generate a scroll or resize response.
    unowned private let largeScrollView: NSScrollView
    
    /// The total size of all menu items.
    private var totalMenuItemSize: NSSize = .zero
    
    /// The initial bounds of the visible menu items.
    private var initialVisibleBounds: NSRect = .zero
    
    /// The maximum bounds of the visible menu items.
    private var finalVisibleBounds: NSRect = .zero
    
    /// The scroll action that is currently taking place.
    private var action: ScrollTrackingAction = .scrolling
    
    /// The current clip mode.
    private var clipMode: ScrollTrackingClipMode = .none
    
    /// When `true`, the offscreen bounds are being changed programmatically.
    private var adjustingBounds = false
    
    /// Records the delta from the previous scroll event.
    private var previousScrollEventDelta: CGFloat = 0.0
    
    /// Responds to a change in the small scroll view's bounds.
    @objc private func smallScrollViewBoundsChanged(_ notification: Notification) {
        
        guard self.adjustingBounds == false else {
            return
        }
        
        self.adjustingBounds = true
        
        let smallScrollView = self.smallScrollView
        let largeScrollView = self.largeScrollView
        let smallMenuItemBounds = smallScrollView.contentView.bounds
        
        let menuSize = self.totalMenuItemSize
        let finalBounds = self.finalVisibleBounds
        
        if smallMenuItemBounds.height < finalBounds.height {
            
            let largeDocumentFrame = NSRect(
                width: OBWFilteringMenuScrollTracking.scrollViewWidth,
                height: menuSize.height - smallMenuItemBounds.height + finalBounds.height
            )
            
            let largeDocumentView = largeScrollView.documentView
            largeDocumentView?.setFrameSize(largeDocumentFrame.size)
            largeScrollView.contentView.scroll(to: smallMenuItemBounds.origin)
            largeScrollView.reflectScrolledClipView(largeScrollView.contentView)
        }
        
        let menuItemBounds = NSRect(
            x: smallMenuItemBounds.minX,
            y: smallMenuItemBounds.minY,
            width: menuSize.width,
            height: smallMenuItemBounds.height
        )
        
        let userInfo = [OBWFilteringMenuScrollTracking.Key.bounds : menuItemBounds]
        NotificationCenter.default.post(
            name: OBWFilteringMenuScrollTracking.boundsChangedNotification,
            object: self,
            userInfo: userInfo
        )
        
        self.adjustingBounds = false
    }
    
    /// Responds to a change in the large scroll view's bounds.
    @objc private func largeScrollViewBoundsChanged(_ notification: Notification) {
        
        guard self.adjustingBounds == false else {
            return
        }
        
        let smallScrollView = self.smallScrollView
        let largeScrollView = self.largeScrollView
        
        guard let documentView = self.largeScrollView.documentView else {
            return
        }
        
        let largeDocumentBounds = documentView.bounds
        let largeMenuItemBounds = largeScrollView.contentView.bounds
        
        let menuSize = self.totalMenuItemSize
        let initialBounds = self.initialVisibleBounds
        let finalBounds = self.finalVisibleBounds
        
        let clipMode = self.clipMode
        var smallMenuItemBounds = NSZeroRect
        
        if clipMode == .bottom {
            
            smallMenuItemBounds = NSRect(
                x: 0.0,
                y: largeMenuItemBounds.origin.y,
                width: OBWFilteringMenuScrollTracking.scrollViewWidth,
                height: min(menuSize.height - largeMenuItemBounds.origin.y, finalBounds.height)
            )
        }
        else if clipMode == .top {
            
            smallMenuItemBounds = NSRect(
                x: 0.0,
                y: max(0.0, largeMenuItemBounds.origin.y - (finalBounds.height - initialBounds.height)),
                width: OBWFilteringMenuScrollTracking.scrollViewWidth,
                height: min(finalBounds.height, finalBounds.height - (largeDocumentBounds.height - menuSize.height) + largeMenuItemBounds.origin.y)
            )
        }

        let scrollFrameSize = NSScrollView.frameSize(
            forContentSize: smallMenuItemBounds.size,
            horizontalScrollerClass: nil,
            verticalScrollerClass: NSScroller.self,
            borderType: .noBorder,
            controlSize: .small,
            scrollerStyle: .overlay
        )
        
        guard scrollFrameSize.height >= smallScrollView.frame.height else {
            return
        }
        
        self.adjustingBounds = true
        
        if scrollFrameSize != smallScrollView.frame.size {
            smallScrollView.setFrameSize(scrollFrameSize)
        }

        smallScrollView.contentView.scroll(to: smallMenuItemBounds.origin)
        smallScrollView.reflectScrolledClipView(smallScrollView.contentView)
        
        let menuItemBounds = NSRect(
            x: smallMenuItemBounds.origin.x,
            y: smallMenuItemBounds.origin.y,
            width: menuSize.width,
            height: smallMenuItemBounds.height
        )
        
        let userInfo = [OBWFilteringMenuScrollTracking.Key.bounds : menuItemBounds]
        NotificationCenter.default.post(
            name: OBWFilteringMenuScrollTracking.boundsChangedNotification,
            object: self,
            userInfo: userInfo
        )
        
        self.adjustingBounds = false
    }
    
    /// The previously handled scroll wheel event.
    private var previousScrollEvent: NSEvent? = nil
    
    /// Clamps the scroll magnitude of the given event to a reasonable magnitude.
    /// - parameter sourceEvent: A scroll wheel event.
    /// - returns: Returns the original event if the scroll magnitude is acceptable.  Otherwise, creates a new event.
    private func clampedEvent(fromEvent sourceEvent: NSEvent) -> NSEvent {
        
        let scrollEventDelta = sourceEvent.effectiveScrollDeltaY
        let largestAcceptableScrollEventDelta: CGFloat = 100.0
        
        if scrollEventDelta.magnitude <= largestAcceptableScrollEventDelta {
            self.previousScrollEvent = sourceEvent
            return sourceEvent
        }
        
        let clampedEventDelta: CGFloat
        if let previousEvent = self.previousScrollEvent {
            
            let previousScrollEventDelta = previousEvent.effectiveScrollDeltaY
            
            if scrollEventDelta.sign == previousScrollEventDelta.sign {
                clampedEventDelta = previousScrollEventDelta
            }
            else {
                clampedEventDelta = (scrollEventDelta / scrollEventDelta.magnitude)
            }
        }
        else {
            clampedEventDelta = (scrollEventDelta / scrollEventDelta.magnitude)
        }
        
        let eventSource = CGEventSource(event: sourceEvent.cgEvent)
        
        if
            let cgEvent = CGEvent(scrollWheelEvent2Source: eventSource, units: .pixel, wheelCount: 1, wheel1: Int32(clampedEventDelta), wheel2: 0, wheel3: 0),
            let clampedEvent = NSEvent(cgEvent: cgEvent)
        {
            self.previousScrollEvent = clampedEvent
            return clampedEvent
        }
        else {
            self.previousScrollEvent = sourceEvent
            return sourceEvent
        }
    }
    
}


// MARK: -

/// Notification definitions.
extension OBWFilteringMenuScrollTracking {
    
    /// Scroll tracking bounds changed.
    /// - parameter object: The scroll tracking object.
    /// - parameter userInfo: value - An NSRect containing the new menu item bounds.
    static let boundsChangedNotification = Notification.Name(rawValue: "ESCFilteringMenuScrollTrackingBoundsChangedNotification")
    
    /// A type defining notification keys.
    struct Key: Hashable, RawRepresentable {
        let rawValue: String
        
        /// An NSRect containing a bounds rectangle.
        static let bounds = OBWFilteringMenuScrollTracking.Key(rawValue: "ESCFilteringMenuScrollTrackingBoundsValueKey")
    }
}


extension NSEvent {
    
    var  effectiveScrollDeltaY: CGFloat {
        return (self.hasPreciseScrollingDeltas ? self.scrollingDeltaY : self.deltaY)
    }
}
