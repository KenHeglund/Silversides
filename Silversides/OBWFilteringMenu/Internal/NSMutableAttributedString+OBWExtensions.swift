/*===========================================================================
 NSImage+OBWExtension.swift
 Silversides
 Copyright (c) 2021 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit

extension NSMutableAttributedString {
	/// Adds the Bold font trait to the fonts in the given range of the
	/// receiver.
	///
	/// - Parameter range: The range to which to add the Bold font trait.
	func addBoldFontTrait(to range: NSRange) {
		self.enumerateAttribute(.font, in: range, options: []) { (value, range, _) in
			guard let font = value as? NSFont else {
				return
			}
			
			let fontWithBold = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
			self.addAttribute(.font, value: fontWithBold, range: range)
		}
	}
	
	/// Removes the Bold font trait from the fonts in the given range of the
	/// receiver.
	///
	/// - Parameter range: The range from which to remove the Bold font trait.
	func removeBoldFontTrait(from range: NSRange) {
		self.enumerateAttribute(.font, in: range, options: []) { (value, range, _) in
			guard let font = value as? NSFont else {
				return
			}
			
			let fontWithoutBold = NSFontManager.shared.convert(font, toNotHaveTrait: .boldFontMask)
			self.addAttribute(.font, value: fontWithoutBold, range: range)
		}
	}
	
	/// Applies an `NSColor` system effect to the foreground color of text in
	/// the given range.  This function has no effect on ranges in the receiver
	/// that do not have a `.foregroundColor` attribute.
	///
	/// - Parameters:
	///   - systemEffect: The system effect to apply.
	///   - range: The range to apply `systemEffect` to.
	func applySystemEffect(_ systemEffect: NSColor.SystemEffect, to range: NSRange) {
		self.enumerateAttribute(.foregroundColor, in: range, options: []) { (value, range, _) in
			guard let color = value as? NSColor else {
				return
			}
			
			let adjustedColor = color.withSystemEffect(systemEffect)
			self.addAttribute(.foregroundColor, value: adjustedColor, range: range)
		}
	}
}
