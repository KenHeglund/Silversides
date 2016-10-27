/*===========================================================================
 OBWFilteringMenuItemScrollView.swift
 Silversides
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

private class OBWColorView: NSView {
    
    var color: NSColor? = nil
    
    override func drawRect( dirtyRect: NSRect ) {
        guard let color = self.color else { return }
        color.set()
        NSRectFillUsingOperation( dirtyRect, .SourceOver )
    }
}

/*==========================================================================*/
// MARK: -

class OBWFilteringMenuItemScrollView: NSView {
    
    /*==========================================================================*/
    init( menu: OBWFilteringMenu ) {
        
        let initialFrame = NSRect(
            width: OBWFilteringMenuItemScrollView.minimumItemWidth,
            height: 0.0
        )
        
        self.filteringMenu = menu
        
        let itemParentView: NSView
        #if DEBUG_MENU_TINTING
            let colorParentView = OBWColorView( frame: NSZeroRect )
            colorParentView.color = NSColor( deviceRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.1 )
            itemParentView = colorParentView
        #else
            itemParentView = NSView( frame: NSZeroRect )
        #endif
        itemParentView.autoresizesSubviews = true
        self.itemParentView = itemParentView
        
        let itemClipView = NSClipView()
        self.itemClipView = itemClipView
        
        let upArrowView = NSImageView()
        self.upArrowView = upArrowView
        
        let downArrowView = NSImageView()
        self.downArrowView = downArrowView
        
        super.init( frame: initialFrame )
        
        self.buildItemViews()
        self.repositionItemViews()
        
        let itemParentViewFrame = itemParentView.frame
        
        itemClipView.frame = itemParentViewFrame
        
        let upArrowFrame = NSRect(
            x: itemParentViewFrame.origin.x + floor( ( itemParentViewFrame.size.width - OBWFilteringMenuItemScrollView.arrowSize.width ) / 2.0 ),
            y: itemParentViewFrame.maxY - OBWFilteringMenuItemScrollView.arrowSize.height,
            size: OBWFilteringMenuItemScrollView.arrowSize
        )
        
        upArrowView.frame = upArrowFrame
        upArrowView.imageScaling = .ScaleProportionallyDown
        upArrowView.imageAlignment = .AlignCenter
        upArrowView.autoresizingMask = [ .ViewMinYMargin, .ViewMinXMargin, .ViewMaxXMargin ]
        upArrowView.image = OBWFilteringMenuArrows.upArrow
        upArrowView.hidden = true
        
        let downArrowFrame = NSRect(
            x: itemParentViewFrame.origin.x + floor( ( itemParentViewFrame.size.width - OBWFilteringMenuItemScrollView.arrowSize.width ) / 2.0 ),
            y: 0.0,
            size: OBWFilteringMenuItemScrollView.arrowSize
        )
        
        downArrowView.frame = downArrowFrame
        downArrowView.imageScaling = .ScaleProportionallyDown
        downArrowView.imageAlignment = .AlignCenter
        downArrowView.autoresizingMask = [ .ViewMaxYMargin, .ViewMinXMargin, .ViewMaxXMargin ]
        downArrowView.image = OBWFilteringMenuArrows.downArrow
        downArrowView.hidden = true
        
        itemClipView.drawsBackground = false
        itemClipView.autoresizingMask = [ .ViewWidthSizable, .ViewHeightSizable ]
        itemClipView.addSubview( itemParentView )
        
        self.setFrameSize( itemParentViewFrame.size )
        self.addSubview( itemClipView )
        self.addSubview( upArrowView )
        self.addSubview( downArrowView )
        
        self.autoresizingMask = [ .ViewWidthSizable, .ViewHeightSizable ]
        self.autoresizesSubviews = true
    }
    
    /*==========================================================================*/
    required init?( coder: NSCoder ) {
        fatalError( "init(coder:) has not been implemented" )
    }
    
    /*==========================================================================*/
    // MARK: - NSView overrides
    
