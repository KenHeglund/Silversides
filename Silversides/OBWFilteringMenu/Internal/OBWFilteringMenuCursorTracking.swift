/*===========================================================================
 OBWFilteringMenuCursorTracking.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

class OBWFilteringMenuCursorTracking {
    
    /*==========================================================================*/
    init( subviewOfItem: OBWFilteringMenuItem, fromSourceLine: NSRect, toArea: NSRect ) {
        
        self.sourceMenuItem = subviewOfItem
        self.destinationArea = toArea
        
        OBWFilteringMenuCursorTracking.debugWindow?.trackingView.cursorTracking = self
        OBWFilteringMenuCursorTracking.debugWindow?.orderFront( nil )
        
        self.sourceLine = fromSourceLine
        
        self.recalculateLimits()
        self.resetWaypoints()
    }
    
    /*==========================================================================*/
    deinit {
        OBWFilteringMenuCursorTracking.debugWindow?.trackingView.cursorTracking = nil
        OBWFilteringMenuCursorTracking.debugWindow?.orderOut( nil )
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuCursorTracking implementation
    
    unowned let sourceMenuItem: OBWFilteringMenuItem
    
    var sourceLine: NSRect = NSZeroRect {
        
        didSet {
            
            self.recalculateLimits()
            self.resetWaypoints()
            
            OBWFilteringMenuCursorTracking.debugWindow?.trackingView.needsDisplay = true
            OBWFilteringMenuCursorTracking.debugWindow?.display()
        }
    }
    
    /*==========================================================================*/
    class func hideDebugWindow() {
        OBWFilteringMenuCursorTracking.debugWindow?.orderOut( nil )
    }
    
    /*==========================================================================*/
    func isCursorProgressingTowardSubmenu( event: NSEvent ) -> Bool {
        
        if let eventLocation = event.obw_locationInScreen {
            
            if self.applyLimits {
                
                let topLimit = ( self.topSlope * eventLocation.x ) + self.topOffset
                let bottomLimit = ( self.bottomSlope * eventLocation.x ) + self.bottomOffset
                
                if eventLocation.y < bottomLimit || eventLocation.y > topLimit {
                    return false
                }
                
                if !self.isCursorMovingFastEnough( event.timestamp, locationInScreen: eventLocation ) {
                    return false
                }
            }
            
            self.lastMouseTimestamp = event.timestamp
        }
        else if let lastMouseTimestamp = self.lastMouseTimestamp {
            
            if event.timestamp - lastMouseTimestamp > OBWFilteringMenuCursorTracking.trackingInterval {
                return false
            }
        }
        
        return true
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuCursorTracking private
    
    private static let trackingInterval = 0.10
    private static let minimumSpeed = 10.0
    
    private let destinationArea: NSRect
    
    private var applyLimits = false
    
    private var lastMouseTimestamp: NSTimeInterval? = nil
    
    private let cursorWaypoints: [OBWFilteringMenuCursorTrackingWaypoint] =
        (1...20).map({ _ in OBWFilteringMenuCursorTrackingWaypoint() })
    
    
    private var topSlope: CGFloat = 0.0
    private var topOffset: CGFloat = 0.0
    private var bottomSlope: CGFloat = 0.0
    private var bottomOffset: CGFloat = 0.0
    private var minimumDrawX: CGFloat = 0.0
    private var maximumDrawX: CGFloat = 0.0
    
    private static let debugWindow: OBWFilteringMenuCursorTrackingDebugWindow? = {
        #if DEBUG_CURSOR_TRACKING
            return OBWFilteringMenuCursorTrackingDebugWindow()
        #else
            return nil
        #endif
    }()

    
    /*==========================================================================*/
    private func recalculateLimits() {
        
        let sourceLine = self.sourceLine
        let destinationArea = self.destinationArea
        
        let sourcePadding = NSSize( width: 0.0, height: 6.0 )
        let destinationPadding = NSSize( width: 0.0, height: 40.0 )
        
        let leftEdge: NSRect
        let rightEdge: NSRect
        
        let minimumDrawX: CGFloat
        let maximumDrawX: CGFloat
        
        if sourceLine.origin.x < destinationArea.origin.x {
            
            leftEdge = NSRect(
                x: sourceLine.origin.x - sourcePadding.width,
                y: sourceLine.origin.y - sourcePadding.height,
                width: 0.0,
                height: sourceLine.size.height + ( 2.0 * sourcePadding.height )
            )
            
            rightEdge = NSRect(
                x: destinationArea.origin.x - destinationPadding.width,
                y: destinationArea.origin.y - destinationPadding.height,
                width: 0.0,
                height: destinationArea.size.height + ( 2.0 * destinationPadding.height )
            )
            
            minimumDrawX = sourceLine.origin.x
            maximumDrawX = destinationArea.origin.x + destinationArea.size.width
        }
        else if sourceLine.origin.x > destinationArea.origin.x + destinationArea.size.width {
            
            leftEdge = NSRect(
                x: destinationArea.origin.x + destinationArea.size.width - destinationPadding.width,
                y: destinationArea.origin.y - destinationPadding.height,
                width: 0.0,
                height: destinationArea.size.height + ( 2.0 * destinationPadding.height )
            )
            
            rightEdge = NSRect(
                x: sourceLine.origin.x + sourcePadding.width,
                y: sourceLine.origin.y - sourcePadding.height,
                width: 0.0,
                height: sourceLine.size.height + ( 2.0 * sourcePadding.height )
            )
            
            minimumDrawX = destinationArea.origin.x;
            maximumDrawX = sourceLine.origin.x
        }
        else {
            
            self.applyLimits = false
            return
        }
        
        let run = rightEdge.origin.x - leftEdge.origin.x
        guard run != 0.0 else { return }
        
        let topRise = rightEdge.maxY - leftEdge.maxY
        self.topSlope = topRise / run
        self.topOffset = leftEdge.maxY - ( topSlope * leftEdge.origin.x )
        
        let bottomRise = rightEdge.origin.y - leftEdge.origin.y
        self.bottomSlope = bottomRise / run
        self.bottomOffset = leftEdge.origin.y - ( bottomSlope * leftEdge.origin.x )
        
        self.minimumDrawX = minimumDrawX
        self.maximumDrawX = maximumDrawX
        self.applyLimits = true
        
        OBWFilteringMenuCursorTracking.debugWindow?.trackingView.needsDisplay = true
        OBWFilteringMenuCursorTracking.debugWindow?.display()
    }
    
    /*==========================================================================*/
    private func resetWaypoints() {
        
        for waypoint in self.cursorWaypoints {
            waypoint.timestamp = nil
        }
    }
    
    /*==========================================================================*/
    private func isCursorMovingFastEnough( timestamp: NSTimeInterval, locationInScreen: NSPoint ) -> Bool {
        
        let waypoints = self.cursorWaypoints
        var oldestIndex = waypoints.startIndex
        
        let firstIndex = waypoints.startIndex.successor()
        let lastIndex = waypoints.endIndex.predecessor()
        
        for index in (firstIndex...lastIndex).reverse() {
            
            let newTimestamp = waypoints[index - 1].timestamp
            let newLocation = waypoints[index - 1].locationInScreen
            
            let oldTimestamp = waypoints[index].timestamp
            
            waypoints[index].timestamp = newTimestamp
            waypoints[index].locationInScreen = newLocation
            
            if oldTimestamp == nil && newTimestamp != nil {
                oldestIndex = index
            }
        }
        
        waypoints.first!.timestamp = timestamp
        waypoints.first!.locationInScreen = locationInScreen
        
        if oldestIndex == waypoints.startIndex {
            return true
        }
        
        let distanceX = waypoints[oldestIndex].locationInScreen.x - waypoints.first!.locationInScreen.x
        let distanceY = waypoints[oldestIndex].locationInScreen.y - waypoints.first!.locationInScreen.y
        
        let distance = Double( abs( distanceX ) + abs( distanceY ) )
        let time = timestamp - waypoints[oldestIndex].timestamp!
        let speed = distance / time
        
        return speed >= OBWFilteringMenuCursorTracking.minimumSpeed
    }
    
}

/*==========================================================================*/
// MARK: -

private class OBWFilteringMenuCursorTrackingWaypoint {
    var timestamp: NSTimeInterval? = nil
    var locationInScreen: NSPoint = NSZeroPoint
}

/*==========================================================================*/
// MARK: -

private class OBWFilteringMenuCursorTrackingDebugView: NSView {
    
    weak var cursorTracking: OBWFilteringMenuCursorTracking? = nil
    
    override func drawRect( dirtyRect: NSRect ) {
        
        let bounds = self.bounds
        
        NSColor.clearColor().set()
        NSRectFill( bounds )
        
        guard let cursorTracking = self.cursorTracking else { return }
        
        let topLeft = NSPoint(
            x: cursorTracking.minimumDrawX,
            y: ( cursorTracking.topSlope * cursorTracking.minimumDrawX ) + cursorTracking.topOffset
        )
        
        let topRight = NSPoint(
            x: cursorTracking.maximumDrawX,
            y: ( cursorTracking.topSlope * cursorTracking.maximumDrawX ) + cursorTracking.topOffset
        )
        
        let bottomLeft = NSPoint(
            x: cursorTracking.minimumDrawX,
            y: ( cursorTracking.bottomSlope * cursorTracking.minimumDrawX ) + cursorTracking.bottomOffset
        )
        
        let bottomRight = NSPoint(
            x: cursorTracking.maximumDrawX,
            y: ( cursorTracking.bottomSlope * cursorTracking.maximumDrawX ) + cursorTracking.bottomOffset
        )
        
        NSColor( deviceRed: 1.0, green: 0.0, blue: 0.0, alpha: 0.15 ).set()
        
        let path = NSBezierPath()
        path.moveToPoint( topRight )
        path.lineToPoint( topLeft )
        path.lineToPoint( bottomLeft )
        path.lineToPoint( bottomRight )
        path.closePath()
        path.fill()
        
        NSColor( deviceRed: 1.0, green: 0.0, blue: 0.0, alpha: 0.5 ).set()
        path.stroke()
    }
    
}

/*==========================================================================*/
// MARK: -

private class OBWFilteringMenuCursorTrackingDebugWindow: NSWindow {
    
    unowned let trackingView: OBWFilteringMenuCursorTrackingDebugView
    
    init() {
        
        let screenFrame = NSScreen.screens()?.first?.frame ?? NSZeroRect
        
        let trackingView = OBWFilteringMenuCursorTrackingDebugView( frame: screenFrame )
        self.trackingView = trackingView
        
        super.init( contentRect: screenFrame, styleMask: NSBorderlessWindowMask, backing: .Buffered, defer: false )
        
        self.level = CGWindowLevelForKey( .ScreenSaverWindowLevelKey ) - 10
        self.opaque = false
        self.backgroundColor = NSColor.clearColor()
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.acceptsMouseMovedEvents = false
        self.releasedWhenClosed = false
        self.animationBehavior = .None
        
        self.contentView?.addSubview( trackingView )
    }
    
}
