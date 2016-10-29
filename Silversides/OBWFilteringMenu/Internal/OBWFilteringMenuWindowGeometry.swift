/*===========================================================================
 OBWFilteringMenuWindowGeometry.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/
// MARK: -

class OBWFilteringMenuWindowGeometry {
    
    /*==========================================================================*/
    init( window: OBWFilteringMenuWindow, constrainToScreen: Bool = true ) {
        
        let screenFrame = window.screen?.frame ?? NSZeroRect
        
        let menuView = window.menuView
        
        self.window = window
        self.frame = window.frame
        self.initialBounds = menuView.menuItemBounds
        
        let totalMenuItemSize = menuView.totalMenuItemSize
        self.totalMenuItemSize = totalMenuItemSize
        
        let windowScreenLimits = screenFrame + OBWFilteringMenuWindowGeometry.screenMargins
        let interiorScreenLimits = windowScreenLimits + OBWFilteringMenuWindow.interiorMargins
        let menuItemScreenLimits = interiorScreenLimits + menuView.outerMenuMargins
        
        let finalSize = NSSize(
            width: min( totalMenuItemSize.width, menuItemScreenLimits.size.width ),
            height: min( totalMenuItemSize.height, menuItemScreenLimits.size.height )
        )
        
        self.finalBounds = NSRect( size: finalSize )
        
        if constrainToScreen {
            self.constrainGeometryToScreen( allowWindowToGrowUpward: true )
        }
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuWindowGeometry internal
    
    /*==========================================================================*/
    func updateGeometryToDisplayMenuLocation( locationInMenu: NSPoint, atScreenLocation locationInScreen: NSPoint, allowWindowToGrowUpward: Bool ) -> Bool {
        
        guard NSScreen.screenContainingLocation( locationInScreen ) != nil else { return false }
        
        let menuView = self.window.menuView
        let totalMenuItemSize = menuView.totalMenuItemSize
        self.totalMenuItemSize = totalMenuItemSize
        
        let menuFrameInScreen = NSRect(
            x: locationInScreen.x - locationInMenu.x,
            y: locationInScreen.y - locationInMenu.y,
            size: totalMenuItemSize
        )
        
        let interiorFrameInScreen = menuFrameInScreen - menuView.outerMenuMargins
        
        var windowFrameInScreen = interiorFrameInScreen - OBWFilteringMenuWindow.interiorMargins
        windowFrameInScreen.size = max( windowFrameInScreen.size, OBWFilteringMenuWindow.minimumFrameSize )
        
        self.frame = windowFrameInScreen
        
        let menuItemBounds = NSRect( size: totalMenuItemSize )
        self.initialBounds = menuItemBounds
        self.finalBounds = menuItemBounds
        
        self.constrainGeometryToScreen( allowWindowToGrowUpward: allowWindowToGrowUpward )
        
        return true
    }
    
    /*==========================================================================*/
    func updateGeometryToDisplayMenuLocation( locationInMenu: NSPoint, adjacentToScreenArea areaInScreen: NSRect, preferredAlignment: OBWFilteringMenuAlignment ) -> OBWFilteringMenuAlignment {
        
        let rightAlignmentLocation: NSPoint
        
        if areaInScreen.height < self.frame.size.height {
            rightAlignmentLocation = NSPoint( x: areaInScreen.maxX + 1.0, y: areaInScreen.maxY )
        }
        else {
            rightAlignmentLocation = NSPoint( x: areaInScreen.maxX + 1.0, y: areaInScreen.midY )
        }
        
        var rightGeometry: OBWFilteringMenuWindowGeometry? = OBWFilteringMenuWindowGeometry( window: self.window )
        if let geometry = rightGeometry {
            
            if !geometry.updateGeometryToDisplayMenuLocation( locationInMenu, atScreenLocation: rightAlignmentLocation, allowWindowToGrowUpward: true ) {
                rightGeometry = nil
            }
        }
        
        let leftAlignmentLocation: NSPoint
        
        if areaInScreen.height < self.frame.size.height {
            
            leftAlignmentLocation = NSPoint(
                x: areaInScreen.origin.x - self.frame.size.width - 1.0,
                y: areaInScreen.maxY
            )
        }
        else {
            
            leftAlignmentLocation = NSPoint(
                x: areaInScreen.origin.x - self.frame.size.width - 1.0,
                y: areaInScreen.midY
            )
        }
    
        var leftGeometry: OBWFilteringMenuWindowGeometry? = OBWFilteringMenuWindowGeometry( window: self.window )
        if let geometry = leftGeometry {
            
            if !geometry.updateGeometryToDisplayMenuLocation( locationInMenu, atScreenLocation: leftAlignmentLocation, allowWindowToGrowUpward: true ) {
                leftGeometry = nil
            }
        }
        
        guard rightGeometry != nil || leftGeometry != nil else { return preferredAlignment }
        
        let windowGeometry: OBWFilteringMenuWindowGeometry
        let alignment: OBWFilteringMenuAlignment
        
        if leftGeometry == nil {
            windowGeometry = rightGeometry!
            alignment = .Right
        }
        else if rightGeometry == nil {
            windowGeometry = leftGeometry!
            alignment = .Left
        }
        else {
            
            switch preferredAlignment {
                
            case .Left:
                
                if leftGeometry!.frame.origin.x != leftAlignmentLocation.x && rightGeometry!.frame.origin.x == rightAlignmentLocation.x {
                    windowGeometry = rightGeometry!
                    alignment = .Right
                }
                else {
                    windowGeometry = leftGeometry!
                    alignment = .Left
                }
                
            case .Right:
                
                if rightGeometry!.frame.origin.x != rightAlignmentLocation.x && leftGeometry!.frame.origin.x == leftAlignmentLocation.x {
                    windowGeometry = leftGeometry!
                    alignment = .Left
                }
                else {
                    windowGeometry = rightGeometry!
                    alignment = .Right
                }
            }
        }
        
        self.frame = windowGeometry.frame
        self.totalMenuItemSize = windowGeometry.totalMenuItemSize
        self.initialBounds = windowGeometry.initialBounds
        self.finalBounds = windowGeometry.finalBounds
        
        return alignment
    }
    
    /*==========================================================================*/
    func updateGeometryWithResizedMenu() -> Bool {
        
        let window = self.window
        let menuView = window.menuView
        let outerMenuMargins = menuView.outerMenuMargins
        let interiorMargins = OBWFilteringMenuWindow.interiorMargins
        
        let totalMenuItemSize = menuView.totalMenuItemSize
        self.totalMenuItemSize = totalMenuItemSize
        
        var windowFrameInScreen = self.frame
        var interiorFrameInScreen = windowFrameInScreen + interiorMargins
        var menuFrameInScreen = interiorFrameInScreen + outerMenuMargins
        
        menuFrameInScreen.origin.y = menuFrameInScreen.maxY - totalMenuItemSize.height
        menuFrameInScreen.size.height = totalMenuItemSize.height
        menuFrameInScreen.size.width = max( menuFrameInScreen.size.width, totalMenuItemSize.width )
        
        interiorFrameInScreen = menuFrameInScreen - outerMenuMargins
        
        if let screenAnchor = window.screenAnchor {
            
            interiorFrameInScreen = OBWFilteringMenuWindowGeometry.constrainFrame( interiorFrameInScreen, toAnchorRect: screenAnchor )
            
            if totalMenuItemSize.height == 0.0 {
                interiorFrameInScreen.origin.y = screenAnchor.maxY - interiorFrameInScreen.size.height
            }
        }
        
        windowFrameInScreen = interiorFrameInScreen - interiorMargins
        windowFrameInScreen.size = max( windowFrameInScreen.size, OBWFilteringMenuWindow.minimumFrameSize )
        self.frame = windowFrameInScreen
        
        self.initialBounds = NSRect( size: totalMenuItemSize )
        self.finalBounds = NSRect( size: totalMenuItemSize )
        
        self.constrainGeometryToScreen( allowWindowToGrowUpward: false )
        
        return true
    }
    
    /*==========================================================================*/
    func updateGeometryToDisplayMenuItemBounds( menuItemBounds: NSRect ) -> Bool {
        
        let window = self.window
        
        guard window.screen != nil else { return false }
        let menuView = window.menuView
        
        var initialBounds = self.initialBounds
        let interiorMargins = OBWFilteringMenuWindow.interiorMargins
        let outerMenuMargins = menuView.outerMenuMargins
        
        var windowFrameInScreen = self.frame
        var interiorFrameInScreen = windowFrameInScreen + interiorMargins
        var menuFrameInScreen = interiorFrameInScreen + outerMenuMargins
        
        if menuFrameInScreen.size.height == menuItemBounds.size.height {
            initialBounds.origin.y = menuItemBounds.origin.y
            self.initialBounds = initialBounds
            return true
        }
        
        menuFrameInScreen.origin.y += ( menuFrameInScreen.size.height - menuItemBounds.size.height )
        menuFrameInScreen.size.height = menuItemBounds.size.height
        
        interiorFrameInScreen = menuFrameInScreen - outerMenuMargins
        windowFrameInScreen = interiorFrameInScreen - interiorMargins
        windowFrameInScreen.size = max( windowFrameInScreen.size, OBWFilteringMenuWindow.minimumFrameSize )
        self.frame = windowFrameInScreen
        
        self.initialBounds = menuItemBounds
        self.finalBounds = NSRect( size: menuView.totalMenuItemSize )
        
        self.constrainGeometryToScreen( allowWindowToGrowUpward: true )
        
        return true
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuWindowGeometry private
    
    unowned private let window: OBWFilteringMenuWindow
    var frame: NSRect
    var totalMenuItemSize: NSSize
    var initialBounds: NSRect
    var finalBounds: NSRect
    
    static let screenMargins = NSEdgeInsets( top: 6.0, left: 6.0, bottom: 6.0, right: 6.0 )
    
    /*==========================================================================*/
    private func constrainGeometryToScreen( allowWindowToGrowUpward allowWindowToGrowUpward: Bool ) {
        
        guard let screen = self.window.screen else { return }
        let menuView = window.menuView
        
        var windowFrame = self.frame
        let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
        
        if windowFrame.size.width >= screenLimits.size.width {
            windowFrame.origin.x = screenLimits.origin.x
            windowFrame.size.width = screenLimits.size.width
        }
        else if windowFrame.origin.x < screenLimits.origin.x {
            windowFrame.origin.x = screenLimits.origin.x
        }
        else if windowFrame.maxX > screenLimits.maxX {
            windowFrame.origin.x = screenLimits.maxX - windowFrame.size.width
        }
        
        let outerMenuMargins = menuView.outerMenuMargins
        let interiorMargins = OBWFilteringMenuWindow.interiorMargins
        
        let minimumWindowHeightAtBottomOfScreen = min( menuView.minimumHeightAtTop + interiorMargins.height + outerMenuMargins.height, screenLimits.size.height )
        let minimumWindowHeightAtTopOfScreen = min( menuView.minimumHeightAtBottom + interiorMargins.height + outerMenuMargins.height, screenLimits.size.height )
        
        if windowFrame.origin.y > screenLimits.maxY - minimumWindowHeightAtTopOfScreen {
            windowFrame.origin.y = screenLimits.maxY - minimumWindowHeightAtTopOfScreen
        }
        if windowFrame.maxY < screenLimits.origin.y + minimumWindowHeightAtBottomOfScreen {
            windowFrame.origin.y = screenLimits.origin.y + minimumWindowHeightAtBottomOfScreen - windowFrame.size.height
        }
        
        if ( windowFrame.origin.y < screenLimits.origin.y ) && allowWindowToGrowUpward {
            
            let distanceFreeAtTopOfScreen = screenLimits.maxY - windowFrame.maxY
            
            if distanceFreeAtTopOfScreen > 0.0 {
                windowFrame.origin.y += min( screenLimits.origin.y - windowFrame.origin.y, distanceFreeAtTopOfScreen )
            }
        }
        
        let distanceToTrimFromBottomOfMenu: CGFloat
        
        if windowFrame.origin.y < screenLimits.origin.y {
            
            distanceToTrimFromBottomOfMenu = screenLimits.origin.y - windowFrame.origin.y
            windowFrame.size.height -= distanceToTrimFromBottomOfMenu
            windowFrame.origin.y = screenLimits.origin.y
        }
        else {
            distanceToTrimFromBottomOfMenu = 0.0
        }
        
        let distanceToTrimFromTopOfMenu: CGFloat
        
        if windowFrame.maxY > screenLimits.maxY {
            
            distanceToTrimFromTopOfMenu = windowFrame.maxY - screenLimits.maxY
            windowFrame.size.height -= distanceToTrimFromTopOfMenu
        }
        else {
            distanceToTrimFromTopOfMenu = 0.0
        }
        
        self.frame = windowFrame
        
        if distanceToTrimFromBottomOfMenu > 0.0 || distanceToTrimFromTopOfMenu > 0.0 {
            
            var initialBounds = self.initialBounds
            initialBounds.origin.y += distanceToTrimFromBottomOfMenu
            initialBounds.origin.y = max( initialBounds.origin.y, 0.0 )
            initialBounds.size.height -= ( distanceToTrimFromBottomOfMenu + distanceToTrimFromTopOfMenu )
            self.initialBounds = initialBounds
        }
        
        let interiorScreenLimits = screenLimits + interiorMargins
        let menuScreenLimits = interiorScreenLimits + outerMenuMargins
        
        var finalBounds = self.finalBounds
        finalBounds.size.width = min( finalBounds.size.width, menuScreenLimits.size.width )
        finalBounds.size.height = min( finalBounds.size.height, menuScreenLimits.size.height )
        self.finalBounds = finalBounds
    }
    
    /*==========================================================================*/
    private class func constrainFrame( frame: NSRect, toAnchorRect anchor: NSRect ) -> NSRect {
        
        let anchorBottom = anchor.origin.y
        let anchorTop = anchor.origin.y + anchor.size.height
        
        let frameBottom = frame.origin.y
        var frameTop = frame.origin.y + frame.size.height
        
        if ( frameBottom <= anchorBottom ) && ( frameTop >= anchorTop ) {
            return frame
        }
        
        var constrainedFrame = frame
        
        if frameBottom > anchorBottom {
            constrainedFrame.origin.y = anchorBottom
            frameTop = constrainedFrame.origin.y + constrainedFrame.size.height
        }
        
        if frameTop < anchorTop {
            constrainedFrame.origin.y = anchorTop - constrainedFrame.size.height
        }
        
        return constrainedFrame
    }
    
}
