/*===========================================================================
 OBWFilteringMenuItemTitleField.swift
 OBWControls
 Copyright (c) 2019 OrderedBytes. All rights reserved.
 ===========================================================================*/

import AppKit
import OSLog

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
			os_signpost(.begin, log: .filteringMenuLogger, name: "Apply.ApplyToItems.UpdateAttributedString", signpostID: .filteringSignpostID, "")
			self.updateAttributedStringValue()
			os_signpost(.end, log: .filteringMenuLogger, name: "Apply.ApplyToItems.UpdateAttributedString", signpostID: .filteringSignpostID, "")
			
			os_signpost(.begin, log: .filteringMenuLogger, name: "Apply.ApplyToItems.SizeToFit", signpostID: .filteringSignpostID, "")
			self.sizeToFit()
			os_signpost(.end, log: .filteringMenuLogger, name: "Apply.ApplyToItems.SizeToFit", signpostID: .filteringSignpostID, "")
		}
	}
	
	
	// MARK: - Private
	
	/// The menu item containing the title to display.
	private let menuItem: OBWFilteringMenuItem
	
	/// Updates the title field’s attributed string value.
	private func updateAttributedStringValue() {
		guard let filterStatus = self.filterStatus else {
			let attributedTitle = OBWFilteringMenuItemTitleField.attributedTitle(for: self.menuItem)
			if self.menuItem.isHeadingItem || self.menuItem.enabled {
				self.attributedStringValue = attributedTitle
			}
			else {
				self.attributedStringValue = attributedTitle.applying(systemEffect: .disabled)
			}
			return
		}
		
		let attributedTitle = NSMutableAttributedString(attributedString: self.basicAttributedTitle)
		let matchingAttributedTitle = NSMutableAttributedString(attributedString: self.matchingAttributedTitle)
		let nonMatchingAttributedTitle = NSMutableAttributedString(attributedString: self.nonMatchingAttributedTitle)
		let entireRange = NSRange(location: 0, length: attributedTitle.length)
		
		if menuItem.isHeadingItem {
			attributedTitle.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: entireRange)
			matchingAttributedTitle.addAttribute(.foregroundColor, value: NSColor.labelColor, range: entireRange)
			nonMatchingAttributedTitle.addAttribute(.foregroundColor, value: NSColor.labelColor.withSystemEffect(.disabled), range: entireRange)
		}
		else if menuItem.isHighlighted {
			attributedTitle.addAttribute(.foregroundColor, value: NSColor.selectedMenuItemTextColor, range: entireRange)
			matchingAttributedTitle.addAttribute(.foregroundColor, value: NSColor.selectedMenuItemTextColor, range: entireRange)
			nonMatchingAttributedTitle.addAttribute(.foregroundColor, value: NSColor.selectedMenuItemTextColor.withSystemEffect(.disabled), range: entireRange)
		}
		else {
			attributedTitle.addAttribute(.foregroundColor, value: NSColor.labelColor, range: entireRange)
			matchingAttributedTitle.addAttribute(.foregroundColor, value: NSColor.labelColor, range: entireRange)
			nonMatchingAttributedTitle.addAttribute(.foregroundColor, value: NSColor.labelColor.withSystemEffect(.disabled), range: entireRange)
		}
		
		guard let annotatedTitle = filterStatus.annotatedTitle else {
			self.attributedStringValue = NSAttributedString(attributedString: attributedTitle)
			return
		}
		
		guard attributedTitle.string == annotatedTitle.string else {
			assertionFailure("Expected “\(attributedTitle.string)” to be identical to “\(annotatedTitle.string)”")
			self.attributedStringValue = attributedTitle
			return
		}
		
		let attributedStringValue = NSMutableAttributedString(attributedString: attributedTitle)
		
		annotatedTitle.enumerateAttribute(.filterMatch, in: entireRange, options: []) { (value, range, stopPtr) in
			if let value = value as? Bool, value {
				let matchingSubstring = matchingAttributedTitle.attributedSubstring(from: range)
				attributedStringValue.replaceCharacters(in: range, with: matchingSubstring)
			}
			else {
				let nonmatchingSubstring = nonMatchingAttributedTitle.attributedSubstring(from: range)
				attributedStringValue.replaceCharacters(in: range, with: nonmatchingSubstring)
			}
		}
		
		self.attributedStringValue = NSAttributedString(attributedString: attributedStringValue)
	}
	
	private lazy var basicAttributedTitle: NSAttributedString = {
		if let itemAttributedTitle = self.menuItem.attributedTitle, itemAttributedTitle.length > 0 {
			return itemAttributedTitle
		}
		
		guard let itemTitle = self.menuItem.title, !itemTitle.isEmpty else {
			return NSAttributedString()
		}
		
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.setParagraphStyle(.default)
		paragraphStyle.lineBreakMode = .byTruncatingTail
		
		let attributes: [NSAttributedString.Key: Any] = [
			.font : self.menuItem.font,
			.paragraphStyle : paragraphStyle,
		]
		
		return NSAttributedString(string: itemTitle, attributes: attributes)
	}()
	
	private lazy var matchingAttributedTitle: NSAttributedString = {
		let title = NSMutableAttributedString(attributedString: self.basicAttributedTitle)
		let range = NSRange(location: 0, length: title.string.count)
		title.addBoldFontTrait(to: range)
		title.addAttribute(.foregroundColor, value: NSColor.labelColor, range: range)
		return NSAttributedString(attributedString: title)
	}()
	
	private lazy var nonMatchingAttributedTitle: NSAttributedString = {
		let title = NSMutableAttributedString(attributedString: self.basicAttributedTitle)
		let range = NSRange(location: 0, length: title.string.count)
		title.removeBoldFontTrait(from: range)
		title.applySystemEffect(.disabled, to: range)
		return NSAttributedString(attributedString: title)
	}()
	
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
		if menuItem.isHeadingItem {
			foregroundColor = .secondaryLabelColor
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
