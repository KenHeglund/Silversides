/*===========================================================================
 OBWPathItemView.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/
// MARK: -

extension NSColor {
    
    func colorByScaling( hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat ) -> NSColor {
        
        guard let originalColor = self.usingColorSpaceName( NSColorSpaceName.deviceRGB ) else { return self }
        
        let pinColor = { ( value: CGFloat ) -> CGFloat in
            if value < 0.0 { return 0.0 }
            if value > 1.0 { return 1.0 }
            return value
        }
        
        let adjustedHue = pinColor( originalColor.hueComponent * hue )
        let adjustedSaturation = pinColor( originalColor.saturationComponent * saturation )
        let adjustedBrightness = pinColor( originalColor.brightnessComponent * brightness )
        let adjustedAlpha = pinColor( originalColor.alphaComponent * alpha )
        
        let adjustedColor = NSColor( deviceHue: adjustedHue, saturation: adjustedSaturation, brightness: adjustedBrightness, alpha: adjustedAlpha )
        
        return ( adjustedColor.usingColorSpaceName( self.colorSpaceName ) ?? self )
    }
    
}

/*==========================================================================*/
// MARK: -

class OBWPathItemView: NSView {
    
    /*==========================================================================*/
    override init( frame frameRect: NSRect ) {
        super.init( frame: frameRect )
        self.commonInitialization()
    }
    
    /*==========================================================================*/
    required init?( coder: NSCoder ) {
        super.init( coder: coder )
        self.commonInitialization()
    }
    
    /*==========================================================================*/
    fileprivate func commonInitialization() {
        
        self.currentWidth = self.bounds.size.width
        self.idleWidth = self.currentWidth
        self.preferredWidth = self.currentWidth
        
        self.addSubview( imageView )
        self.addSubview( titleField )
        self.addSubview( dividerView )
        
        self.autoresizingMask = NSView.AutoresizingMask()
        self.layerContentsRedrawPolicy = .duringViewResize
    }
    
    /*==========================================================================*/
    // MARK: - NSResponder overrides
    
    /*==========================================================================*/
    override func mouseDown( with theEvent: NSEvent ) {
        
        guard let pathView = self.superview as? OBWPathView else { return }
        guard pathView.enabled else { return }
        
        self.displayItemMenu( .gui( theEvent ) )
    }

    /*==========================================================================*/
    // MARK: - NSView overrides
    
    /*==========================================================================*/
    override func viewDidMoveToWindow() {
        
        super.viewDidMoveToWindow()
        
        self.updateTitleFieldContents()
        
        self.needsDisplay = true
        
        if self.recalculateWidths() {
            self.needsLayout = true
        }
    }
    
