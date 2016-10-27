/*===========================================================================
 OBWFilteringMenuActionItemView.swift
 Silversides
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

class OBWTextFieldCell: NSTextFieldCell {
    override func accessibilityIsIgnored() -> Bool {
        return true
    }
}

class OBWImageCell: NSImageCell {
    override func accessibilityIsIgnored() -> Bool {
        return true
    }
}

extension NSGraphicsContext {
    
    static func withSavedGraphicsState( @noescape handler: () -> Void ) {
        NSGraphicsContext.saveGraphicsState()
        handler()
        NSGraphicsContext.restoreGraphicsState()
    }
}

/*==========================================================================*/
// MARK: -

class OBWFilteringMenuActionItemView: OBWFilteringMenuItemView {
    
    /*==========================================================================*/
    override init( menuItem: OBWFilteringMenuItem ) {
        
        assert( !menuItem.isSeparatorItem )
        
        let itemTitleField = NSTextField( frame: NSZeroRect )
        self.itemTitleField = itemTitleField
        
        let itemImageSize = menuItem.image?.size ?? NSZeroSize
        let itemImageFrame = NSRect( size: itemImageSize )
        
        let itemImageView = NSImageView( frame: itemImageFrame )
        self.itemImageView = itemImageView
        
        let subviewArrowImageView = NSImageView( frame: OBWFilteringMenuActionItemView.subviewArrowFrame )
        self.subviewArrowImageView = subviewArrowImageView
        
        super.init( menuItem: menuItem )
        
        itemTitleField.cell = OBWTextFieldCell()
        itemTitleField.editable = false
        itemTitleField.selectable = false
        itemTitleField.bezeled = false
        #if DEBUG_MENU_TINTING
            itemTitleField.drawsBackground = true
            itemTitleField.backgroundColor = NSColor( deviceRed: 1.0, green: 0.0, blue: 0.0, alpha: 0.15 )
        #else
            itemTitleField.drawsBackground = false
        #endif
        itemTitleField.cell?.lineBreakMode = .ByClipping
        itemTitleField.textColor = NSColor.blackColor()
        itemTitleField.alphaValue = ( menuItem.enabled ? 1.0 : 0.35 )
        itemTitleField.attributedStringValue = self.attributedStringValue
        
        self.addSubview( itemTitleField )
        
        itemImageView.cell = OBWImageCell()
        itemImageView.image = menuItem.image
        itemImageView.imageFrameStyle = .None
        itemImageView.editable = false
        itemImageView.hidden = ( menuItem.image == nil )
        itemImageView.enabled = menuItem.enabled
        
        self.addSubview( itemImageView )
        
        subviewArrowImageView.cell = OBWImageCell()
        subviewArrowImageView.image = OBWFilteringMenuArrows.blackRightArrow
        subviewArrowImageView.imageFrameStyle = .None
        subviewArrowImageView.editable = false
        subviewArrowImageView.hidden = ( menuItem.submenu == nil )
        
        self.addSubview( subviewArrowImageView )
        
        NSNotificationCenter.defaultCenter().addObserver( self, selector: #selector(OBWFilteringMenuActionItemView.highlightedItemDidChange(_:)), name: OBWFilteringMenu.highlightedItemDidChangeNotification, object: nil )
    }
    
    /*==========================================================================*/
    required init?( coder: NSCoder ) {
        fatalError( "init(coder:) has not been implemented" )
    }
    
    /*==========================================================================*/
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver( self, name: OBWFilteringMenu.highlightedItemDidChangeNotification, object: nil )
    }
    
    /*==========================================================================*/
    // MARK: - NSView overrides
    
    /*==========================================================================*/
    override func resizeSubviewsWithOldSize( oldSize: NSSize ) {
        
        let itemViewBounds = self.bounds
        let interiorMargins = OBWFilteringMenuActionItemView.interiorMargins
        let imageMargins = OBWFilteringMenuActionItemView.imageMargins
        
        let imageFrameOffsetY: CGFloat
        let titleFrameOffsetY: CGFloat
        
        let attributedTitleLength = self.menuItem.attributedTitle?.length ?? 0
        let fontHeight = self.menuItem.font
        if attributedTitleLength == 0 && fontHeight == NSFont.systemFontSizeForControlSize( .Regular ) {
            // Special cases for the standard Regular control size
            imageFrameOffsetY = 1.0
            titleFrameOffsetY = 1.0
        }
        else {
            imageFrameOffsetY = -1.0
            titleFrameOffsetY = 0.0
        }
        
        let imageSize = self.menuItem.image?.size ?? NSZeroSize
        let imageFrame = NSRect(
            x: interiorMargins.left + imageMargins.left,
            y: floor( ( itemViewBounds.size.height - imageSize.height ) / 1.0 ) + imageFrameOffsetY,
            size: imageSize
        )
        
        let titleSize = OBWFilteringMenuActionItemView.preferredViewSizeForTitleOfMenuItem( self.menuItem )
        let titleFrame = NSRect(
            x: ( imageFrame.size.width > 0 ? imageFrame.maxX + imageMargins.right : interiorMargins.left ),
            y: floor( ( itemViewBounds.size.height - titleSize.height ) / 2.0 ) + titleFrameOffsetY,
            size: titleSize
        )
        
        self.itemImageView.frame = imageFrame
        self.itemTitleField.frame = titleFrame
        
        var arrowImageFrame = self.subviewArrowImageView.frame
        arrowImageFrame.origin.y = itemViewBounds.origin.y + round( ( itemViewBounds.size.height - arrowImageFrame.size.height ) / 2.0 )
        arrowImageFrame.origin.x = itemViewBounds.maxX - arrowImageFrame.size.width - interiorMargins.right
        self.subviewArrowImageView.setFrameOrigin( arrowImageFrame.origin )
    }
    
