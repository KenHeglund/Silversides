/*===========================================================================
 OBWPathView.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

public enum OBWPathItemTrigger {
    
    case gui( NSEvent )
    case accessibility
}

public protocol OBWPathViewDelegate: AnyObject {
    
    func pathView( _ pathView: OBWPathView, filteringMenuForItem: OBWPathItem, trigger: OBWPathItemTrigger ) -> OBWFilteringMenu?
    func pathView( _ pathView: OBWPathView, menuForItem: OBWPathItem, trigger: OBWPathItemTrigger ) -> NSMenu?
    
    func pathViewAccessibilityDescription( _ pathView: OBWPathView ) -> String?
    func pathViewAccessibilityHelp( _ pathView: OBWPathView ) -> String?
    func pathView( _ pathView: OBWPathView, accessibilityHelpForItem: OBWPathItem ) -> String?
}

public enum OBWPathViewError: Error {
    case invalidIndex( index: Int, endIndex: Int )
    case imbalancedEndPathItemUpdate
}

/*==========================================================================*/

private enum OBWPathViewCompression: Int {
    case none = 0
    case interior       // Lowest resistance to compression
    case head
    case penultimate
    case tail           // Highest resistance to compression
}

/*==========================================================================*/
// MARK: -

open class OBWPathView: NSView {
    
