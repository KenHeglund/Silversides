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
		let attributedTitle = OBWFilteringMenuItemTitleField.attributedTitle(for: self.menuItem)
		
		guard let annotatedTitle = self.filterStatus?.annotatedTitle else {
			if self.menuItem.enabled {
				self.attributedStringValue = attributedTitle
			}
			else {
				self.attributedStringValue = attributedTitle.applying(systemEffect: .disabled)
			}
			return
		}
		
		guard attributedTitle.string == annotatedTitle.string else {
			assertionFailure("Expected “\(attributedTitle.string)” to be identical to “\(annotatedTitle.string)”")
			self.attributedStringValue = attributedTitle
			return
		}
		
		let attributedStringValue = NSMutableAttributedString(attributedString: attributedTitle)
		let entireRange = NSRange(location: 0, length: attributedStringValue.length)
		
		annotatedTitle.enumerateAttribute(.filterMatch, in: entireRange, options: []) { (value, range, stopPtr) in
			if let value = value as? Bool, value {
				attributedStringValue.addMatchingAttributes(in: range)
			}
			else {
				attributedStringValue.addNonmatchingAttributes(in: range)
			}
		}
		
		self.attributedStringValue = NSAttributedString(attributedString: attributedStringValue)
	}
	
	/// Builds an attributed string for the given menu item’s title.
	///
	/// - Parameter menuItem: The menu item to build the attributed title from.
	///
	/// - Returns: An attributed string containing the title of `menuItem`.
	class func attributedTitle(for menuItem: OBWFilteringMenuItem) -> NSAttributedString {
		if let itemAttributedTitle = menuItem.attributedTitle, itemAttributedTitle.length > 0 {
			return itemAttributedTitle
		}
		
		guard let itemTitle = menuItem.title, !itemTitle.isEmpty else {
			return NSAttributedString()
		}
		
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.setParagraphStyle(.default)
		paragraphStyle.lineBreakMode = .byTruncatingTail
		
		let foregroundColor: NSColor
		if menuItem.isHeadingItem || !menuItem.enabled {
			foregroundColor = .disabledControlTextColor
		}
		else if menuItem.isHighlighted {
			foregroundColor = .selectedMenuItemTextColor
		}
		else {
			foregroundColor = .labelColor
		}
		
		let attributes: [NSAttributedString.Key: Any] = [
			.font : menuItem.font,
			.foregroundColor : foregroundColor,
			.paragraphStyle : paragraphStyle,
		]
		
		return NSAttributedString(string: itemTitle, attributes: attributes)
	}
}

private extension NSMutableAttributedString {
	/// Adds attributes to the receiver that indicate the given range is a
	/// filter match.
	///
	/// - Parameter range: The portion of the receiver to add attributes to.
	func addMatchingAttributes(in range: NSRange) {
		self.addBoldFontTrait(to: range)
	}
	
	/// Adds attributes to the receiver that indicate the given range is not a
	/// filter match.
	///
	/// - Parameter range: The portion of the receiver to add attributes to.
	func addNonmatchingAttributes(in range: NSRange) {
		self.removeBoldFontTrait(from: range)
		
		self.enumerateAttribute(.foregroundColor, in: range, options: []) { (value, range, stopPtr) in
			let dimmedColor: NSColor
			if let color = value as? NSColor {
				dimmedColor = color.withSystemEffect(.disabled)
			}
			else {
				assertionFailure("Not expecting to fail to find a foreground color")
				dimmedColor = NSColor.systemRed.withSystemEffect(.disabled)
			}
			self.addAttribute(.foregroundColor, value: dimmedColor, range: range)
		}
	}
}
