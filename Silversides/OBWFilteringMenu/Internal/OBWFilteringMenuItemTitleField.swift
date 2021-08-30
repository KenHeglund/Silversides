//
//  OBWFilteringMenuItemTitleField.swift
//  OBWControls
//
//  Created by Ken Heglund on 7/27/19.
//  Copyright © 2019 OrderedBytes. All rights reserved.
//

import AppKit

/// An `NSTextField` subclass that displays a menu item title.
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
	
	// Required initializer.
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override var needsDisplay: Bool {
		didSet {
			self.updateAttributedStringValue()
		}
	}
	
	
	// MARK: - OBWFilteringMenuItemTitleField implementation
	
	/// The current filter status of the menu item.
	var filterStatus: OBWFilteringMenuItemFilterStatus? {
		didSet {
			self.updateAttributedStringValue()
			self.sizeToFit()
		}
	}
	
	
	// MARK: - Private
	
	/// The menu item containing the title to display.
	private let menuItem: OBWFilteringMenuItem
	
	/// Updates the title field’s attributed string value.
	private func updateAttributedStringValue() {
		let attributedStringValue: NSMutableAttributedString
		if let filterStatus = self.filterStatus {
			attributedStringValue = NSMutableAttributedString(attributedString: filterStatus.highlightedTitle)
		}
		else if let title = OBWFilteringMenuItemTitleField.attributedTitle(for: self.menuItem) {
			attributedStringValue = NSMutableAttributedString(attributedString: title)
		}
		else {
			attributedStringValue = NSMutableAttributedString()
		}
		
		if attributedStringValue.attribute(.foregroundColor, at: 0, effectiveRange: nil) == nil {
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
			
			let range = NSMakeRange(0, attributedStringValue.length)
			attributedStringValue.addAttribute(.foregroundColor, value: foregroundColor, range: range)
		}
		
		self.attributedStringValue = NSAttributedString(attributedString: attributedStringValue)
	}
	
	/// Builds an attributed string for the given menu item’s title.
	///
	/// - Parameter menuItem: The menu item to build the attributed title from.
	///
	/// - Returns: An attributed string containing the title of `menuItem`.
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
		
		let attributes: [NSAttributedString.Key: Any] = [
			.font : menuItem.font,
			.paragraphStyle : paragraphStyle,
		]
		
		return NSAttributedString(string: itemTitle, attributes: attributes)
	}
}