    /*==========================================================================*/
    override func drawRect( dirtyRect: NSRect ) {
        
        #if DEBUG_MENU_TINTING
            NSColor( deviceRed: 0.0, green: 1.0, blue: 0.0, alpha: 0.1 ).set()
            NSRectFill( self.bounds )
        #endif
        
        if !self.menuItem.isHighlighted { return }
        
        NSGraphicsContext.withSavedGraphicsState {
            
            let localOrigin = self.bounds.origin
            let originInWindow = self.convertPoint( localOrigin, toView: nil )
            
            NSGraphicsContext.currentContext()?.patternPhase = originInWindow
            
            NSColor.selectedMenuItemColor().setFill()
            NSRectFill( self.bounds )
        }
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuItemView overrides
    
    /*==========================================================================*/
    override class func preferredSizeForMenuItem( menuItem: OBWFilteringMenuItem ) -> NSSize {
        
        let interiorMargins = OBWFilteringMenuActionItemView.interiorMargins
        let imageMargins = OBWFilteringMenuActionItemView.imageMargins
        let subviewArrowFrame = OBWFilteringMenuActionItemView.subviewArrowFrame
        let titleToSubmenuArrowSpacing = OBWFilteringMenuActionItemView.titleToSubmenuArrowSpacing
        
        var imageSize = menuItem.image?.size ?? NSZeroSize
        imageSize.height += imageMargins.height
        
        let titleSize = OBWFilteringMenuActionItemView.preferredViewSizeForTitleOfMenuItem( menuItem )
        
        var preferredSize = NSSize(
            width: interiorMargins.width + imageSize.width + titleSize.width,
            height: 0.0
        )
        
        if imageSize.width > 0.0 {
            
            preferredSize.width += imageMargins.left
            
            if titleSize.width > 0.0 {
                preferredSize.width += imageMargins.right
            }
        }
        
        if menuItem.submenu != nil {
            preferredSize.width += titleToSubmenuArrowSpacing + subviewArrowFrame.size.width
        }
        
        preferredSize.height = max( imageSize.height, titleSize.height )
        preferredSize.height = max( preferredSize.height, subviewArrowFrame.size.height )
        
        if menuItem.attributedTitle != nil {
            return preferredSize
        }
        
        // Special cases for non-attributed titles with standard control font sizes
        let fontHeight = menuItem.font.pointSize
        
        let standardMiniControlMenuItemHeight: CGFloat = 13.0
        let standardSmallControlMenuItemHeight: CGFloat = 16.0
        let standardRegularControlMenuItemHeight: CGFloat = 18.0
        
        if NSFont.systemFontSizeForControlSize( .Mini ) == fontHeight {
            preferredSize.height = max( preferredSize.height, standardMiniControlMenuItemHeight )
        }
        else if NSFont.systemFontSizeForControlSize( .Small ) == fontHeight {
            preferredSize.height = max( preferredSize.height, standardSmallControlMenuItemHeight )
        }
        else if NSFont.systemFontSizeForControlSize( .Regular ) == fontHeight {
            preferredSize.height = max( preferredSize.height, standardRegularControlMenuItemHeight )
        }
        
        return preferredSize
    }
    
    /*==========================================================================*/
    override func applyFilterStatus( status: OBWFilteringMenuItemFilterStatus ) {
        
        super.applyFilterStatus( status )
        
        self.itemTitleField.attributedStringValue = self.attributedStringValue
        self.itemTitleField.needsDisplay = true
    }
    
    
    /*==========================================================================*/
    // MARK: - NSAccessibility implementation
    
    /*==========================================================================*/
    override func isAccessibilityElement() -> Bool {
        return true
    }
    
    /*==========================================================================*/
    override func accessibilityRole() -> String? {
        let itemHasSubmenu = ( self.menuItem.submenu != nil )
        return ( itemHasSubmenu ? NSAccessibilityPopUpButtonRole : NSAccessibilityButtonRole )
    }
    
    /*==========================================================================*/
    override func accessibilityRoleDescription() -> String? {
        guard let role = self.accessibilityRole() else { return nil }
        return NSAccessibilityRoleDescription( role, nil )
    }
    
    /*==========================================================================*/
    override func accessibilityParent() -> AnyObject? {
        guard let superview = self.superview else { return nil }
        return NSAccessibilityUnignoredAncestor( superview )
    }
    
    /*==========================================================================*/
    override func accessibilityValue() -> AnyObject? {
        return self.menuItem.title ?? nil
    }
    
    /*==========================================================================*/
    override func accessibilityValueDescription() -> String? {
        let itemHasSubmenu = ( self.menuItem.submenu != nil )
        return ( itemHasSubmenu ? super.accessibilityValueDescription() : self.menuItem.title ?? "" );
    }
    
    /*==========================================================================*/
    override func accessibilityChildren() -> [AnyObject]? {
        return []
    }
    
    /*==========================================================================*/
    override func isAccessibilityEnabled() -> Bool {
        return self.menuItem.enabled
    }
    
    /*==========================================================================*/
    override func isAccessibilityFocused() -> Bool {
        return self.menuItem.isHighlighted
    }
    
    /*==========================================================================*/
    override func accessibilityHelp() -> String? {
        
        let menuItem = self.menuItem
        
        if let menu = menuItem.menu {
            if let helpString = menu.delegate?.filteringMenu( menu, accessibilityHelpForItem: menuItem ) {
                return helpString
            }
        }
        
        guard let title = menuItem.title else { return nil }
        
        let itemWithoutSubmenuFormat = NSLocalizedString( "Click this button to select the %@ item", comment: "Filtering menu item (without submenu) accessibility help format" )
        let itemWithSubmenuFormat = NSLocalizedString( "Click this button to interact with the %@ item", comment: "Filtering menu item (with submenu) accessibility help format" )
        
        let format = menuItem.submenu == nil ? itemWithoutSubmenuFormat : itemWithSubmenuFormat
        
        return NSString( format: format, title ) as String
    }
    
    /*==========================================================================*/
    override func accessibilityPerformPress() -> Bool {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let userInfo = [ OBWFilteringMenuItemKey : self.menuItem ]
        notificationCenter.postNotificationName( OBWFilteringMenuAXDidOpenMenuItemNotification, object: self, userInfo: userInfo )
        return true
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuActionItemView internal
    
    /*==========================================================================*/
    static func titleOffsetForMenuItem( menuItem: OBWFilteringMenuItem ) -> NSSize {
        
        let interiorMargins = OBWFilteringMenuActionItemView.interiorMargins
        let imageMargins = OBWFilteringMenuActionItemView.imageMargins
        
        let menuItemSize = OBWFilteringMenuActionItemView.preferredSizeForMenuItem( menuItem )
        
        // Offset from top-left of item view to bottom-left of text field
        
        let imageSize = menuItem.image?.size ?? NSZeroSize
        let imageFrame = NSRect(
            x: interiorMargins.left + imageMargins.left,
            y: floor( ( menuItemSize.height - imageSize.height ) / 2.0 ),
            size: imageSize
        )
        
        let titleFrameOffsetY: CGFloat
        let attributedTitleLength = menuItem.attributedTitle?.length ?? 0
        if attributedTitleLength == 0 {
            
            let fontHeight = menuItem.font.pointSize
            
            if NSFont.systemFontSizeForControlSize( .Regular ) == fontHeight {
                // Special cases for standard Regular control font size
                titleFrameOffsetY = 1.0
            }
            else {
                titleFrameOffsetY = 0.0
            }
        }
        else {
            titleFrameOffsetY = 0.0
        }
        
        let titleSize = OBWFilteringMenuActionItemView.preferredViewSizeForTitleOfMenuItem( menuItem )
        let titleFrame = NSRect(
            x: ( imageFrame.size.width > 0.0 ? imageFrame.maxX + imageMargins.right : interiorMargins.left ),
            y: floor( ( menuItemSize.height - titleSize.height ) / 2.0 ) + titleFrameOffsetY,
            size: titleSize
        )
        
        let titleOffset = NSSize(
            width: titleFrame.origin.x,
            height: menuItemSize.height - titleFrame.maxY
        )
        
        return titleOffset
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuActionItemView private
    
    unowned private let itemTitleField: NSTextField
    unowned private let itemImageView: NSImageView
    unowned private let subviewArrowImageView: NSImageView
    
    private static let subviewArrowFrame = NSRect( width: 9.0, height: 10.0 )
    private static let interiorMargins = NSEdgeInsets( top: 0.0, left: 19.0, bottom: 0.0, right: 10.0 )
    private static let imageMargins = NSEdgeInsets( top: 2.0, left: 2.0, bottom: 2.0, right: 2.0 )
    private static let titleToSubmenuArrowSpacing: CGFloat = 37.0
    
    /*==========================================================================*/
    private var attributedStringValue: NSAttributedString {
        
        if let filterStatus = self.filterStatus {
            
            if !self.menuItem.isHighlighted {
                return filterStatus.highlightedTitle
            }
            
            let attributedString = NSMutableAttributedString( attributedString: filterStatus.highlightedTitle )
            let range = NSRange( location: 0, length: attributedString.length )
            attributedString.addAttribute( NSForegroundColorAttributeName, value: NSColor.whiteColor(), range: range )
            
            return attributedString
        }
        
        if let attributedStringValue = OBWFilteringMenuActionItemView.attributedTitleForMenuItem( self.menuItem ) {
            return attributedStringValue
        }
        
        return NSAttributedString()
    }
    
    /*==========================================================================*/
    private class func preferredViewSizeForTitleOfMenuItem( menuItem: OBWFilteringMenuItem ) -> NSSize {
        
        let titleSize = OBWFilteringMenuActionItemView.titleSizeForMenuItem( menuItem )
        
        // Left and right bearing is space that is added between the origin and the sides of the glyphs.  The amount present doesn't seem to be readily available.
        let horizontalPaddingToAccountForLeftAndRightBearing: CGFloat = 4.0
        
        var preferredViewSize = NSSize(
            
            width: ceil( titleSize.width + horizontalPaddingToAccountForLeftAndRightBearing ),
            
            // This formula was determined by comparing the standard control text heights to the standard-size menu item heights and determining the best-fit, straight-line relationship.
            height: round( 0.9737 * titleSize.height + 1.7105 )
        )
        
        // Above about font size 65.0, the above formula yields a height that is smaller than the title bounds.  Use the bounds when that happens.
        preferredViewSize.height = max( preferredViewSize.height, ceil( titleSize.height ) )
        
        return preferredViewSize
    }
    
    /*==========================================================================*/
    private class func titleSizeForMenuItem( menuItem: OBWFilteringMenuItem ) -> NSSize {
        return OBWFilteringMenuActionItemView.attributedTitleForMenuItem( menuItem )?.size() ?? NSZeroSize
    }
    
    /*==========================================================================*/
    private class func attributedTitleForMenuItem( menuItem: OBWFilteringMenuItem ) -> NSAttributedString? {
        
        let attributedTitle: NSMutableAttributedString
        
        if menuItem.attributedTitle?.length > 0 {
            attributedTitle = menuItem.attributedTitle!.mutableCopy() as! NSMutableAttributedString
        }
        else {
            
            guard let itemTitle = menuItem.title else { return nil }
            
            let fontAttribute = [ NSFontAttributeName : menuItem.font ]
            attributedTitle = NSMutableAttributedString( string: itemTitle, attributes: fontAttribute )
        }
        
        let range = NSRange( location: 0, length: attributedTitle.length )
        
        let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.lineBreakMode = .ByTruncatingTail
        
        let paragraphAttribute = [ NSParagraphStyleAttributeName : paragraphStyle ]
        attributedTitle.addAttributes( paragraphAttribute, range: range )
        
        if menuItem.isHighlighted {
            let colorAttribute = [ NSForegroundColorAttributeName : NSColor.selectedMenuItemTextColor() ]
            attributedTitle.addAttributes( colorAttribute, range: range )
        }
        
        return attributedTitle.copy() as? NSAttributedString
    }
    
    /*==========================================================================*/
    @objc private func highlightedItemDidChange( notification: NSNotification ) {
        
        guard let userInfo = notification.userInfo else { return }
        
        let oldItem = userInfo[OBWFilteringMenu.previousHighlightedItemKey] as? OBWFilteringMenuItem
        let newItem = userInfo[OBWFilteringMenu.currentHighlightedItemKey] as? OBWFilteringMenuItem
        
        let menuItem = self.menuItem
        
        if menuItem === oldItem {
            self.subviewArrowImageView.image = OBWFilteringMenuArrows.blackRightArrow
        }
        else if menuItem === newItem {
            self.subviewArrowImageView.image = OBWFilteringMenuArrows.whiteRightArrow
        }
        else {
            return
        }
        
        self.itemTitleField.attributedStringValue = self.attributedStringValue
        self.needsDisplay = true
    }
}