    /*==========================================================================*/
    override func layout() {
        
        let itemViewBounds = self.bounds
        var titleMargins = OBWPathItemView.titleMargins
        let imageMargins = OBWPathItemView.imageMargins
        let dividerMargins = OBWPathItemView.dividerMargins
        
        let imageView = self.imageView
        
        let imageHeight = itemViewBounds.size.height - imageMargins.bottom - imageMargins.top
        
        let imageFrame = NSRect(
            x: itemViewBounds.origin.x + imageMargins.left,
            y: itemViewBounds.origin.y + imageMargins.bottom,
            width: imageHeight,
            height: imageHeight
        )
        
        imageView.frame = imageFrame
        
        if !imageView.isHidden {
            titleMargins.left = imageMargins.left + imageFrame.size.width + max( imageMargins.right, titleMargins.left )
        }
        
        let dividerView = self.dividerView
        let dividerImageSize = dividerView.image?.size ?? NSZeroSize
        
        var dividerFrame = NSRect(
            x: itemViewBounds.origin.x + itemViewBounds.size.width - dividerMargins.right - dividerImageSize.width,
            y: floor( ( itemViewBounds.size.height - dividerImageSize.height ) / 2.0 ),
            width: dividerImageSize.width,
            height: dividerImageSize.height
        )
        
        let minimumDividerOriginX = itemViewBounds.origin.x + self.minimumWidth - ( dividerMargins.right + dividerImageSize.width )
        dividerFrame.origin.x = max( dividerFrame.origin.x, minimumDividerOriginX )
        
        dividerView.frame = dividerFrame
        
        if !dividerView.isHidden {
            titleMargins.right = dividerMargins.right + dividerFrame.size.width + min( dividerMargins.left, titleMargins.right )
        }
        
        let titleField = self.titleField
        
        // This is the distance from the top of the ESCPathItemView to the desired text baseline.
        let desiredDistanceFromTopOfViewToTitleBaseline: CGFloat = 16.0
        
        // This is the distance from the top of the NSTextFieldCell to the text baseline and appears to be an AppKit constant.  It was casually measured from screenshots on Mac OS X 10.8.
        let measuredDistanceFromTopOfCellToTextBaseline: CGFloat = 11.0
        
        var titleFrame = NSRect(
            x: titleMargins.left,
            y: 0.0,
            width: itemViewBounds.size.width - titleMargins.left - titleMargins.right,
            height: itemViewBounds.size.height - desiredDistanceFromTopOfViewToTitleBaseline + measuredDistanceFromTopOfCellToTextBaseline
        )
        
        OBWPathItemView.offscreenTextField.attributedStringValue = titleField.attributedStringValue
        OBWPathItemView.offscreenTextField.sizeToFit()
        let fieldHeight = OBWPathItemView.offscreenTextField.frame.size.height
        titleFrame.origin.y = titleFrame.size.height - fieldHeight
        titleFrame.size.height = fieldHeight
        
        titleField.frame = titleFrame
        
        super.layout()
    }
    
    /*==========================================================================*/
    // MARK: - NSAccessibility implementation
    
    /*==========================================================================*/
    override func isAccessibilityElement() -> Bool {
        return self.pathItem?.accessible ?? false
    }
    
    /*==========================================================================*/
    override func accessibilityRole() -> NSAccessibilityRole? {
        return NSAccessibilityRole.popUpButton
    }
    
    /*==========================================================================*/
    override func accessibilityRoleDescription() -> String? {
        
        let descriptionFormat = NSLocalizedString( "path element %@", comment: "PathItemView accessibility role description" )
        guard let standardDescription = NSAccessibilityRole.popUpButton.description(with: nil ) else { return nil }
        return String( format: descriptionFormat, standardDescription )
    }
    
    /*==========================================================================*/
    override func accessibilityChildren() -> [Any]? {
        return nil
    }
    
    /*==========================================================================*/
    override func isAccessibilityEnabled() -> Bool {
        guard let pathView = self.superview as? OBWPathView else { return false }
        return pathView.enabled
    }
    
    /*==========================================================================*/
    override func accessibilityValue() -> Any? {
        return self.pathItem?.title ?? ""
    }
    
    /*==========================================================================*/
    override func accessibilityHelp() -> String? {
        guard let pathView = self.superview as? OBWPathView else { return nil }
        guard let pathItem = self.pathItem else { return nil }
        return pathView.delegate?.pathView( pathView, accessibilityHelpForItem: pathItem )
    }
    
    /*==========================================================================*/
    override func accessibilityPerformPress() -> Bool {
        self.displayItemMenu( .accessibility )
        return true
    }
    
    /*==========================================================================*/
    override func accessibilityPerformShowMenu() -> Bool {
        self.displayItemMenu( .accessibility )
        return true
    }
    
    /*==========================================================================*/
    // MARK: - OBWPathItemView implementation
    
    var preferredWidthRequired: Bool = false
    var currentWidth: CGFloat = 0.0
    var idleWidth: CGFloat = 0.0
    
    fileprivate(set) var preferredWidth: CGFloat = 0.0
    fileprivate(set) var minimumWidth: CGFloat = 20.0
    
    /*==========================================================================*/
    var pathItem: OBWPathItem? = nil {
        
        didSet {
            
            self.updateTitleFieldContents()
            
            self.imageView.image = self.pathItem?.image ?? nil
            self.imageView.isHidden = ( self.imageView.image == nil )
            
            self.needsDisplay = true
            
            if self.recalculateWidths() {
                self.needsLayout = true
            }
        }
    }
    
