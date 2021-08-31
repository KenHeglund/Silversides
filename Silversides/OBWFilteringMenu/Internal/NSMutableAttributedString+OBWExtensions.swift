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
		self.enumerateAttribute(.font, in: range, options: []) { (value, range, stopPtr) in
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
		self.enumerateAttribute(.font, in: range, options: []) { (value, range, stopPtr) in
			guard let font = value as? NSFont else {
				return
			}
			
			let fontWithoutBold = NSFontManager.shared.convert(font, toNotHaveTrait: .boldFontMask)
			self.addAttribute(.font, value: fontWithoutBold, range: range)
		}
	}
}