    /*==========================================================================*/
    public override init( frame frameRect: NSRect ) {
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
        
        let options: NSTrackingArea.Options = [ NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.mouseMoved, NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.inVisibleRect ]
        let trackingArea = NSTrackingArea( rect: self.bounds, options: options, owner: self, userInfo: nil )
        self.addTrackingArea( trackingArea )
        
        self.wantsLayer = true
        
        if let layer = self.layer {
            layer.backgroundColor = NSColor.textBackgroundColor.cgColor
            layer.borderColor = NSColor.tertiaryLabelColor.cgColor
            layer.borderWidth = 1.0
        }
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver( self, selector: #selector(OBWPathView.windowBecameOrResignedMain(_:)), name: NSWindow.didBecomeMainNotification, object: self.window )
        notificationCenter.addObserver( self, selector: #selector(OBWPathView.windowBecameOrResignedMain(_:)), name: NSWindow.didResignMainNotification, object: self.window )
    }
    
    /*==========================================================================*/
    deinit {
        
        try! self.removeItemsFromIndex( 0 )
        
        NotificationCenter.default.removeObserver( self )
    }
    
    /*==========================================================================*/
    // MARK: - NSResponder overrides
    
    /*==========================================================================*/
    override open func mouseEntered( with theEvent: NSEvent ) {
        self.mouseMoved( with: theEvent )
    }
    
    /*==========================================================================*/
    override open func mouseExited( with theEvent: NSEvent ) {
        
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
    override open func mouseMoved( with theEvent: NSEvent ) {
        
        guard self.pathItemUpdateDepth == 0 else { return }
        
        let locationInView = self.convert( theEvent.locationInWindow, from: nil )
        
        if !self.updatePreferredWidthRequirementsForCursorLocation( locationInView ) { return }
        
        self.updateCurrentItemViewWidths()
        self.adjustItemViewFrames( animate: true )
    }
    
    /*==========================================================================*/
    // MARK: - NSView overrides
    
    /*==========================================================================*/
    override open func resize( withOldSuperviewSize oldSize: NSSize ) {
        super.resize( withOldSuperviewSize: oldSize )
        self.updateCurrentItemViewWidths()
        self.adjustItemViewFrames( animate: false )
    }
    
    /*==========================================================================*/
    override open func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.active = self.window?.isMainWindow ?? false
    }
    
    /*==========================================================================*/
    // MARK: - NSAccessibility implementation
    
    /*==========================================================================*/
    override open func isAccessibilityElement() -> Bool {
        return true
    }
    
    /*==========================================================================*/
    override open func accessibilityRole() -> NSAccessibilityRole? {
        return NSAccessibilityRole.list
    }
    
    /*==========================================================================*/
    override open func accessibilityRoleDescription() -> String? {
        
        let descriptionFormat = NSLocalizedString( "path element %@", comment: "PathView accessibility role description format" )
        guard let standardDescription = NSAccessibilityRole.list.description(with: nil ) else { return nil }
        return String( format: descriptionFormat, standardDescription )
    }
    
    /*==========================================================================*/
    override open func accessibilityValueDescription() -> String? {
        return self.delegate?.pathViewAccessibilityDescription( self ) ?? "Empty Path"
    }
    
    /*==========================================================================*/
    override open func accessibilityChildren() -> [Any]? {
        return NSAccessibilityUnignoredChildren( self.itemViews )
    }
    
    /*==========================================================================*/
    override open func isAccessibilityEnabled() -> Bool {
        return self.enabled
    }
    
    /*==========================================================================*/
    override open func accessibilityOrientation() -> NSAccessibilityOrientation {
        return .horizontal
    }
    
    /*==========================================================================*/
    override open func accessibilityHelp() -> String? {
        return self.delegate?.pathViewAccessibilityHelp( self )
    }
    
    /*==========================================================================*/
    // MARK: - OBWPathView public
    
    open weak var delegate: OBWPathViewDelegate? = nil
    
    /*==========================================================================*/
    @objc open dynamic var enabled = true {
        
        didSet {
            
            for itemView in self.itemViews {
                itemView.pathViewAppearanceChanged()
            }
        }
    }
    
    /*==========================================================================*/
    open var numberOfItems: Int {
        return self.itemViews.count
    }
    
    /*==========================================================================*/
    open func setItems( _ pathItems: [OBWPathItem] ) {
        
        self.pathItemUpdate { 
            
            for itemIndex in pathItems.indices.suffix(from: 0) {
                try! self.setItem( pathItems[itemIndex], atIndex: itemIndex )
            }
            
            try! self.removeItemsFromIndex( pathItems.endIndex )
        }
    }
    
    /*==========================================================================*/
    open func item( atIndex index: Int ) throws -> OBWPathItem {
        
        let endIndex = self.itemViews.endIndex
        
        guard index >= 0 && index < endIndex else {
            throw OBWPathViewError.invalidIndex( index: index, endIndex: endIndex )
        }
        
        return self.itemViews[index].pathItem!
    }
    
    /*==========================================================================*/
    open func setItem( _ item: OBWPathItem, atIndex index: Int ) throws {
        
        let endIndex = self.itemViews.endIndex
        
        guard index >= 0 && index <= endIndex else {
            throw OBWPathViewError.invalidIndex( index: index, endIndex: endIndex )
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
    open func removeItemsFromIndex( _ index: Int ) throws {
        
        let endIndex = self.itemViews.endIndex
        
        guard index >= 0 && index <= endIndex else {
            throw OBWPathViewError.invalidIndex( index: index, endIndex: endIndex )
        }
        
        if index == endIndex {
            return
        }
        
        self.pathItemUpdate {
            self.terminatedViews = Array( self.itemViews.suffix( from: index ) )
            self.itemViews = Array( self.itemViews.prefix( upTo: index ) )
        }
    }
    
    /*==========================================================================*/
    open func beginPathItemUpdate() {
        self.pathItemUpdateDepth += 1
    }
    
    /*==========================================================================*/
    open func endPathItemUpdate() throws {
        
        if self.pathItemUpdateDepth <= 0 {
            throw OBWPathViewError.imbalancedEndPathItemUpdate
        }
        
        self.pathItemUpdateDepth -= 1
        
        guard self.pathItemUpdateDepth == 0 else { return }
        
        self.updateItemDividerVisibility()
        _ = self.updatePreferredWidthRequirements()
        self.updateCurrentItemViewWidths()
        self.adjustItemViewFrames( animate: true )
    }
    
    /*==========================================================================*/
    open func pathItemUpdate( withHandler handler: () -> Void ) {
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
    @objc private func windowBecameOrResignedMain( _ notification: Notification ) {
        self.needsDisplay = true
        self.active = ( notification.name == NSWindow.didBecomeMainNotification )
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
        
        let locationInScreen = NSRect( origin: NSEvent.mouseLocation, size: NSZeroSize )
        let locationInWindow = window.convertFromScreen( locationInScreen )
        let locationInView = self.convert( locationInWindow.origin, from: nil )
        
        return self.updatePreferredWidthRequirementsForCursorLocation( locationInView )
    }

    
    /*==========================================================================*/
    private func updatePreferredWidthRequirementsForCursorLocation( _ locationInView: NSPoint ) -> Bool {
        
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
        
        var compression = OBWPathViewCompression.interior
        var widthToCompress = totalPreferredWidth - parentWidth
        
        if parentWidth < headMinimumWidth + interiorMinimumWidth + penultimateMinimumWidth + tailPreferredWidth {
            compression = .tail
        }
        else if parentWidth < headMinimumWidth + interiorMinimumWidth + penultimatePreferredWidth + tailPreferredWidth {
            compression = .penultimate
        }
        else if parentWidth < headPreferredWidth + interiorMinimumWidth + penultimatePreferredWidth + tailPreferredWidth {
            compression = .head
        }
        
        if compression.rawValue >= OBWPathViewCompression.interior.rawValue && !interiorItemViews.isEmpty {
            widthToCompress -= self.compress( itemViews: interiorItemViews, by: widthToCompress )
        }
        
        if let headItemView = headItemView {
            if compression.rawValue >= OBWPathViewCompression.head.rawValue {
                widthToCompress -= self.compress( itemViews: [headItemView], by: widthToCompress )
            }
        }
        
        if let penultimateItemView = penultimateItemView {
            if compression.rawValue >= OBWPathViewCompression.penultimate.rawValue {
                widthToCompress -= self.compress( itemViews: [penultimateItemView], by: widthToCompress )
            }
        }
        
        if compression.rawValue == OBWPathViewCompression.tail.rawValue {
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
    private func compress( itemViews: [OBWPathItemView], by compression: CGFloat ) -> CGFloat {
        
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
    private func adjustItemViewFrames( animate: Bool ) {
        
        let shiftKey = NSEvent.modifierFlags.contains( NSEvent.ModifierFlags.shift )
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
