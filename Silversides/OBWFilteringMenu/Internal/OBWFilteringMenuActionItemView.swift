/*===========================================================================
 OBWFilteringMenuActionItemView.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit

/// A view that hosts an OBWFilteringMenuItem.
class OBWFilteringMenuActionItemView: OBWFilteringMenuItemView {
    
    /// Initialize the view from the menu item that it will host.
    override init(menuItem: OBWFilteringMenuItem) {
        
        assert(menuItem.isSeparatorItem == false)
        
        self.submenuArrowImageView = OBWFilteringMenuSubmenuImageView(menuItem)
        self.itemTitleField = OBWFilteringMenuItemTitleField(menuItem)
        
        super.init(menuItem: menuItem)
        
        self.addSubview(self.itemTitleField)
        self.addSubview(self.itemImageView)
        self.addSubview(self.submenuArrowImageView)
        self.addSubview(self.stateImageView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(OBWFilteringMenuActionItemView.highlightedItemDidChange(_:)), name: OBWFilteringMenu.highlightedItemDidChangeNotification, object: nil)
        
        self.itemImageView.image = menuItem.image
        self.itemImageView.isHidden = (menuItem.image == nil)
        self.itemImageView.isEnabled = menuItem.enabled && !menuItem.isHeadingItem
    }
    
    /// Required initializer, currently unused.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Clean up.
    deinit {
        NotificationCenter.default.removeObserver(self, name: OBWFilteringMenu.highlightedItemDidChangeNotification, object: nil)
    }
    
    
    // MARK: - NSView overrides
    
    /// Resize and reposition the view's subviews.
    override func resizeSubviews(withOldSize _: NSSize) {
        
        let contentBounds = self.bounds + OBWFilteringMenuActionItemView.interiorMargins
        let imageMargins = OBWFilteringMenuActionItemView.imageMargins
        
        let indentation = CGFloat(self.menuItem.indentationLevel) * OBWFilteringMenuActionItemView.indentDistancePerLevel
        
        let imageSize = self.menuItem.image?.size ?? NSZeroSize
        let imageFrame = NSRect(
            x: contentBounds.minX + indentation + imageMargins.left,
            y: floor(contentBounds.midY - (imageSize.height / 2.0)),
            size: imageSize
        )
        
        let titleSize = OBWFilteringMenuActionItemView.preferredTitleTextFieldSize(for: self.menuItem)
        let titleFrame = NSRect(
            x: (imageFrame.width > 0 ? imageFrame.maxX + imageMargins.right : contentBounds.minX + indentation),
            y: floor(contentBounds.midY - (titleSize.height / 2.0)),
            size: titleSize
        )
        
        self.itemImageView.frame = imageFrame
        self.itemTitleField.frame = titleFrame
        
        let arrowImageSize = self.submenuArrowImageView.frame.size
        let arrowImageOrigin = NSPoint(
            x: contentBounds.maxX - arrowImageSize.width,
            y: contentBounds.midY - floor(arrowImageSize.height / 2.0)
        )
        self.submenuArrowImageView.setFrameOrigin(arrowImageOrigin)
        
        let stateToTitleRatio: CGFloat = 0.6
        let stateImageSize = titleSize.height * stateToTitleRatio
        
        let stateImageFrame = NSRect(
            x: imageFrame.origin.x - OBWFilteringMenuActionItemView.statusImageRightMargin - stateImageSize,
            y: titleFrame.origin.y + ((titleSize.height - stateImageSize) / 2.0),
            width: stateImageSize,
            height: stateImageSize
        )
        
        self.stateImageView.frame = stateImageFrame
    }
    
    /// The view is about to be drawn.
    override func viewWillDraw() {
        super.viewWillDraw()
        self.updateStateImage()
    }
    
    /// Draw the view.
    override func draw(_ dirtyRect: NSRect) {
        
        #if DEBUG_MENU_TINTING
        NSColor.green.withAlphaComponent(0.1).set()
        self.bounds.fill()
        #endif

        if self.menuItem.isHighlighted == false {
            return
        }
        
        NSGraphicsContext.withSavedGraphicsState {
            
            let localOrigin = self.bounds.origin
            let originInWindow = self.convert(localOrigin, to: nil)
            
            NSGraphicsContext.current?.patternPhase = originInWindow
            
            if #available(macOS 10.14, *) {
                NSColor.selectedContentBackgroundColor.setFill()
            }
            else {
                NSColor.selectedMenuItemColor.setFill()
            }
            self.bounds.fill()
        }
    }
    
    /// Returns the first baseline offset of the title field adjusted to this view's coordinates.
    override var firstBaselineOffsetFromTop: CGFloat {
        return self.itemTitleField.firstBaselineOffsetFromTop + (self.bounds.maxY - self.itemTitleField.frame.maxY)
    }
    
    
    // MARK: - OBWFilteringMenuItemView overrides
    
    /// Calculate the preferred view size needed to draw the given menu item.
    override class func preferredSizeForMenuItem(_ menuItem: OBWFilteringMenuItem) -> NSSize {
        
        let interiorMargins = OBWFilteringMenuActionItemView.interiorMargins
        let imageMargins = OBWFilteringMenuActionItemView.imageMargins
        let submenuArrowSize = OBWFilteringMenuSubmenuImageView.size
        let titleToSubmenuArrowSpacing = OBWFilteringMenuActionItemView.titleToSubmenuArrowSpacing
        
        let imageSize: NSSize
        if let image = menuItem.image {
            imageSize = NSSize(
                width: image.size.width,
                height: image.size.height + imageMargins.height
            )
        }
        else {
            imageSize = .zero
        }
        
        let titleSize = OBWFilteringMenuActionItemView.preferredTitleTextFieldSize(for: menuItem)
        
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
            preferredSize.width += titleToSubmenuArrowSpacing + submenuArrowSize.width
        }
        
        preferredSize.height = max(imageSize.height, titleSize.height)
        preferredSize.height = max(preferredSize.height, submenuArrowSize.height)
        
        if menuItem.attributedTitle == nil {
        
            // Special cases for non-attributed titles with standard control font sizes
            let fontHeight = menuItem.font.pointSize
            
            let standardMiniControlMenuItemHeight: CGFloat = 13.0
            let standardSmallControlMenuItemHeight: CGFloat = 16.0
            let standardRegularControlMenuItemHeight: CGFloat = 18.0
            
            if NSFont.systemFontSize(for: .mini) == fontHeight {
                preferredSize.height = max(preferredSize.height, standardMiniControlMenuItemHeight)
            }
            else if NSFont.systemFontSize(for: .small) == fontHeight {
                preferredSize.height = max(preferredSize.height, standardSmallControlMenuItemHeight)
            }
            else if NSFont.systemFontSize(for: .regular) == fontHeight {
                preferredSize.height = max(preferredSize.height, standardRegularControlMenuItemHeight)
            }
        }
        
        let indentation = CGFloat(menuItem.indentationLevel) * OBWFilteringMenuActionItemView.indentDistancePerLevel
        preferredSize.width += indentation
        
        return preferredSize
    }
    
    /// Applies the given filter status to the view.
    override func applyFilterStatus(_ status: OBWFilteringMenuItemFilterStatus) {
        super.applyFilterStatus(status)
        self.itemTitleField.filterStatus = status
    }
    
    
    // MARK: - NSAccessibility implementation
    
    /// The view is accessible.
    override func isAccessibilityElement() -> Bool {
        return true
    }
    
    /// Returns the view's accessibility role based on whether or not it has a subview.
    override func accessibilityRole() -> NSAccessibility.Role? {
        let itemHasSubmenu = (self.menuItem.submenu != nil)
        return (itemHasSubmenu ? NSAccessibility.Role.popUpButton : NSAccessibility.Role.button)
    }
    
    /// Returns the standard description of the view's accessibility role.
    override func accessibilityRoleDescription() -> String? {
        
        guard let role = self.accessibilityRole() else {
            return nil
        }
        
        return role.description(with: nil )
    }
    
    /// Returns the accessibility parent of the view.
    override func accessibilityParent() -> Any? {
        
        guard let superview = self.superview else {
            return nil
        }
        
        return NSAccessibility.unignoredAncestor(of: superview)
    }
    
    /// Returns the accessibility value (the title) of the view.
    override func accessibilityValue() -> Any? {
        return self.menuItem.title ?? nil
    }
    
    /// Returns a description of the view's accessibility value.
    override func accessibilityValueDescription() -> String? {
        let itemHasSubmenu = (self.menuItem.submenu != nil)
        return (itemHasSubmenu ? super.accessibilityValueDescription() : self.menuItem.title ?? "");
    }
    
    /// Returns the view's accessibile children (an empty array).
    override func accessibilityChildren() -> [Any]? {
        return []
    }
    
    /// Returns whether accessibility is enabled on the view based on whether the menu item is enabled or not.
    override func isAccessibilityEnabled() -> Bool {
        return self.menuItem.enabled && !self.menuItem.isHeadingItem
    }
    
    /// Returns whether the view has accessibility focus.
    override func isAccessibilityFocused() -> Bool {
        return self.menuItem.isHighlighted
    }
    
    /// Returns accessibility help for the view.
    override func accessibilityHelp() -> String? {
        
        let menuItem = self.menuItem
        
        if let menu = menuItem.menu {
            if let helpString = menu.delegate?.filteringMenu(menu, accessibilityHelpForItem: menuItem) {
                return helpString
            }
        }
        
        guard let title = menuItem.title else {
            return nil
        }
        
        let itemWithoutSubmenuFormat = NSLocalizedString("Click this button to select the %@ item", comment: "Filtering menu item (without submenu) accessibility help format")
        let itemWithSubmenuFormat = NSLocalizedString("Click this button to interact with the %@ item", comment: "Filtering menu item (with submenu) accessibility help format")
        
        let format = menuItem.submenu == nil ? itemWithoutSubmenuFormat : itemWithSubmenuFormat
        
        return String.localizedStringWithFormat(format, title)
    }
    
    /// Responds to the user activating the view via accessibility.
    override func accessibilityPerformPress() -> Bool {
        let notificationCenter = NotificationCenter.default
        let userInfo: [OBWFilteringMenuController.Key:Any] = [.menuItem : self.menuItem]
        notificationCenter.post(name: OBWFilteringMenuController.axDidOpenMenuItemNotification, object: self, userInfo: userInfo)
        return true
    }
    
    
    // MARK: - Private
    
    /// The field that draws the menu item title.
    private let itemTitleField: OBWFilteringMenuItemTitleField
    
    /// The view that draws the menu item's image.
    private let itemImageView: NSImageView = {
        
        let itemImageSize = NSSize(width: 10.0, height: 10.0)
        let itemImageFrame = NSRect(size: itemImageSize)
        let itemImageView = NSImageView(frame: itemImageFrame)
        
        itemImageView.imageFrameStyle = .none
        itemImageView.isEditable = false
        
        return itemImageView
    }()
    
    /// The view that draws the submenu arrow.
    private let submenuArrowImageView: OBWFilteringMenuSubmenuImageView
    
    /// The view that draws the menu item state.
    private let stateImageView: NSImageView = {
        let stateImageView = NSImageView(frame: .zero)
        stateImageView.imageFrameStyle = .none
        stateImageView.isEditable = false
        return stateImageView
    }()
    
    /// Padding to the right of the status image.
    private static let statusImageRightMargin: CGFloat = 5.0
    
    /// Margins between the item image view and its contents.
    private static let interiorMargins = NSEdgeInsets(top: 0.0, left: 19.0, bottom: 0.0, right: 10.0)
    
    /// Margins around the icon image.
    private static let imageMargins = NSEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
    
    /// Padding between the title and the arrow indicating that there is a submenu.
    private static let titleToSubmenuArrowSpacing: CGFloat = 37.0
    
    /// The amount by which an item is indented for each indentation level.
    private static let indentDistancePerLevel: CGFloat = 12.0
    
    /// Calculates the preferred text field size for the given menu item.
    private class func preferredTitleTextFieldSize(for menuItem: OBWFilteringMenuItem) -> NSSize {
        
        let titleSize = OBWFilteringMenuItemTitleField.attributedTitle(for: menuItem)?.size() ?? .zero
        
        // Left and right bearing is space that is added between the origin and the sides of the glyphs.  The amount present doesn't seem to be readily available.
        let horizontalPaddingToAccountForLeftAndRightBearing: CGFloat = 4.0
        
        var preferredViewSize = NSSize(
            
            width: ceil(titleSize.width + horizontalPaddingToAccountForLeftAndRightBearing),
            
            // This formula was determined by comparing the standard control text heights to the standard-size menu item heights and determining the best-fit, straight-line relationship.
            height: round(0.9737 * titleSize.height + 1.7105)
        )
        
        // Above about font size 65.0, the above formula yields a height that is smaller than the title bounds.  Use the bounds when that happens.
        preferredViewSize.height = max(preferredViewSize.height, ceil(titleSize.height))
        
        return preferredViewSize
    }
    
    /// The menu's highlighted item changed.
    @objc private func highlightedItemDidChange(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo as? [OBWFilteringMenu.Key:Any] else {
            return
        }
        
        let oldItem = userInfo[.previousHighlightedItem] as? OBWFilteringMenuItem
        let newItem = userInfo[.currentHighlightedItem] as? OBWFilteringMenuItem
        
        guard self.menuItem === oldItem || self.menuItem === newItem else {
            return
        }
        
        self.itemTitleField.needsDisplay = true
        self.submenuArrowImageView.needsDisplay = true
        self.needsDisplay = true
    }
    
    /// Updates the view's state image (i.e. "checked", "mixed", or "none")
    private func updateStateImage() {
        
        guard let templateImage = self.menuItem.stateTemplateImage else {
            self.stateImageView.image = nil
            return
        }
        
        let stateImage = NSImage(size: templateImage.size)
        stateImage.withLockedFocus {
            
            NSAppearance.withAppearance(self.effectiveAppearance) {
                
                if self.menuItem.isHighlighted {
                    NSColor.selectedMenuItemTextColor.set()
                }
                else {
                    NSColor.labelColor.set()
                }
                
                NSRect(origin: .zero, size: templateImage.size).fill()
                
                templateImage.draw(at: .zero, from: .zero, operation: .destinationIn, fraction: 1.0)
            }
        }
        
        self.stateImageView.image = stateImage
    }
    
}