    /*==========================================================================*/
    var dividerHidden: Bool {
        
        get {
            return self.dividerView.isHidden
        }
        
        set {
            
            if self.dividerView.isHidden == newValue {
                return
            }
            
            self.dividerView.isHidden = newValue
            
            if self.recalculateWidths() {
                self.needsLayout = true
            }
        }
    }
    
    /*==========================================================================*/
    func displayItemMenu( _ menuTrigger: OBWPathItemTrigger ) {
        
        guard let pathView = self.superview as? OBWPathView else { return }
        
        guard let hitPathItem = self.pathItem else { return }
        guard let delegate = pathView.delegate else { return }
        
        // OBWFilteringMenu
        if let filteringMenu = delegate.pathView( pathView, filteringMenuForItem: hitPathItem, trigger: menuTrigger ) {
            
            let menuItem = filteringMenu.itemWithTitle( hitPathItem.title )
            
            var itemLocation = NSPoint( x: self.bounds.minX, y: self.bounds.maxY )
            
            if let menuItem = menuItem {
            
                let pathTitleFieldFrame = self.titleField.frame
                
                let pathTitleOffset = NSSize(
                    width: pathTitleFieldFrame.origin.x - self.bounds.minX,
                    height: self.bounds.size.height - pathTitleFieldFrame.maxY
                )
                
                let menuItemTitleOffset = menuItem.titleOffset
                
                let menuItemLocationOffsets = NSSize(
                    width: pathTitleOffset.width - menuItemTitleOffset.width,
                    height: pathTitleOffset.height - menuItemTitleOffset.height
                )
                
                itemLocation.x += menuItemLocationOffsets.width
                itemLocation.y -= menuItemLocationOffsets.height
            }
            
            let event: NSEvent?
            let highlightItem: Bool?
            
            switch menuTrigger {
                
            case .gui( let triggerEvent ):
                event = triggerEvent
                highlightItem = nil
                
            case .accessibility:
                event = nil
                highlightItem = false
            }
            
            _ = filteringMenu.popUpMenuPositioningItem( menuItem, atLocation: itemLocation, inView: self, withEvent: event, highlightMenuItem: highlightItem )
        }
        
        // NSMenu
        else if let menu = delegate.pathView( pathView, menuForItem: hitPathItem, trigger: menuTrigger ) {
            
            let menuItem = menu.item( withTitle: hitPathItem.title )
            
            let minorVersion = ProcessInfo().operatingSystemVersion.minorVersion
            let menuItemLocationOffsets: NSSize
            
            if minorVersion <= 10 {
                // These offsets are based on the geometry of a standard NSMenu and were determined experimentally on Mac OS X 10.10
                menuItemLocationOffsets = NSSize( width: -17.0, height: 1.0 )
            }
            else {
                // These offsets are based on the geometry of a standard NSMenu and were determined experimentally on Mac OS X 10.11
                menuItemLocationOffsets = NSSize( width: -16.0, height: 2.0 )
            }
            
            let itemLocation = NSPoint(
                x: self.bounds.origin.x + menuItemLocationOffsets.width,
                y: self.bounds.origin.y + self.bounds.size.height - menuItemLocationOffsets.height
            )
            
            menu.popUp( positioning: menuItem, at: itemLocation, in: self )
        }
    }
    
    /*==========================================================================*/
    func pathViewAppearanceChanged() {
        
        guard let pathView = self.superview as? OBWPathView else { return }
        
        let activeAppearance = ( pathView.enabled && pathView.active )
        let imageAlpha = ( activeAppearance ? 1.0 : OBWPathItemView.disabledViewAlpha )
        
        self.imageView.alphaValue = imageAlpha
        self.dividerView.alphaValue = imageAlpha
        self.updateTitleFieldContents()
        self.needsDisplay = true
    }
    
    /*==========================================================================*/
    // MARK: - OBWPathItemView internal
    
    fileprivate static let offscreenTextField = NSTextField( frame: NSZeroRect )
    fileprivate var active: Bool = true
    
