/*===========================================================================
 OBWPathItemView.swift
 Silversides
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/
// MARK: -

extension NSColor {
    
    func colorByScaling( hue hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat ) -> NSColor {
        
        guard let originalColor = self.colorUsingColorSpaceName( NSDeviceRGBColorSpace ) else { return self }
        
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
        
        return ( adjustedColor.colorUsingColorSpaceName( self.colorSpaceName ) ?? self )
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
    private func commonInitialization() {
        
        self.currentWidth = self.bounds.size.width
        self.idleWidth = self.currentWidth
        self.preferredWidth = self.currentWidth
        
        self.addSubview( imageView )
        self.addSubview( titleField )
        self.addSubview( dividerView )
        
        self.autoresizingMask = .ViewNotSizable
        self.layerContentsRedrawPolicy = .DuringViewResize
    }
    
    /*==========================================================================*/
    // MARK: - NSResponder overrides
    
    /*==========================================================================*/
    override func mouseDown( theEvent: NSEvent ) {
        
        guard let pathView = self.superview as? OBWPathView else { return }
        guard pathView.enabled else { return }
        
        self.displayItemMenu( .GUI( theEvent ) )
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
        
        if !imageView.hidden {
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
        
        if !dividerView.hidden {
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
    override func accessibilityRole() -> String? {
        return NSAccessibilityPopUpButtonRole
    }
    
    /*==========================================================================*/
    override func accessibilityRoleDescription() -> String? {
        
        let descriptionFormat = NSLocalizedString( "path element %@", comment: "PathItemView accessibility role description" )
        guard let standardDescription = NSAccessibilityRoleDescription( NSAccessibilityPopUpButtonRole, nil ) else { return nil }
        return String( format: descriptionFormat, standardDescription )
    }
    
    /*==========================================================================*/
    override func accessibilityChildren() -> [AnyObject]? {
        return nil
    }
    
    /*==========================================================================*/
    override func isAccessibilityEnabled() -> Bool {
        guard let pathView = self.superview as? OBWPathView else { return false }
        return pathView.enabled
    }
    
    /*==========================================================================*/
    override func accessibilityValue() -> AnyObject? {
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
        self.displayItemMenu( .Accessibility )
        return true
    }
    
    /*==========================================================================*/
    override func accessibilityPerformShowMenu() -> Bool {
        self.displayItemMenu( .Accessibility )
        return true
    }
    
    /*==========================================================================*/
    // MARK: - OBWPathItemView implementation
    
    var preferredWidthRequired: Bool = false
    var currentWidth: CGFloat = 0.0
    var idleWidth: CGFloat = 0.0
    
    private(set) var preferredWidth: CGFloat = 0.0
    private(set) var minimumWidth: CGFloat = 20.0
    
    /*==========================================================================*/
    var pathItem: OBWPathItem? = nil {
        
        didSet {
            
            self.updateTitleFieldContents()
            
            self.imageView.image = self.pathItem?.image ?? nil
            self.imageView.hidden = ( self.imageView.image == nil )
            
            self.needsDisplay = true
            
            if self.recalculateWidths() {
                self.needsLayout = true
            }
        }
    }
    
    /*==========================================================================*/
    var dividerHidden: Bool {
        
        get {
            return self.dividerView.hidden
        }
        
        set {
            
            if self.dividerView.hidden == newValue {
                return
            }
            
            self.dividerView.hidden = newValue
            
            if self.recalculateWidths() {
                self.needsLayout = true
            }
        }
    }
    
    /*==========================================================================*/
    func displayItemMenu( menuTrigger: OBWPathItemTrigger ) {
        
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
                
            case .GUI( let triggerEvent ):
                event = triggerEvent
                highlightItem = nil
                
            case .Accessibility:
                event = nil
                highlightItem = false
            }
            
            filteringMenu.popUpMenuPositioningItem( menuItem, atLocation: itemLocation, inView: self, withEvent: event, highlightMenuItem: highlightItem )
        }
        
        // NSMenu
        else if let menu = delegate.pathView( pathView, menuForItem: hitPathItem, trigger: menuTrigger ) {
            
            let menuItem = menu.itemWithTitle( hitPathItem.title )
            
            let minorVersion = NSProcessInfo.processInfo().operatingSystemVersion.minorVersion
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
            
            menu.popUpMenuPositioningItem( menuItem, atLocation: itemLocation, inView: self )
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
    
    private static let offscreenTextField = NSTextField( frame: NSZeroRect )
    private var active: Bool = true
    
    /*==========================================================================*/
    private let imageView: NSImageView = {
        
        let itemImageView = NSImageView( frame: NSZeroRect )
        itemImageView.autoresizingMask = .ViewNotSizable
        itemImageView.hidden = true
        itemImageView.cell?.setAccessibilityElement( false )
        
        return itemImageView
    }()
    
    /*==========================================================================*/
    private let titleField: NSTextField = {
        
        let titleField = NSTextField( frame: NSZeroRect )
        titleField.cell?.setAccessibilityElement( false )
        titleField.cell?.lineBreakMode = .ByTruncatingTail
        titleField.autoresizingMask = .ViewNotSizable
        titleField.editable = false
        titleField.selectable = false
        titleField.bezeled = false
        titleField.drawsBackground = false
        
        return titleField
    }()
    
    /*==========================================================================*/
    private let dividerView: NSImageView = {
        
        let dividerImage = OBWPathItemView.dividerImage
        
        let frame = NSRect( size: dividerImage.size )
        
        let dividerImageView = NSImageView( frame: frame )
        dividerImageView.cell?.setAccessibilityElement( false )
        dividerImageView.image = dividerImage
        dividerImageView.autoresizingMask = .ViewMaxXMargin
        dividerImageView.hidden = true
        
        return dividerImageView
    }()
    
    private static let titleFontSize: CGFloat = 11.0
    private static let disabledViewAlpha: CGFloat = 0.5
    
    /*==========================================================================*/
    private static let imageMargins: NSEdgeInsets = {
        
        let minorVersion = NSProcessInfo.processInfo().operatingSystemVersion.minorVersion
        
        if minorVersion <= 10 {
            return NSEdgeInsets( top: 3.0, left: 4.0, bottom: 3.0, right: 2.0 )
        }
        else {
            return NSEdgeInsets( top: 3.0, left: 5.0, bottom: 4.0, right: 2.0 )
        }
    }()
    
    private static let titleMargins = NSEdgeInsets( top: 4.0, left: 2.0, bottom: 4.0, right: 2.0 )
    private static let dividerMargins = NSEdgeInsets( top: 0.0, left: 3.0, bottom: 0.0, right: 2.0 )
    
    private static let minimumTitleWidthWithoutImage: CGFloat = 20.0

    /*==========================================================================*/
    private static var dividerImage: NSImage = {
        
        let attributes: [String:AnyObject] = [
            NSParagraphStyleAttributeName : NSParagraphStyle.defaultParagraphStyle(),
            NSFontAttributeName : NSFont.controlContentFontOfSize( OBWPathItemView.titleFontSize + 6.0 ),
            NSForegroundColorAttributeName : NSColor( deviceWhite: 0.55, alpha: 1.0 ),
        ]
        
        let string = "⟩" as NSString // \xE2\x9F\xA9
        let stringBounds = string.boundingRectWithSize( NSZeroSize, options: [], attributes: attributes )
        
        let sourceFrame = NSRect(
            width: ceil( stringBounds.size.width ),
            height: ceil( stringBounds.size.height )
        )
        
        let sourceImage = NSImage( size: sourceFrame.size )
        sourceImage.withLockedFocus {
            string.drawAtPoint( NSZeroPoint, withAttributes: attributes )
        }
        
        guard let dividerImage = sourceImage.imageByTrimmingTransparentEdges() else { return sourceImage }
        
        let maskImage = NSImage( size: dividerImage.size )
        maskImage.withLockedFocus {
            
            let colors = [
                NSColor.blackColor(),
                NSColor.clearColor(),
                NSColor.clearColor(),
            ]
            
            let locations: [CGFloat] = [ 0.0, 0.65, 1.0 ]
            
            guard let gradient = NSGradient( colors: colors, atLocations: locations, colorSpace: NSColorSpace.genericRGBColorSpace() ) else { return }
            
            let destinationRect = NSRect(
                size: dividerImage.size
            )
            
            gradient.drawInRect( destinationRect, angle: 0.0 )
        }
        
        dividerImage.withLockedFocus {
            maskImage.drawAtPoint( NSZeroPoint, fromRect: NSZeroRect, operation: .DestinationOut, fraction: 1.0 )
        }
        
        return dividerImage
    }()
    
    /*==========================================================================*/
    private class func titleFontForPathItemStyle( style: OBWPathItemStyle ) -> NSFont {
        
        var displayFont = NSFont.controlContentFontOfSize( OBWPathItemView.titleFontSize )
        
        let sharedFontManager = NSFontManager.sharedFontManager()
        
        if style.contains( .Italic ) {
            displayFont = sharedFontManager.convertFont( displayFont, toHaveTrait: .ItalicFontMask )
        }
        if style.contains( .Bold ) {
            displayFont = sharedFontManager.convertFont( displayFont, toHaveTrait: .BoldFontMask )
        }
        
        return displayFont
    }
    
    /*==========================================================================*/
    private func updateTitleFieldContents() {
        
        guard let title = self.pathItem?.title else {
            self.titleField.stringValue = ""
            return
        }
        
        guard let pathItem = self.pathItem else { return }
        guard let pathView = self.superview as? OBWPathView else { return }
        
        let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.lineBreakMode = .ByTruncatingTail
        
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
            titleColor = NSColor.controlTextColor()
        }
        else {
            titleColor = NSColor.disabledControlTextColor()
        }
        
        let attributes: [String:AnyObject] = [
            NSParagraphStyleAttributeName : paragraphStyle,
            NSFontAttributeName : displayFont,
            NSForegroundColorAttributeName : titleColor,
        ]
        
        self.titleField.attributedStringValue = NSAttributedString( string: title, attributes: attributes )
    }
    
    /*==========================================================================*/
    private func recalculateWidths() -> Bool {
        
        var titleMargins = OBWPathItemView.titleMargins
        var titleMinimumWidth = OBWPathItemView.minimumTitleWidthWithoutImage
        
        let imageView = self.imageView
        
        if !imageView.hidden {
            
            let imageFrameWidth = self.bounds.size.height - OBWPathItemView.imageMargins.bottom - OBWPathItemView.imageMargins.top
            titleMargins.left = OBWPathItemView.imageMargins.left + imageFrameWidth + max( OBWPathItemView.imageMargins.right, OBWPathItemView.titleMargins.left )
            titleMinimumWidth = 0.0
        }
        
        let dividerView = self.dividerView
        
        if !dividerView.hidden {
            let dividerImageSize = dividerView.image!.size
            titleMargins.right = OBWPathItemView.dividerMargins.right + dividerImageSize.width + min( OBWPathItemView.dividerMargins.left, OBWPathItemView.titleMargins.right )
        }
        
        let currentMinimumWidth = self.minimumWidth
        let newMinimumWidth = ( titleMargins.left + titleMinimumWidth + titleMargins.right )
        
        let currentPreferredWidth = self.preferredWidth
        var newPreferredWidth = newMinimumWidth
        
        if let cell = self.titleField.cell, pathItem = self.pathItem {
            
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
