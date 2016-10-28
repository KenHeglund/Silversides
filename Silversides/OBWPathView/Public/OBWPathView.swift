/*===========================================================================
 OBWPathView.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

public enum OBWPathItemTrigger {
    
    case GUI( NSEvent )
    case Accessibility
}

public protocol OBWPathViewDelegate: AnyObject {
    
    func pathView( pathView: OBWPathView, filteringMenuForItem: OBWPathItem, trigger: OBWPathItemTrigger ) -> OBWFilteringMenu?
    func pathView( pathView: OBWPathView, menuForItem: OBWPathItem, trigger: OBWPathItemTrigger ) -> NSMenu?
    
    func pathViewAccessibilityDescription( pathView: OBWPathView ) -> String?
    func pathViewAccessibilityHelp( pathView: OBWPathView ) -> String?
    func pathView( pathView: OBWPathView, accessibilityHelpForItem: OBWPathItem ) -> String?
}

public enum OBWPathViewError: ErrorType {
    case InvalidIndex( index: Int, endIndex: Int )
    case ImbalancedEndPathItemUpdate
}

/*==========================================================================*/

private enum OBWPathViewCompression: Int {
    case None = 0
    case Interior       // Lowest resistance to compression
    case Head
    case Penultimate
    case Tail           // Highest resistance to compression
}

/*==========================================================================*/
// MARK: -

public class OBWPathView: NSView {
    
    /*==========================================================================*/
    override init( frame frameRect: NSRect ) {
        super.init( frame: frameRect )
        self.commonInitialization()
    }
    
    /*==========================================================================*/
    public required init?( coder: NSCoder ) {
        super.init( coder: coder )
        self.commonInitialization()
    }
    