    /*==========================================================================*/
    fileprivate let imageView: NSImageView = {
        
        let itemImageView = NSImageView( frame: NSZeroRect )
        itemImageView.autoresizingMask = NSView.AutoresizingMask()
        itemImageView.isHidden = true
        itemImageView.cell?.setAccessibilityElement( false )
        
        return itemImageView
    }()
    
    /*==========================================================================*/
    fileprivate let titleField: NSTextField = {
        
        let titleField = NSTextField( frame: NSZeroRect )
        titleField.cell?.setAccessibilityElement( false )
        titleField.cell?.lineBreakMode = .byTruncatingTail
        titleField.autoresizingMask = NSView.AutoresizingMask()
        titleField.isEditable = false
        titleField.isSelectable = false
        titleField.isBezeled = false
        titleField.drawsBackground = false
        
        return titleField
    }()
    
    /*==========================================================================*/
    fileprivate let dividerView: NSImageView = {
        
        let dividerImage = OBWPathItemView.dividerImage
        
        let frame = NSRect( size: dividerImage.size )
        
        let dividerImageView = NSImageView( frame: frame )
        dividerImageView.cell?.setAccessibilityElement( false )
        dividerImageView.image = dividerImage
        dividerImageView.autoresizingMask = NSView.AutoresizingMask.maxXMargin
        dividerImageView.isHidden = true
        
        return dividerImageView
    }()
    
    fileprivate static let titleFontSize: CGFloat = 11.0
    fileprivate static let disabledViewAlpha: CGFloat = 0.5
    
    /*==========================================================================*/
    fileprivate static let imageMargins: NSEdgeInsets = {
        
        let minorVersion = ProcessInfo().operatingSystemVersion.minorVersion
        
        if minorVersion <= 10 {
            return NSEdgeInsets( top: 3.0, left: 4.0, bottom: 3.0, right: 2.0 )
        }
        else {
            return NSEdgeInsets( top: 3.0, left: 5.0, bottom: 4.0, right: 2.0 )
        }
    }()
    
    fileprivate static let titleMargins = NSEdgeInsets( top: 4.0, left: 2.0, bottom: 4.0, right: 2.0 )
    fileprivate static let dividerMargins = NSEdgeInsets( top: 0.0, left: 3.0, bottom: 0.0, right: 2.0 )
    
    fileprivate static let minimumTitleWidthWithoutImage: CGFloat = 20.0

    /*==========================================================================*/
    fileprivate static var dividerImage: NSImage = {
        
        let attributes: [NSAttributedStringKey:Any] = [
            .paragraphStyle : NSParagraphStyle.default,
            .font : NSFont.controlContentFont( ofSize: OBWPathItemView.titleFontSize + 6.0 ),
            .foregroundColor : NSColor( deviceWhite: 0.55, alpha: 1.0 ),
        ]
        
        let string = "⟩" as NSString // \xE2\x9F\xA9
        let stringBounds = string.boundingRect( with: NSZeroSize, options: [], attributes: attributes )
        
        let sourceFrame = NSRect(
            width: ceil( stringBounds.size.width ),
            height: ceil( stringBounds.size.height )
        )
        
        let sourceImage = NSImage( size: sourceFrame.size )
        sourceImage.withLockedFocus {
            string.draw( at: NSZeroPoint, withAttributes: attributes )
        }
        
        guard let dividerImage = sourceImage.imageByTrimmingTransparentEdges() else { return sourceImage }
        
        let maskImage = NSImage( size: dividerImage.size )
        maskImage.withLockedFocus {
            
            let colors = [
                NSColor.black,
                NSColor.clear,
                NSColor.clear,
            ]
            
            let locations: [CGFloat] = [ 0.0, 0.65, 1.0 ]
            
            guard let gradient = NSGradient( colors: colors, atLocations: locations, colorSpace: NSColorSpace.genericRGB ) else { return }
            
            let destinationRect = NSRect(
                size: dividerImage.size
            )
            
            gradient.draw( in: destinationRect, angle: 0.0 )
        }
        
        dividerImage.withLockedFocus {
            maskImage.draw( at: NSZeroPoint, from: NSZeroRect, operation: .destinationOut, fraction: 1.0 )
        }
        
        return dividerImage
    }()
    
