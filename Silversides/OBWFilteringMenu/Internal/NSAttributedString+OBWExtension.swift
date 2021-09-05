/*===========================================================================
NSAttributedString+OBWExtension.swift
OBWControls
Copyright (c) 2021 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

extension NSAttributedString {
	/// Constructs a new `NSAttributedString` by modifying the colors in the
	/// receiver to apply the given system effect.
	///
	/// - Parameter systemEffect: The effect to apply to the existing colors.
	///
	/// - Returns: A new `NSAttributedString`.
	func applying(systemEffect: NSColor.SystemEffect) -> NSAttributedString {
		let entireRange = NSRange(location: 0, length: self.length)
		
		let attributedString = NSMutableAttributedString(attributedString: self)
		attributedString.enumerateAttribute(.foregroundColor, in: entireRange, options: []) { (value, range, stopPtr) in
			guard let color = value as? NSColor else {
				return
			}
			
			let modifiedColor = color.withSystemEffect(systemEffect)
			attributedString.addAttribute(.foregroundColor, value: modifiedColor, range: range)
		}
		
		return NSAttributedString(attributedString: attributedString)
	}
}