    /*==========================================================================*/
    override func resizeSubviewsWithOldSize( oldSize: NSSize ) {
        
        super.resizeSubviewsWithOldSize( oldSize )
        
        let heightDelta = self.frame.size.height - oldSize.height
        let itemClipView = self.itemClipView
        
        let newClipBoundsOrigin = NSPoint(
            x: 0.0,
            y: itemClipView.bounds.origin.y - heightDelta
        )
        
        itemClipView.setBoundsOrigin( newClipBoundsOrigin )
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuItemScrollView implementation
    
    /*==========================================================================*/
    var minimumHeightAtTop: CGFloat {
        guard let itemView = allItemViews.first else { return 0.0 }
        return self.minimumHeightForView( itemView )
    }
    
    /*==========================================================================*/
    var minimumHeightAtBottom: CGFloat {
        guard let itemView = allItemViews.last else { return 0.0 }
        return self.minimumHeightForView( itemView )
    }
    
    /*==========================================================================*/
    var totalMenuItemSize: NSSize {
        return self.itemParentView.frame.size
    }
    
    /*==========================================================================*/
    var menuItemBounds: NSRect {
        return self.convertRect( self.bounds, toView: self.itemClipView )
    }
    
    /*==========================================================================*/
    func menuItemAtLocation( locationInView: NSPoint ) -> OBWFilteringMenuItem? {
        
        let itemClipView = self.itemClipView
        let locationInClipView = itemClipView.convertPoint( locationInView, fromView: self )
        guard NSPointInRect( locationInClipView, itemClipView.bounds ) else { return nil }
        
        let itemParentView = self.itemParentView
        let locationInParentView = itemParentView.convertPoint( locationInView, fromView: self )
        
        for subview in itemParentView.subviews {
            
            guard let itemView = subview as? OBWFilteringMenuItemView else { continue }
            
            guard !itemView.hidden else { continue }
            guard NSPointInRect( locationInParentView, itemView.frame ) else { continue }
            
            let menuItem = itemView.menuItem
            
            if !menuItem.enabled { return nil }
            if !menuItem.canHighlight { return nil }
            
            return menuItem
        }
        
        return nil
    }
    
    /*==========================================================================*/
    func menuPartAtLocation( locationInView: NSPoint ) -> OBWFilteringMenuPart {
        
        let itemClipFrame = self.itemClipView.frame
        
        if locationInView.x < itemClipFrame.origin.x || locationInView.x >= itemClipFrame.maxX {
            return .None
        }
        else if locationInView.y < itemClipFrame.origin.y {
            return self.downArrowView.hidden ? .None : .Down
        }
        else if locationInView.y >= itemClipFrame.maxY {
            return self.upArrowView.hidden ? .None : .Up
        }
        
        return .Item
    }
    
    /*==========================================================================*/
    func viewForMenuItem( menuItem: OBWFilteringMenuItem ) -> OBWFilteringMenuItemView? {
        
        guard !menuItem.isSeparatorItem else { return nil }
        
        for itemView in self.allItemViews {
            
            if itemView.menuItem === menuItem {
                return itemView
            }
        }
        
        return nil
    }
    
    /*==========================================================================*/
    func nextViewAfterItem( menuItem: OBWFilteringMenuItem? ) -> OBWFilteringMenuItemView? {
        return self.nextViewAfterItem( menuItem, inViews: self.allItemViews )
    }
    
    /*==========================================================================*/
    func previousViewBeforeItem( menuItem: OBWFilteringMenuItem? ) -> OBWFilteringMenuItemView? {
        return self.nextViewAfterItem( menuItem, inViews: self.allItemViews.reverse() )
    }
    
    /*==========================================================================*/
    func scrollItemToVisible( menuItem: OBWFilteringMenuItem ) {
        guard let itemView = self.viewForMenuItem( menuItem ) else { return }
        self.scrollItemViewIntoFrame( itemView )
    }
    
    /*==========================================================================*/
    func scrollItemsDownWithAcceleration( acceleration: Double ) -> Bool {
        
        let itemClipView = self.itemClipView
        let itemClipViewBounds = itemClipView.bounds
        
        let itemParentView = self.itemParentView
        let itemParentFrame = itemParentView.frame
        let averageItemHeight = itemParentFrame.size.height / CGFloat(itemParentView.subviews.count)
        let scrollDelta = floor( averageItemHeight * CGFloat(acceleration) )
        
        let hitPoint = NSPoint(
            x: itemClipViewBounds.origin.x,
            y: min( itemClipViewBounds.maxY + scrollDelta, itemParentFrame.size.height )
        )
        
        guard let itemView = self.menuItemViewAtLocation( hitPoint ) ?? self.nextViewAfterItem( nil ) else {
            return self.upArrowView.hidden
        }
        
        self.scrollItemViewIntoFrame( itemView )
        
        return self.upArrowView.hidden
    }
    
    /*==========================================================================*/
    func scrollItemsUpWithAcceleration( acceleration: Double ) -> Bool {
        
        let itemClipView = self.itemClipView
        let itemClipViewBounds = itemClipView.bounds
        
        let itemParentView = self.itemParentView
        let averageItemHeight = itemParentView.frame.size.height / CGFloat(itemParentView.subviews.count)
        let scrollDelta = floor( averageItemHeight * CGFloat(acceleration) )
        
        let hitPoint = NSPoint(
            x: itemClipViewBounds.origin.x,
            y: max( itemClipViewBounds.origin.y - scrollDelta, 0.0 )
        )
        
        guard let itemView = self.menuItemViewAtLocation( hitPoint ) ?? self.previousViewBeforeItem( nil ) else {
            return self.downArrowView.hidden
        }
        
        self.scrollItemViewIntoFrame( itemView )
        
        return self.downArrowView.hidden
    }
    
    /*==========================================================================*/
    func scrollItemsDownOnePage() -> OBWFilteringMenuItemView? {
        
        let itemClipView = self.itemClipView
        let itemClipViewBounds = itemClipView.bounds
        
        guard let topItemView = self.firstFullyVisibleMenuItemView() else { return nil }
        
        let hitPoint = NSPoint(
            x: itemClipViewBounds.minX,
            y: topItemView.frame.maxY + ( itemClipViewBounds.size.height - 1.0 )
        )
        
        guard let itemView = self.menuItemViewAtLocation( hitPoint ) ?? self.nextViewAfterItem( nil ) else { return nil }
        
        self.scrollItemViewIntoFrame( itemView )
        
        return itemView
    }
    
    /*==========================================================================*/
    func scrollItemsUpOnePage() -> OBWFilteringMenuItemView? {
        
        let itemClipView = self.itemClipView
        let itemClipViewBounds = itemClipView.bounds
        
        guard let bottomItemView = self.lastFullyVisibleMenuItemView() else { return nil }
        
        let hitPoint = NSPoint(
            x: itemClipViewBounds.minX,
            y: bottomItemView.frame.minY - ( itemClipViewBounds.size.height - 1.0 )
        )
        
        guard let itemView = self.menuItemViewAtLocation( hitPoint ) ?? self.previousViewBeforeItem( nil ) else { return nil }
        
        self.scrollItemViewIntoFrame( itemView )
        
        return itemView
    }
    
    /*==========================================================================*/
    func setMenuItemBoundsOriginY( boundsOriginY: CGFloat ) {
        
        let arrowAreaHeight = OBWFilteringMenuItemScrollView.arrowEdgeMargin + OBWFilteringMenuItemScrollView.arrowContentMargin + OBWFilteringMenuItemScrollView.arrowSize.height
        
        let itemParentView = self.itemParentView
        let itemParentFrame = itemParentView.frame
        
        let scrollViewBounds = self.bounds
        var itemClipFrame = scrollViewBounds
        
        var itemClipBounds = NSRect(
            x: 0.0,
            y: boundsOriginY,
            width: itemClipFrame.size.width,
            height: itemClipFrame.size.height
        )
        
        if boundsOriginY > 0.0 {
            
            itemClipFrame.origin.y += arrowAreaHeight
            itemClipFrame.size.height -= arrowAreaHeight
            
            itemClipBounds.origin.y += arrowAreaHeight
            itemClipBounds.size.height -= arrowAreaHeight
            
            self.downArrowView.hidden = false
        }
        else {
            self.downArrowView.hidden = true
        }
        
        if itemParentFrame.size.height > itemClipBounds.maxY {
            
            itemClipFrame.size.height -= arrowAreaHeight
            itemClipBounds.size.height -= arrowAreaHeight
            
            self.upArrowView.hidden = false
        }
        else {
            self.upArrowView.hidden = true
        }
        
        let itemClipView = self.itemClipView
        itemClipView.frame = itemClipFrame
        itemClipView.scrollToPoint( itemClipBounds.origin )
    }
    
    /*==========================================================================*/
    func applyFilterResults( filterResults: [OBWFilteringMenuItemFilterStatus] ) -> Bool {
        
        let itemViewArray = self.primaryItemViews
        
        for index in filterResults.startIndex ..< filterResults.endIndex {
            
            let status = filterResults[index]
            let itemView = itemViewArray[index]
            
            guard status.menuItem === itemView.menuItem else { continue }
            
            itemView.applyFilterStatus( status )
        }
        
        return self.repositionItemViews( modifierFlags: self.currentModifierFlags )
    }
    
    /*==========================================================================*/
    func applyModifierFlags( modifierFlags: NSEventModifierFlags ) -> Bool {
        
        if modifierFlags == self.currentModifierFlags { return false }
        
        self.currentModifierFlags = modifierFlags
        
        return self.repositionItemViews( modifierFlags: modifierFlags )
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuItemScrollView private
    
    private static let arrowEdgeMargin: CGFloat = 0.0
    private static let arrowContentMargin: CGFloat = 5.0
    private static let arrowSize = NSSize( width: 10.0, height: 9.0 )
    private static let minimumItemWidth: CGFloat = 100.0
    
    unowned private let filteringMenu: OBWFilteringMenu
    private var filteringMenuWindow: OBWFilteringMenuWindow? { return self.window as? OBWFilteringMenuWindow }
    unowned private let itemParentView: NSView
    unowned private let itemClipView: NSClipView
    unowned private let upArrowView: NSImageView
    unowned private let downArrowView: NSImageView
    private var primaryItemViews: [OBWFilteringMenuItemView] = []
    private var currentModifierFlags: NSEventModifierFlags = []
    
    /*==========================================================================*/
    private func buildItemViews() {
        
        let itemParentView = self.itemParentView
        assert( itemParentView.subviews.isEmpty )
        
        var primaryItemViews: [OBWFilteringMenuItemView] = []
        
        for menuItem in self.filteringMenu.itemArray {
            
            let itemView = OBWFilteringMenuItemView.viewWithMenuItem( menuItem )
            primaryItemViews.append( itemView )
            itemParentView.addSubview( itemView )
            
            guard let alternateViews = itemView.alternateViews else { continue }
            
            for (_,alternateItemView) in alternateViews {
                itemParentView.addSubview( alternateItemView )
            }
        }
        
        self.primaryItemViews = primaryItemViews
    }
    
    /*==========================================================================*/
    private func repositionItemViews( modifierFlags modifierFlags: NSEventModifierFlags = [] ) -> Bool {
        
        let itemParentView = self.itemParentView
        let itemParentBounds = itemParentView.bounds
        
        var itemViewOrigin = NSPoint( x: self.bounds.origin.x, y: 0.0 )
        var parentViewWidth = max( OBWFilteringMenuItemScrollView.minimumItemWidth, itemParentBounds.size.width )
        
        for primaryItemView in self.primaryItemViews.reverse() {
            
            let primaryMenuItem = primaryItemView.menuItem
            let primaryFilterStatus = primaryItemView.filterStatus
            
            let primaryViewVisible: Bool
            if primaryFilterStatus?.matchScore == 0 {
                primaryViewVisible = false
            }
            else if primaryMenuItem.visibleItemForModifierFlags( modifierFlags ) !== primaryMenuItem {
                primaryViewVisible = false
            }
            else {
                primaryViewVisible = true
            }
            
            let itemViewFrame = NSRect(
                origin: itemViewOrigin,
                width: itemParentBounds.size.width,
                height: primaryItemView.preferredSize.height
            )
            
            if primaryItemView.frame != itemViewFrame {
                
                primaryItemView.frame = itemViewFrame
                
                if primaryViewVisible {
                    NSAccessibilityPostNotification( primaryItemView, NSAccessibilityMovedNotification )
                }
            }
            
            if primaryViewVisible && primaryItemView.hidden {
                primaryItemView.hidden = false
                NSAccessibilityPostNotification( primaryItemView, NSAccessibilityCreatedNotification )
            }
            else if !primaryViewVisible && !primaryItemView.hidden {
                primaryItemView.hidden = true
                NSAccessibilityPostNotification( primaryItemView, NSAccessibilityUIElementDestroyedNotification )
            }
            
            var visibleItemView: OBWFilteringMenuItemView? = ( primaryViewVisible ? primaryItemView : nil )
            
            for ( _, alternateItemView ) in ( primaryItemView.alternateViews ?? [:] ) {
                
                let alternateMenuItem = alternateItemView.menuItem
                let alternateFilterStatus = alternateItemView.filterStatus
                
                let alternateViewVisible: Bool
                if alternateFilterStatus?.matchScore == 0 {
                    alternateViewVisible = false
                }
                else if alternateMenuItem.visibleItemForModifierFlags( modifierFlags ) !== alternateMenuItem {
                    alternateViewVisible = false
                }
                else {
                    alternateViewVisible = true
                }
                
                let alternateItemViewFrame = NSRect(
                    origin: itemViewOrigin,
                    width: itemParentBounds.size.width,
                    height: alternateItemView.preferredSize.height
                )
                
                if alternateItemView.frame != alternateItemViewFrame {
                    
                    alternateItemView.frame = alternateItemViewFrame
                    
                    if alternateViewVisible {
                        NSAccessibilityPostNotification( alternateItemView, NSAccessibilityMovedNotification )
                    }
                }
                
                if alternateViewVisible && alternateItemView.hidden {
                    alternateItemView.hidden = false
                    NSAccessibilityPostNotification( alternateItemView, NSAccessibilityCreatedNotification)
                }
                else if !alternateViewVisible && !alternateItemView.hidden {
                    alternateItemView.hidden = true
                    NSAccessibilityPostNotification( alternateItemView, NSAccessibilityUIElementDestroyedNotification )
                }
                
                if alternateViewVisible {
                    visibleItemView = alternateItemView
                }
            }
            
            if let visibleItemView = visibleItemView {
            
                itemViewOrigin.y += visibleItemView.frame.size.height
                
                let itemSize = OBWFilteringMenuItemView.preferredSizeForMenuItem( visibleItemView.menuItem )
                parentViewWidth = max( parentViewWidth, itemSize.width )
            }
        }
        
        let totalMenuItemSizeChanged = ( itemParentView.frame.size.height != itemViewOrigin.y )
        
        if totalMenuItemSizeChanged {
            
            let parentViewSize = NSSize( width: parentViewWidth, height: itemViewOrigin.y )
            itemParentView.setFrameSize( parentViewSize )
        }
        
        guard let highlightedItem = self.filteringMenu.highlightedItem else { return totalMenuItemSizeChanged }
        
        if self.viewForMenuItem( highlightedItem )?.hidden == true {
            self.filteringMenu.highlightedItem = nil
        }
        
        return totalMenuItemSizeChanged
    }
    
    /*==========================================================================*/
    private var allItemViews: [OBWFilteringMenuItemView] {
        return self.itemParentView.subviews as! [OBWFilteringMenuItemView]
    }
    
    /*==========================================================================*/
    private func minimumHeightForView( itemView: NSView ) -> CGFloat {
        
        let minimumHeight = itemView.frame.size.height
        
        if self.allItemViews.count == 1 {
            return minimumHeight
        }
        
        return minimumHeight + OBWFilteringMenuItemScrollView.arrowEdgeMargin + OBWFilteringMenuItemScrollView.arrowContentMargin + OBWFilteringMenuItemScrollView.arrowSize.height
    }
    
    /*==========================================================================*/
    private func nextViewAfterItem( menuItem: OBWFilteringMenuItem?, inViews itemViewArray: [OBWFilteringMenuItemView] ) -> OBWFilteringMenuItemView? {
        
        let accessibilityActive = self.filteringMenuWindow?.accessibilityActive ?? false
        
        var currentMenuItemView: OBWFilteringMenuItemView? = nil
        var useNextAvailable = ( menuItem == nil )
        
        for itemView in itemViewArray {
            
            let item = itemView.menuItem
            
            if item === menuItem {
                currentMenuItemView = itemView
                useNextAvailable = true
                continue
            }
            
            if !useNextAvailable { continue }
            if itemView.hidden { continue }
            if !item.enabled && !accessibilityActive { continue }
            if !item.canHighlight { continue }
            
            return itemView
        }
        
        return currentMenuItemView
    }
    
    /*==========================================================================*/
    private func nextViewAfterItemAtIndex( itemIndex: Int ) -> OBWFilteringMenuItemView {
        
        let itemViews = self.allItemViews
        let currentItemView = itemViews[itemIndex]
        
        guard let window = self.filteringMenuWindow else { return currentItemView }
        
        let accessibilityActive = window.accessibilityActive
        
        let startIndex = itemIndex + 1
        let range = startIndex ..< itemViews.endIndex
        for index in range {
            
            let itemView = itemViews[index]
            
            if itemView.hidden { continue }
            
            let item = itemView.menuItem
            
            if !item.enabled && !accessibilityActive { continue }
            if !item.canHighlight { continue }
            
            return itemView
        }
        
        return currentItemView
    }
    
    /*==========================================================================*/
    private func previousViewBeforeItemAtIndex( itemIndex: Int ) -> OBWFilteringMenuItemView {
        
        let itemViews = self.allItemViews
        let currentItemView = itemViews[itemIndex]
        
        guard let window = self.filteringMenuWindow else { return currentItemView }
        
        let accessibilityActive = window.accessibilityActive
        
        let endIndex = itemIndex
        let range = itemViews.startIndex ..< endIndex
        for index in range.reverse() {
            
            let itemView = itemViews[index]
            
            if itemView.hidden { continue }
            
            let item = itemView.menuItem
            
            if !item.enabled && !accessibilityActive { continue }
            if !item.canHighlight { continue }
            
            return itemView
        }
        
        return currentItemView
    }
    
    /*==========================================================================*/
    private func menuItemViewAtLocation( locationInItemClipView: NSPoint ) -> OBWFilteringMenuItemView? {
        
        for itemView in self.allItemViews {
            if itemView.hidden { continue }
            if NSPointInRect( locationInItemClipView, itemView.frame ) { return itemView }
        }
        
        return nil
    }
    
    /*==========================================================================*/
    private func firstFullyVisibleMenuItemView() -> OBWFilteringMenuItemView? {
        
        let itemClipViewBounds = self.itemClipView.bounds
        
        let topLeft = NSPoint(
            x: itemClipViewBounds.minX,
            y: itemClipViewBounds.maxY
        )
        
        guard let topMenuView = self.menuItemViewAtLocation( topLeft ) else { return nil }
        
        if topMenuView.frame.maxY <= itemClipViewBounds.maxY {
            return topMenuView
        }
        
        let testPoint = NSPoint(
            x: itemClipViewBounds.minX,
            y: itemClipViewBounds.maxY - topMenuView.frame.size.height
        )
        
        return self.menuItemViewAtLocation( testPoint )
    }
    
    /*==========================================================================*/
    private func lastFullyVisibleMenuItemView() -> OBWFilteringMenuItemView? {
        
        let itemClipViewBounds = self.itemClipView.bounds
        
        guard let bottomMenuView = self.menuItemViewAtLocation( itemClipViewBounds.origin ) else { return nil }
        
        if bottomMenuView.frame.minY >= itemClipViewBounds.minY {
            return bottomMenuView
        }
        
        let testPoint = NSPoint(
            x: itemClipViewBounds.minX,
            y: itemClipViewBounds.minY + bottomMenuView.frame.size.height
        )
        
        return self.menuItemViewAtLocation( testPoint )
    }
    
    /*==========================================================================*/
    private func scrollItemViewIntoFrame( itemView: OBWFilteringMenuItemView ) {
        
        let itemViewFrame = itemView.frame
        let scrollViewBounds = self.bounds
        
        var itemTopLeftInScrollView = NSZeroPoint
        
        let itemClipView = self.itemClipView
        let itemClipBounds = itemClipView.bounds
        let itemClipFrame = itemClipView.frame
        
        let itemParentFrame = self.itemParentView.frame
        
        if itemViewFrame.origin.y < itemClipBounds.origin.y {
            
            // scroll items up
            
            let minimumY = itemClipFrame.origin.y + itemViewFrame.size.height
            let maximumY = scrollViewBounds.origin.y + itemViewFrame.maxY
            
            itemTopLeftInScrollView.y = max( scrollViewBounds.origin.y, minimumY )
            itemTopLeftInScrollView.y = min( itemTopLeftInScrollView.y, maximumY )
            itemTopLeftInScrollView.x = scrollViewBounds.origin.x
        }
        else if itemViewFrame.maxY > itemClipBounds.maxY {
            
            // scroll items down
            
            let maximumY = itemClipFrame.maxY
            let minimumY = scrollViewBounds.maxY - ( itemParentFrame.size.height - itemViewFrame.maxY )
            
            itemTopLeftInScrollView.y = min( scrollViewBounds.maxY, maximumY )
            itemTopLeftInScrollView.y = max( itemTopLeftInScrollView.y, minimumY )
            itemTopLeftInScrollView.x = scrollViewBounds.origin.x
        }
        else {
            return
        }
        
        let locationInScreen = self.obw_convertPointToScreen( itemTopLeftInScrollView )
        
        let menuLocation = NSPoint(
            x: itemViewFrame.minX,
            y: itemViewFrame.maxY
        )
        
        self.filteringMenuWindow?.displayMenuLocation( menuLocation, atScreenLocation: locationInScreen, allowWindowToGrowUpward: false, resetScrollTracking: false )
    }
    
}