    /*==========================================================================*/
    private func commonInitialization() {
        
        self.autoresizesSubviews = false
        
        let options: NSTrackingAreaOptions = [ .MouseEnteredAndExited, .MouseMoved, .ActiveAlways, .InVisibleRect ]
        let trackingArea = NSTrackingArea( rect: self.bounds, options: options, owner: self, userInfo: nil )
        self.addTrackingArea( trackingArea )
        
        self.wantsLayer = true
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver( self, selector: #selector(OBWPathView.windowBecameOrResignedMain(_:)), name: NSWindowDidBecomeMainNotification, object: self.window )
        notificationCenter.addObserver( self, selector: #selector(OBWPathView.windowBecameOrResignedMain(_:)), name: NSWindowDidResignMainNotification, object: self.window )
    }
    
    /*==========================================================================*/
    deinit {
        
        try! self.removeItemsFromIndex( 0 )
        
        NSNotificationCenter.defaultCenter().removeObserver( self )
    }
    
    /*==========================================================================*/
    // MARK: - NSResponder overrides
    
    /*==========================================================================*/
    override public func mouseEntered( theEvent: NSEvent ) {
        self.mouseMoved( theEvent )
    }
    
    /*==========================================================================*/
    override public func mouseExited( theEvent: NSEvent ) {
        
        guard self.pathItemUpdateDepth == 0 else { return }
        
        var updateItemWidths = false
        
        for itemView in self.itemViews {
            
            if itemView.preferredWidthRequired {
                itemView.preferredWidthRequired = false
                updateItemWidths = true
            }
        }
        
        if updateItemWidths {
            self.updateCurrentItemViewWidths()
            self.adjustItemViewFrames( animate: true )
        }
    }
    
    /*==========================================================================*/
    override public func mouseMoved( theEvent: NSEvent ) {
        
        guard self.pathItemUpdateDepth == 0 else { return }
        
        let locationInView = self.convertPoint( theEvent.locationInWindow, fromView: nil )
        
        if !self.updatePreferredWidthRequirementsForCursorLocation( locationInView ) { return }
        
        self.updateCurrentItemViewWidths()
        self.adjustItemViewFrames( animate: true )
    }
    
    /*==========================================================================*/
    // MARK: - NSView overrides
    
    /*==========================================================================*/
    override public var wantsUpdateLayer: Bool { return true }
    
    /*==========================================================================*/
    override public func updateLayer() {
        self.updateLayerContents()
    }
    
    /*==========================================================================*/
    override public func resizeWithOldSuperviewSize( oldSize: NSSize ) {
        super.resizeWithOldSuperviewSize( oldSize )
        self.updateCurrentItemViewWidths()
        self.adjustItemViewFrames( animate: false )
    }
    
    /*==========================================================================*/
    override public func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.active = self.window?.mainWindow ?? false
    }
    
    /*==========================================================================*/
    // MARK: - NSAccessibility implementation
    
    /*==========================================================================*/
    override public func isAccessibilityElement() -> Bool {
        return true
    }
    
    /*==========================================================================*/
    override public func accessibilityRole() -> String? {
        return NSAccessibilityListRole
    }
    
    /*==========================================================================*/
    override public func accessibilityRoleDescription() -> String? {
        
        let descriptionFormat = NSLocalizedString( "path element %@", comment: "PathView accessibility role description format" )
        guard let standardDescription = NSAccessibilityRoleDescription( NSAccessibilityListRole, nil ) else { return nil }
        return String( format: descriptionFormat, standardDescription )
    }
    
    /*==========================================================================*/
    override public func accessibilityValueDescription() -> String? {
        return self.delegate?.pathViewAccessibilityDescription( self ) ?? "Empty Path"
    }
    
    /*==========================================================================*/
    override public func accessibilityChildren() -> [AnyObject]? {
        return NSAccessibilityUnignoredChildren( self.itemViews )
    }
    
    /*==========================================================================*/
    override public func isAccessibilityEnabled() -> Bool {
        return self.enabled
    }
    
    /*==========================================================================*/
    override public func accessibilityOrientation() -> NSAccessibilityOrientation {
        return .Horizontal
    }
    
    /*==========================================================================*/
    override public func accessibilityHelp() -> String? {
        return self.delegate?.pathViewAccessibilityHelp( self )
    }
    
    /*==========================================================================*/
    // MARK: - OBWPathView public
    
    public weak var delegate: OBWPathViewDelegate? = nil
    
    /*==========================================================================*/
    public dynamic var enabled = true {
        
        didSet {
            
            for itemView in self.itemViews {
                itemView.pathViewAppearanceChanged()
            }
        }
    }
    
    /*==========================================================================*/
    public var numberOfItems: Int {
        return self.itemViews.count
    }
    
    /*==========================================================================*/
    public func setItems( pathItems: [OBWPathItem] ) {
        
        self.pathItemUpdate { 
            
            for itemIndex in 0 ..< pathItems.endIndex {
                try! self.setItem( pathItems[itemIndex], atIndex: itemIndex )
            }
            
            try! self.removeItemsFromIndex( pathItems.endIndex )
        }
    }
    
    /*==========================================================================*/
    public func item( atIndex index: Int ) throws -> OBWPathItem {
        
        let endIndex = self.itemViews.endIndex
        
        guard index >= 0 && index < endIndex else {
            throw OBWPathViewError.InvalidIndex( index: index, endIndex: endIndex )
        }
        
        return self.itemViews[index].pathItem!
    }
    
    /*==========================================================================*/
    public func setItem( item: OBWPathItem, atIndex index: Int ) throws {
        
        let endIndex = self.itemViews.endIndex
        
        guard index >= 0 && index <= endIndex else {
            throw OBWPathViewError.InvalidIndex( index: index, endIndex: endIndex )
        }
        
        self.pathItemUpdate {
            
            if index == endIndex {
                
                let pathViewBounds = self.bounds
                
                var newItemViewFrame = NSRect(
                    x: pathViewBounds.origin.x + pathViewBounds.size.width,
                    y: pathViewBounds.origin.y,
                    width: 50.0,
                    height: pathViewBounds.size.height
                )
                
                if let lastView = self.itemViews.last {
                    let lastViewFrame = lastView.frame
                    newItemViewFrame.origin.x = max( newItemViewFrame.origin.x, lastViewFrame.origin.x + lastViewFrame.size.width )
                }
                
                let itemView = OBWPathItemView( frame: newItemViewFrame )
                itemView.alphaValue = 0.0
                itemView.pathItem = item
                self.addSubview( itemView )
                self.itemViews.append( itemView )
                
                newItemViewFrame.size.width = itemView.preferredWidth
                itemView.currentWidth = newItemViewFrame.size.width
                itemView.idleWidth = newItemViewFrame.size.width
                itemView.frame = newItemViewFrame
            }
            else {
                
                self.itemViews[index].pathItem = item
            }
                
        }
    }
    
    /*==========================================================================*/
    public func removeItemsFromIndex( index: Int ) throws {
        
        let endIndex = self.itemViews.endIndex
        
        guard index >= 0 && index <= endIndex else {
            throw OBWPathViewError.InvalidIndex( index: index, endIndex: endIndex )
        }
        
        if index == endIndex {
            return
        }
        
        self.pathItemUpdate {
            self.terminatedViews = Array( self.itemViews.suffixFrom( index ) )
            self.itemViews = Array( self.itemViews.prefixUpTo( index ) )
        }
    }
    
    /*==========================================================================*/
    public func beginPathItemUpdate() {
        self.pathItemUpdateDepth += 1
    }
    
    /*==========================================================================*/
    public func endPathItemUpdate() throws {
        
        if self.pathItemUpdateDepth <= 0 {
            throw OBWPathViewError.ImbalancedEndPathItemUpdate
        }
        
        self.pathItemUpdateDepth -= 1
        
        guard self.pathItemUpdateDepth == 0 else { return }
        
        self.updateItemDividerVisibility()
        self.updatePreferredWidthRequirements()
        self.updateCurrentItemViewWidths()
        self.adjustItemViewFrames( animate: true )
    }
    
    /*==========================================================================*/
    public func pathItemUpdate( @noescape withHandler handler: () -> Void ) {
        self.beginPathItemUpdate()
        handler()
        try! self.endPathItemUpdate()
    }
    
    /*==========================================================================*/
    // MARK: - OBWPathView private
    
    private(set) var active = false {
        
        didSet {
            
            guard self.enabled else { return }
            
            for itemView in self.itemViews {
                itemView.pathViewAppearanceChanged()
            }
        }
    }
    
    private var itemViews: [OBWPathItemView] = []
    private var pathItemUpdateDepth = 0
    
    private var terminatedViews: [OBWPathItemView]? = nil
    
    /*==========================================================================*/
    @objc private func windowBecameOrResignedMain( notification: NSNotification ) {
        self.updateLayerContents()
        self.active = ( notification.name == NSWindowDidBecomeMainNotification )
    }
    
    /*==========================================================================*/
    private func updateLayerContents() {
        
        guard let layer = self.layer else { return }
        
        layer.backgroundColor = CGColorCreateGenericGray( 1.0, 1.0 )
        layer.borderColor = CGColorCreateGenericGray( 0.55, 1.0 )
        layer.borderWidth = 1.0
    }
    
    /*==========================================================================*/
    private func updateItemDividerVisibility() {
        
        guard let lastItemView = self.itemViews.last else { return }
        
        for itemView in self.itemViews {
            itemView.dividerHidden = ( itemView === lastItemView )
        }
    }
    
    /*==========================================================================*/
    private func updatePreferredWidthRequirements() -> Bool {
        
        guard let window = self.window else { return false }
        
        let locationInScreen = NSRect( origin: NSEvent.mouseLocation(), size: NSZeroSize )
        let locationInWindow = window.convertRectFromScreen( locationInScreen )
        let locationInView = self.convertPoint( locationInWindow.origin, fromView: nil )
        
        return self.updatePreferredWidthRequirementsForCursorLocation( locationInView )
    }

    
    /*==========================================================================*/
    private func updatePreferredWidthRequirementsForCursorLocation( locationInView: NSPoint ) -> Bool {
        
        let cursorIsInParent = NSPointInRect( locationInView, self.bounds )
        
        var itemLeftBound = self.bounds.origin.x
        var anItemHasBeenCollapsed = false
        var anItemHasBeenExpanded = false
        
        for itemView in self.itemViews {
            
            if anItemHasBeenExpanded {
                itemView.preferredWidthRequired = false
                continue
            }
            
            let itemWidthToTest = ( anItemHasBeenCollapsed ? itemView.preferredWidth : itemView.currentWidth )
            let itemRightBound = itemLeftBound + itemWidthToTest
            let cursorIsInItem = ( locationInView.x >= itemLeftBound && locationInView.x < itemRightBound )
            let preferredWidthIsRequired = ( cursorIsInParent && cursorIsInItem )
            
            if itemView.preferredWidthRequired == preferredWidthIsRequired {
                itemLeftBound += itemWidthToTest
                continue
            }
            
            itemView.preferredWidthRequired = preferredWidthIsRequired
            
            if preferredWidthIsRequired {
                anItemHasBeenExpanded = true
                itemLeftBound += itemWidthToTest
            }
            else {
                anItemHasBeenCollapsed = true
                itemLeftBound += itemView.idleWidth
            }
        }
        
        return ( anItemHasBeenCollapsed || anItemHasBeenExpanded )
    }
    
    /*==========================================================================*/
    private func updateCurrentItemViewWidths() {
        
        var itemViews = self.itemViews
        
        if itemViews.isEmpty {
            return
        }
        
        var totalPreferredWidth: CGFloat = 0.0
        
        for itemView in itemViews {
            let preferredWidth = itemView.preferredWidth
            itemView.currentWidth = preferredWidth
            itemView.idleWidth = preferredWidth
            totalPreferredWidth += preferredWidth
        }
        
        let parentWidth = self.bounds.size.width
        
        if parentWidth >= totalPreferredWidth {
            return
        }
        
        let tailItemView = itemViews.removeLast()
        let penultimateItemView: OBWPathItemView? = ( itemViews.count > 0 ? itemViews.removeLast() : nil )
        let headItemView: OBWPathItemView? = ( itemViews.count > 0 ? itemViews.removeFirst() : nil )
        let interiorItemViews = itemViews
        
        let tailPreferredWidth = tailItemView.preferredWidth
        let penultimateMinimumWidth = penultimateItemView?.minimumWidth ?? 0.0
        let penultimatePreferredWidth = penultimateItemView?.preferredWidth ?? 0.0
        let headMinimumWidth = headItemView?.minimumWidth ?? 0.0
        let headPreferredWidth = headItemView?.preferredWidth ?? 0.0
        
        var interiorMinimumWidth: CGFloat = 0.0
        for itemView in interiorItemViews {
            interiorMinimumWidth += itemView.minimumWidth
        }
        
        var compression = OBWPathViewCompression.Interior
        var widthToCompress = totalPreferredWidth - parentWidth
        
        if parentWidth < headMinimumWidth + interiorMinimumWidth + penultimateMinimumWidth + tailPreferredWidth {
            compression = .Tail
        }
        else if parentWidth < headMinimumWidth + interiorMinimumWidth + penultimatePreferredWidth + tailPreferredWidth {
            compression = .Penultimate
        }
        else if parentWidth < headPreferredWidth + interiorMinimumWidth + penultimatePreferredWidth + tailPreferredWidth {
            compression = .Head
        }
        
        if compression.rawValue >= OBWPathViewCompression.Interior.rawValue && !interiorItemViews.isEmpty {
            widthToCompress -= self.compress( itemViews: interiorItemViews, by: widthToCompress )
        }
        
        if let headItemView = headItemView {
            if compression.rawValue >= OBWPathViewCompression.Head.rawValue {
                widthToCompress -= self.compress( itemViews: [headItemView], by: widthToCompress )
            }
        }
        
        if let penultimateItemView = penultimateItemView {
            if compression.rawValue >= OBWPathViewCompression.Penultimate.rawValue {
                widthToCompress -= self.compress( itemViews: [penultimateItemView], by: widthToCompress )
            }
        }
        
        if compression.rawValue == OBWPathViewCompression.Tail.rawValue {
            let tailMinimumWidth = tailItemView.minimumWidth
            let tailCurrentWidth = ( tailPreferredWidth - widthToCompress < tailMinimumWidth ? tailMinimumWidth : tailPreferredWidth - widthToCompress )
            tailItemView.currentWidth = tailCurrentWidth
            tailItemView.idleWidth = tailCurrentWidth
        }
        
        for itemView in self.itemViews {
            
            if itemView.preferredWidthRequired && itemView.currentWidth < itemView.preferredWidth {
                itemView.currentWidth = itemView.preferredWidth
            }
        }
    }
    
    /*==========================================================================*/
    private func compress( itemViews itemViews: [OBWPathItemView], by compression: CGFloat ) -> CGFloat {
        
        var compressibleItemViews: [OBWPathItemView] = []
        var totalWidthItemsCanCompress: CGFloat = 0.0
        
        for itemView in itemViews {
            
            let widthItemCanCompress = itemView.preferredWidth - itemView.minimumWidth
            
            if widthItemCanCompress > 0.0 {
                totalWidthItemsCanCompress += widthItemCanCompress
                compressibleItemViews.append( itemView )
            }
        }
        
        guard !compressibleItemViews.isEmpty else { return 0.0 }
        guard totalWidthItemsCanCompress > 0.0 else { return 0.0 }
        
        let widthToCompress = compression
        
        if totalWidthItemsCanCompress < widthToCompress {
            
            for itemView in compressibleItemViews {
                
                let minimumWidth = itemView.minimumWidth
                itemView.currentWidth = minimumWidth
                itemView.idleWidth = minimumWidth
            }
            
            return totalWidthItemsCanCompress
        }
        
        var widthRemainingToCompress = widthToCompress
        
        for itemView in compressibleItemViews {
            
            let preferredWidth = itemView.preferredWidth
            var widthToCompressItem = widthRemainingToCompress
            
            if itemView !== compressibleItemViews.last! {
                
                let widthItemCanCompress = preferredWidth - itemView.minimumWidth
                let compressionFraction = widthItemCanCompress / totalWidthItemsCanCompress
                widthToCompressItem = round( widthToCompress * compressionFraction )
            }
            
            let itemWidth = preferredWidth - widthToCompressItem
            itemView.currentWidth = itemWidth
            itemView.idleWidth = itemWidth
            widthRemainingToCompress -= widthToCompressItem
        }
        
        return widthToCompress
    }
    
    /*==========================================================================*/
    private func adjustItemViewFrames( animate animate: Bool ) {
        
        let shiftKey = NSEvent.modifierFlags().contains( .Shift )
        let animationDuration = ( animate ? ( shiftKey ? 2.5 : 0.1 ) : 0.0 )
        
        NSAnimationContext.runAnimationGroup({ ( context: NSAnimationContext ) in
            
            context.duration = animationDuration
            
            var itemOriginX = self.bounds.origin.x
            
            for itemView in self.itemViews {
                
                var itemFrame = itemView.frame
                itemFrame.origin.x = itemOriginX
                itemFrame.size.width = itemView.currentWidth
                
                let targetView = ( animate ? itemView.animator() : itemView )
                targetView.frame = itemFrame
                targetView.alphaValue = 1.0
                
                itemView.needsDisplay = true
                
                itemOriginX += itemFrame.size.width
            }
            
            }, completionHandler: nil )
        
        guard let terminatedViews = self.terminatedViews else { return }
        
        self.terminatedViews = nil
        
        NSAnimationContext.runAnimationGroup({ ( context: NSAnimationContext ) in
            
            context.duration = animationDuration
            
            var itemOriginX = self.bounds.origin.x + self.bounds.size.width
            
            for itemView in terminatedViews {
                
                var itemFrame = itemView.frame
                itemFrame.origin.x = itemOriginX
                
                let targetView = ( animate ? itemView.animator() : itemView )
                targetView.frame = itemFrame
                targetView.alphaValue = 0.0
                
                itemView.needsDisplay = true
                
                itemOriginX += itemFrame.size.width
            }
            
            }, completionHandler: {
                
                for itemView in terminatedViews {
                    
                    itemView.pathItem = nil
                    itemView.removeFromSuperview()
                }
        })
    }
}
