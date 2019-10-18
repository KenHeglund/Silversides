//
//  OBWFilteringMenuItemTitleField.swift
//  OBWControls
//
//  Created by Ken Heglund on 7/27/19.
//  Copyright © 2019 OrderedBytes. All rights reserved.
//

import AppKit

class OBWFilteringMenuItemTitleField: NSTextField {
    
    /// Designated initializer.
    init(_ menuItem: OBWFilteringMenuItem) {
        
        self.menuItem = menuItem
        
        super.init(frame: .zero)
        
        self.isEditable = false
        self.isSelectable = false
        self.isBezeled = false
        self.cell?.lineBreakMode = .byClipping
        self.alphaValue = (self.menuItem.enabled && !self.menuItem.isHeadingItem ? 1.0 : 0.35)
        
        #if DEBUG_MENU_TINTING
        self.drawsBackground = true
        self.backgroundColor = NSColor.systemRed.withAlphaComponent(0.15)
        #else
        self.drawsBackground = true
        self.backgroundColor = .clear
        #endif
        
        self.updateAttributedStringValue()
        self.sizeToFit()
    }
    
    /// Required initializer, currently unused.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - OBWFilteringMenuItemTitleField implementation
    
    /// The current filter status of the menu item.
    var filterStatus: OBWFilteringMenuItemFilterStatus? = nil {
        didSet {
            self.updateAttributedStringValue()
            self.sizeToFit()
        }
    }
    
    
    // MARK: - Private
    
    private let menuItem: OBWFilteringMenuItem
    
    /// Updates the title field's attributed string value.
    private func updateAttributedStringValue() {
        
        if let filterStatus = self.filterStatus {
            self.attributedStringValue = filterStatus.highlightedTitle
        }
        else if let title = OBWFilteringMenuItemTitleField.attributedTitle(for: self.menuItem) {
            self.attributedStringValue = title
        }
        else {
            self.attributedStringValue = NSAttributedString()
        }
    }
    
    /// Builds an attributed string for the given menu item's title.
    class func attributedTitle(for menuItem: OBWFilteringMenuItem) -> NSAttributedString? {
        
        if let itemAttributedTitle = menuItem.attributedTitle, itemAttributedTitle.length > 0 {
            return itemAttributedTitle
        }
        
        guard let itemTitle = menuItem.title, !itemTitle.isEmpty else {
            return nil
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.setParagraphStyle(NSParagraphStyle.default)
        paragraphStyle.lineBreakMode = .byTruncatingTail
        
        let foregroundColor: NSColor
        if menuItem.isHeadingItem || !menuItem.enabled {
            foregroundColor = .labelColor
        }
        else if menuItem.isHighlighted {
            foregroundColor = .selectedMenuItemTextColor
        }
        else {
            foregroundColor = .labelColor
        }
        
        let attributes: [NSAttributedString.Key:Any] = [
            .font : menuItem.font,
            .paragraphStyle : paragraphStyle,
            .foregroundColor : foregroundColor,
        ]
        
        return NSAttributedString(string: itemTitle, attributes: attributes)
    }

}
