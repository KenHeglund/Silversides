/*===========================================================================
 OBWFilteringMenuScrollTracking.swift
 Silversides
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

let OBWFilteringMenuScrollTrackingBoundsChangedNotification = "ESCFilteringMenuScrollTrackingBoundsChangedNotification"
let OBWFilteringMenuScrollTrackingBoundsValueKey = "ESCFilteringMenuScrollTrackingBoundsValueKey"

/*==========================================================================*/

private enum ScrollTrackingClipMode {
    case None
    case Top
    case Bottom
    case Both
}

private enum ScrollTrackingAction {
    case Scrolling
    case BottomBounce
    case TopBounce
    case ResizeUp
    case ResizeDown
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
            styleMask: NSBorderlessWindowMask,
            backing: .Buffered,
            defer: true
        )
        
        self.window = window
        
        let smallScrollViewFrame = initialDocumentFrame
        let smallScrollView = NSScrollView( frame: smallScrollViewFrame )
        smallScrollView.hasVerticalScroller = true
        smallScrollView.verticalScrollElasticity = .Allowed
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
        largeScrollView.verticalScrollElasticity = .Allowed
        largeScrollView.documentView = NSView( frame: initialDocumentFrame )
        largeScrollView.contentView.postsBoundsChangedNotifications = true
        window.contentView?.addSubview( largeScrollView )
        self.largeScrollView = largeScrollView
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        notificationCenter.addObserver( self, selector: #selector(OBWFilteringMenuScrollTracking.smallScrollViewBoundsChanged(_:)), name: NSViewBoundsDidChangeNotification, object: smallScrollView.contentView )
        notificationCenter.addObserver( self, selector: #selector(OBWFilteringMenuScrollTracking.largeScrollViewBoundsChanged(_:)), name: NSViewBoundsDidChangeNotification, object: largeScrollView.contentView )
    }
    
    /*==========================================================================*/
    deinit {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver( self, name: NSViewBoundsDidChangeNotification, object: nil )
        self.smallScrollView.contentView.postsBoundsChangedNotifications = false
        self.largeScrollView.contentView.postsBoundsChangedNotifications = false
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringScrollTracking implementation
    
    /*==========================================================================*/
    func reset( totalMenuItemSize: NSSize, initialBounds: NSRect, finalBounds: NSRect ) {
        
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
        
        let smallScrollViewSize = NSScrollView.frameSizeForContentSize(
            smallScrollViewContentSize,
            horizontalScrollerClass: nil,
            verticalScrollerClass: NSScroller.self,
            borderType: .NoBorder,
            controlSize: .Small,
            scrollerStyle: .Overlay
        )
        
        let largeScrollViewSize = NSScrollView.frameSizeForContentSize(
            largeScrollViewContentSize,
            horizontalScrollerClass: nil,
            verticalScrollerClass: NSScroller.self,
            borderType: .NoBorder,
            controlSize: .Small,
            scrollerStyle: .Overlay
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
            self.clipMode = .None
        }
        else if initialBounds.origin.y == 0.0 {
            self.clipMode = .Top
        }
        else if initialBounds.origin.y + initialBounds.size.height == totalMenuItemSize.height {
            self.clipMode = .Bottom
        }
        else {
            self.clipMode = .Both
        }
        
        smallScrollView.contentView.scrollToPoint( initialBounds.origin )
        smallScrollView.reflectScrolledClipView( smallScrollView.contentView )
        
        largeScrollView.contentView.scrollToPoint( initialBounds.origin )
        largeScrollView.reflectScrolledClipView( largeScrollView.contentView )
        
        self.action = .Scrolling
        self.adjustingBounds = false
    }
    
    /*==========================================================================*/
    func scrollEvent( event: NSEvent ) {
        
        #if PRINT_SCROLL_EVENTS
            let dataRef = CGEventCreateData( kCFAllocatorDefault, event.CGEvent )!
            let eventData = dataRef as NSData
            let eventString = eventData.base64EncodedStringWithOptions( [] )
            Swift.print( "let encodedEvent = \"\(eventString)\"" )
        #endif // PRINT_SCROLL_EVENTS
        
        let scrollingDeltaY = ( event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : event.deltaY )
        let clipMode = self.clipMode
        let action = self.action
        let smallScrollBoundsSize = self.smallScrollView.contentView.bounds.size
        let finalBoundsSize = self.finalVisibleBounds.size
        
        if smallScrollBoundsSize.height == self.totalMenuItemSize.height {
            // don't bounce when the entire menu is visible
        }
        else if scrollingDeltaY == 0.0 {
            
            if action == .BottomBounce || action == .TopBounce {
                self.smallScrollView.scrollWheel( event )
            }
            else if action == .ResizeUp || action == .ResizeDown {
                self.largeScrollView.scrollWheel( event )
            }
        }
        else if scrollingDeltaY < 0.0 {
            
            // Content up
            
            if clipMode == .Top || smallScrollBoundsSize.height == finalBoundsSize.height {
                self.action = .BottomBounce
                self.smallScrollView.scrollWheel( event )
            }
            else {
                self.action = .ResizeUp
                self.largeScrollView.scrollWheel( event )
            }
        }
        else if scrollingDeltaY > 0.0 {
            
            // Content down
            
            if clipMode == .Bottom || smallScrollBoundsSize.height == finalBoundsSize.height {
                self.action = .TopBounce
                self.smallScrollView.scrollWheel( event )
            }
            else {
                self.action = .ResizeDown
                self.largeScrollView.scrollWheel( event )
            }
        }
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringScrollTracking private
    
    private static let scrollViewWidth: CGFloat = 10.0
    
    private let window: NSWindow
    unowned private let smallScrollView: NSScrollView
    unowned private let largeScrollView: NSScrollView
    
    private var totalMenuItemSize = NSZeroSize
    private var initialVisibleBounds = NSZeroRect
    private var finalVisibleBounds = NSZeroRect
    
    private var action: ScrollTrackingAction = .Scrolling
    private var clipMode: ScrollTrackingClipMode = .None
    private var adjustingBounds = false
    
    /*==========================================================================*/
    @objc private func smallScrollViewBoundsChanged( notification: NSNotification ) {
        
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
            largeScrollView.contentView.scrollToPoint( smallMenuItemBounds.origin )
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
        NSNotificationCenter.defaultCenter().postNotificationName(
            OBWFilteringMenuScrollTrackingBoundsChangedNotification,
            object: self,
            userInfo: userInfo
        )
        
        self.adjustingBounds = false
    }
    
    /*==========================================================================*/
    @objc private func largeScrollViewBoundsChanged( notification: NSNotification ) {
        
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
        
        if clipMode == .Bottom {
            
            smallMenuItemBounds = NSRect(
                x: 0.0,
                y: largeMenuItemBounds.origin.y,
                width: OBWFilteringMenuScrollTracking.scrollViewWidth,
                height: min( menuSize.height - largeMenuItemBounds.origin.y, finalBounds.size.height )
            )
        }
        else if clipMode == .Top {
            
            smallMenuItemBounds = NSRect(
                x: 0.0,
                y: max( 0.0, largeMenuItemBounds.origin.y - ( finalBounds.size.height - initialBounds.size.height ) ),
                width: OBWFilteringMenuScrollTracking.scrollViewWidth,
                height: min( finalBounds.size.height, finalBounds.size.height - ( largeDocumentBounds.size.height - menuSize.height ) + largeMenuItemBounds.origin.y )
            )
        }
        
        let scrollFrameSize = NSScrollView.frameSizeForContentSize(
            smallMenuItemBounds.size,
            horizontalScrollerClass: nil,
            verticalScrollerClass: NSScroller.self,
            borderType: .NoBorder,
            controlSize: .Small,
            scrollerStyle: .Overlay
        )
        
        if scrollFrameSize != smallScrollView.frame.size {
            smallScrollView.setFrameSize( scrollFrameSize )
        }
        
        smallScrollView.contentView.scrollToPoint( smallMenuItemBounds.origin )
        smallScrollView.reflectScrolledClipView( smallScrollView.contentView )
        
        let menuItemBounds = NSRect(
            x: smallMenuItemBounds.origin.x,
            y: smallMenuItemBounds.origin.y,
            width: menuSize.width,
            height: smallMenuItemBounds.size.height
        )
        
        let boundsValue = NSValue( rect: menuItemBounds )
        let userInfo = [ OBWFilteringMenuScrollTrackingBoundsValueKey : boundsValue ]
        NSNotificationCenter.defaultCenter().postNotificationName(
            OBWFilteringMenuScrollTrackingBoundsChangedNotification,
            object: self,
            userInfo: userInfo
        )
        
        self.adjustingBounds = false
    }
}
