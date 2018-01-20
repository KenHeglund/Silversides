/*===========================================================================
 OBWFilteringMenuScrollTracking.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

let OBWFilteringMenuScrollTrackingBoundsChangedNotification = Notification.Name(rawValue: "ESCFilteringMenuScrollTrackingBoundsChangedNotification")
let OBWFilteringMenuScrollTrackingBoundsValueKey = "ESCFilteringMenuScrollTrackingBoundsValueKey"

/*==========================================================================*/

private enum ScrollTrackingClipMode {
    case none
    case top
    case bottom
    case both
}

private enum ScrollTrackingAction {
    case scrolling
    case bottomBounce
    case topBounce
    case resizeUp
    case resizeDown
}

/*==========================================================================*/

class OBWFilteringMenuScrollTracking {
    
    /*==========================================================================*/
    init() {
        
        let initialDocumentFrame = NSRect(
            width: OBWFilteringMenuScrollTracking.scrollViewWidth,
            height: 100.0
        )
        
        let windowContentFrame = NSRect(
            width: OBWFilteringMenuScrollTracking.scrollViewWidth * 2.0,
            height: initialDocumentFrame.size.height
        )
        
        let window = NSWindow(
            contentRect: windowContentFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: true
        )
        
        self.window = window
        
        let smallScrollViewFrame = initialDocumentFrame
        let smallScrollView = NSScrollView( frame: smallScrollViewFrame )
        smallScrollView.hasVerticalScroller = true
        smallScrollView.verticalScrollElasticity = .allowed
        smallScrollView.documentView = NSView( frame: initialDocumentFrame )
        smallScrollView.contentView.postsBoundsChangedNotifications = true
        window.contentView?.addSubview( smallScrollView )
        self.smallScrollView = smallScrollView
        
        let largeScrollViewFrame = NSRect(
            origin: NSPoint( x: smallScrollViewFrame.maxX, y: 0.0 ),
            size: initialDocumentFrame.size
        )
        
        let largeScrollView = NSScrollView( frame: largeScrollViewFrame )
        largeScrollView.hasVerticalScroller = true
        largeScrollView.verticalScrollElasticity = .allowed
        largeScrollView.documentView = NSView( frame: initialDocumentFrame )
        largeScrollView.contentView.postsBoundsChangedNotifications = true
        window.contentView?.addSubview( largeScrollView )
        self.largeScrollView = largeScrollView
        
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver( self, selector: #selector(OBWFilteringMenuScrollTracking.smallScrollViewBoundsChanged(_:)), name: NSView.boundsDidChangeNotification, object: smallScrollView.contentView )
        notificationCenter.addObserver( self, selector: #selector(OBWFilteringMenuScrollTracking.largeScrollViewBoundsChanged(_:)), name: NSView.boundsDidChangeNotification, object: largeScrollView.contentView )
    }
    
    /*==========================================================================*/
    deinit {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver( self, name: NSView.boundsDidChangeNotification, object: nil )
        self.smallScrollView.contentView.postsBoundsChangedNotifications = false
        self.largeScrollView.contentView.postsBoundsChangedNotifications = false
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringScrollTracking implementation
    
    /*==========================================================================*/
    func reset( _ totalMenuItemSize: NSSize, initialBounds: NSRect, finalBounds: NSRect ) {
        
        if self.totalMenuItemSize == totalMenuItemSize && self.initialVisibleBounds == initialBounds && self.finalVisibleBounds == finalBounds {
            return
        }
        
        self.adjustingBounds = true
        
        self.totalMenuItemSize = totalMenuItemSize
        self.initialVisibleBounds = initialBounds
        self.finalVisibleBounds = finalBounds
        
        let smallScrollViewContentSize = NSSize(
            width: OBWFilteringMenuScrollTracking.scrollViewWidth,
            height: initialBounds.size.height
        )
        
        let largeScrollViewContentSize = NSSize(
            width: OBWFilteringMenuScrollTracking.scrollViewWidth,
            height: finalBounds.size.height
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
            height: max( smallScrollViewSize.height, largeScrollViewSize.height )
        )
        
        let windowFrame = window.frame
        if windowFrame.size.width < windowContentFrame.size.width || windowFrame.size.height < windowContentFrame.size.height {
            window.setFrame( windowContentFrame, display: true )
        }
        
        let smallScrollView = self.smallScrollView
        let smallDocumentView = smallScrollView.documentView!
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
        
        let largeScrollView = self.largeScrollView
        let largeDocumentView = largeScrollView.documentView!
        let largeDocumentFrame = NSRect(
            width: OBWFilteringMenuScrollTracking.scrollViewWidth,
            height: totalMenuItemSize.height - initialBounds.size.height + finalBounds.size.height
        )
        largeDocumentView.frame = largeDocumentFrame
        
        let largeScrollViewFrame = NSRect(
            x: OBWFilteringMenuScrollTracking.scrollViewWidth,
            y: 0.0,
            width: OBWFilteringMenuScrollTracking.scrollViewWidth,
            height: largeScrollViewSize.height
        )
        largeScrollView.frame = largeScrollViewFrame
        
        if initialBounds.size.height == totalMenuItemSize.height {
            self.clipMode = .none
        }
        else if initialBounds.origin.y == 0.0 {
            self.clipMode = .top
        }
        else if initialBounds.origin.y + initialBounds.size.height == totalMenuItemSize.height {
            self.clipMode = .bottom
        }
        else {
            self.clipMode = .both
        }
        
        smallScrollView.contentView.scroll( to: initialBounds.origin )
        smallScrollView.reflectScrolledClipView( smallScrollView.contentView )
        
        largeScrollView.contentView.scroll( to: initialBounds.origin )
        largeScrollView.reflectScrolledClipView( largeScrollView.contentView )
        
        self.action = .scrolling
        self.adjustingBounds = false
    }
    
    /*==========================================================================*/
    func scrollEvent( _ event: NSEvent ) {
        
        let scrollingDeltaY = ( event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : event.deltaY )
        let clipMode = self.clipMode
        let action = self.action
        let smallScrollBoundsSize = self.smallScrollView.contentView.bounds.size
        let finalBoundsSize = self.finalVisibleBounds.size
        
        if smallScrollBoundsSize.height == self.totalMenuItemSize.height {
            // don't bounce when the entire menu is visible
        }
        else if scrollingDeltaY == 0.0 {
            
            if action == .bottomBounce || action == .topBounce {
                self.smallScrollView.scrollWheel( with: event )
            }
            else if action == .resizeUp || action == .resizeDown {
                self.largeScrollView.scrollWheel( with: event )
            }
        }
        else if scrollingDeltaY < 0.0 {
            
            // Content up
            
            if clipMode == .top || smallScrollBoundsSize.height == finalBoundsSize.height {
                self.action = .bottomBounce
                self.smallScrollView.scrollWheel( with: event )
            }
            else {
                self.action = .resizeUp
                self.largeScrollView.scrollWheel( with: event )
            }
        }
        else if scrollingDeltaY > 0.0 {
            
            // Content down
            
            if clipMode == .bottom || smallScrollBoundsSize.height == finalBoundsSize.height {
                self.action = .topBounce
                self.smallScrollView.scrollWheel( with: event )
            }
            else {
                self.action = .resizeDown
                self.largeScrollView.scrollWheel( with: event )
            }
        }
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringScrollTracking private
    
    fileprivate static let scrollViewWidth: CGFloat = 10.0
    
    fileprivate let window: NSWindow
    unowned fileprivate let smallScrollView: NSScrollView
    unowned fileprivate let largeScrollView: NSScrollView
    
    fileprivate var totalMenuItemSize = NSZeroSize
    fileprivate var initialVisibleBounds = NSZeroRect
    fileprivate var finalVisibleBounds = NSZeroRect
    
    fileprivate var action: ScrollTrackingAction = .scrolling
    fileprivate var clipMode: ScrollTrackingClipMode = .none
    fileprivate var adjustingBounds = false
    
    /*==========================================================================*/
    @objc fileprivate func smallScrollViewBoundsChanged( _ notification: Notification ) {
        
        guard !self.adjustingBounds else { return }
        
        self.adjustingBounds = true
        
        let smallScrollView = self.smallScrollView
        let largeScrollView = self.largeScrollView
        let smallMenuItemBounds = smallScrollView.contentView.bounds
        
        let menuSize = self.totalMenuItemSize
        let finalBounds = self.finalVisibleBounds
        
        if smallMenuItemBounds.size.height < finalBounds.size.height {
            
            let largeDocumentFrame = NSRect(
                width: OBWFilteringMenuScrollTracking.scrollViewWidth,
                height: menuSize.height - smallMenuItemBounds.size.height + finalBounds.size.height
            )
            
            let largeDocumentView = largeScrollView.documentView
            largeDocumentView?.setFrameSize( largeDocumentFrame.size )
            largeScrollView.contentView.scroll( to: smallMenuItemBounds.origin )
            largeScrollView.reflectScrolledClipView( largeScrollView.contentView )
        }
        
        let menuItemBounds = NSRect(
            x: smallMenuItemBounds.origin.x,
            y: smallMenuItemBounds.origin.y,
            width: menuSize.width,
            height: smallMenuItemBounds.size.height
        )
        
        let boundsValue = NSValue( rect: menuItemBounds )
        let userInfo = [ OBWFilteringMenuScrollTrackingBoundsValueKey : boundsValue ]
        NotificationCenter.default.post(
            name: OBWFilteringMenuScrollTrackingBoundsChangedNotification,
            object: self,
            userInfo: userInfo
        )
        
        self.adjustingBounds = false
    }
    
    /*==========================================================================*/
    @objc fileprivate func largeScrollViewBoundsChanged( _ notification: Notification ) {
        
        guard !self.adjustingBounds else { return }
        
        self.adjustingBounds = true
        
        let smallScrollView = self.smallScrollView
        let largeScrollView = self.largeScrollView
        let largeDocumentBounds = largeScrollView.documentView!.bounds
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
                height: min( menuSize.height - largeMenuItemBounds.origin.y, finalBounds.size.height )
            )
        }
        else if clipMode == .top {
            
            smallMenuItemBounds = NSRect(
                x: 0.0,
                y: max( 0.0, largeMenuItemBounds.origin.y - ( finalBounds.size.height - initialBounds.size.height ) ),
                width: OBWFilteringMenuScrollTracking.scrollViewWidth,
                height: min( finalBounds.size.height, finalBounds.size.height - ( largeDocumentBounds.size.height - menuSize.height ) + largeMenuItemBounds.origin.y )
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
        
        if scrollFrameSize != smallScrollView.frame.size {
            smallScrollView.setFrameSize( scrollFrameSize )
        }
        
        smallScrollView.contentView.scroll( to: smallMenuItemBounds.origin )
        smallScrollView.reflectScrolledClipView( smallScrollView.contentView )
        
        let menuItemBounds = NSRect(
            x: smallMenuItemBounds.origin.x,
            y: smallMenuItemBounds.origin.y,
            width: menuSize.width,
            height: smallMenuItemBounds.size.height
        )
        
        let boundsValue = NSValue( rect: menuItemBounds )
        let userInfo = [ OBWFilteringMenuScrollTrackingBoundsValueKey : boundsValue ]
        NotificationCenter.default.post(
            name: OBWFilteringMenuScrollTrackingBoundsChangedNotification,
            object: self,
            userInfo: userInfo
        )
        
        self.adjustingBounds = false
    }
}