    /*==========================================================================*/
    fileprivate class func titleFontForPathItemStyle( _ style: OBWPathItemStyle ) -> NSFont {
        
        var displayFont = NSFont.controlContentFont( ofSize: OBWPathItemView.titleFontSize )
        
        let sharedFontManager = NSFontManager.shared
        
        if style.contains( .italic ) {
            displayFont = sharedFontManager.convert( displayFont, toHaveTrait: .italicFontMask )
        }
        if style.contains( .bold ) {
            displayFont = sharedFontManager.convert( displayFont, toHaveTrait: .boldFontMask )
        }
        
        return displayFont
    }
    
    /*==========================================================================*/
    fileprivate func updateTitleFieldContents() {
        
        guard let title = self.pathItem?.title else {
            self.titleField.stringValue = ""
            return
        }
        
        guard let pathItem = self.pathItem else { return }
        guard let pathView = self.superview as? OBWPathView else { return }
        
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.lineBreakMode = .byTruncatingTail
        
        let displayFont = OBWPathItemView.titleFontForPathItemStyle( pathItem.style )
        
        let displayInActiveState = ( pathView.active && pathView.enabled )
        let titleColor: NSColor
        
        if let styleTitleColor = pathItem.textColor {
            
            if displayInActiveState {
                titleColor = styleTitleColor
            }
            else {
                titleColor = styleTitleColor.colorByScaling( hue: 1.0, saturation: 1.0, brightness: 1.0, alpha: OBWPathItemView.disabledViewAlpha )
            }
        }
        else if displayInActiveState {
            titleColor = NSColor.controlTextColor
        }
        else {
            titleColor = NSColor.disabledControlTextColor
        }
        
        let attributes: [NSAttributedStringKey:Any] = [
            .paragraphStyle : paragraphStyle,
            .font : displayFont,
            .foregroundColor : titleColor,
        ]
        
        self.titleField.attributedStringValue = NSAttributedString( string: title, attributes: attributes )
    }
    
    /*==========================================================================*/
    fileprivate func recalculateWidths() -> Bool {
        
        var titleMargins = OBWPathItemView.titleMargins
        var titleMinimumWidth = OBWPathItemView.minimumTitleWidthWithoutImage
        
        let imageView = self.imageView
        
        if !imageView.isHidden {
            
            let imageFrameWidth = self.bounds.size.height - OBWPathItemView.imageMargins.bottom - OBWPathItemView.imageMargins.top
            titleMargins.left = OBWPathItemView.imageMargins.left + imageFrameWidth + max( OBWPathItemView.imageMargins.right, OBWPathItemView.titleMargins.left )
            titleMinimumWidth = 0.0
        }
        
        let dividerView = self.dividerView
        
        if !dividerView.isHidden {
            let dividerImageSize = dividerView.image!.size
            titleMargins.right = OBWPathItemView.dividerMargins.right + dividerImageSize.width + min( OBWPathItemView.dividerMargins.left, OBWPathItemView.titleMargins.right )
        }
        
        let currentMinimumWidth = self.minimumWidth
        let newMinimumWidth = ( titleMargins.left + titleMinimumWidth + titleMargins.right )
        
        let currentPreferredWidth = self.preferredWidth
        var newPreferredWidth = newMinimumWidth
        
        if let cell = self.titleField.cell, let pathItem = self.pathItem {
            
            if !pathItem.title.isEmpty {
                let titlePreferredWidth = ceil( cell.cellSize.width )
                newPreferredWidth = ( titleMargins.left + max( titlePreferredWidth, titleMinimumWidth ) + titleMargins.right )
            }
        }
        
        self.preferredWidth = newPreferredWidth
        self.minimumWidth = newMinimumWidth
        
        return ( currentPreferredWidth != newPreferredWidth || currentMinimumWidth != newMinimumWidth )
    }
}
