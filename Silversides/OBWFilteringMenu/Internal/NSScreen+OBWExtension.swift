/*===========================================================================
NSScreen+OBWExtension.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

extension NSScreen {
	/// Returns the screen containing the given location.
	///
	/// - Parameter locationInScreen: The location in screen coordinates to find
	/// the enclosing screen of.
	///
	/// - Returns: The screen containing `locationInScreen`, or `nil` if no
	/// screen contains `locationInScreen`.
	class func screenContainingLocation(_ locationInScreen: NSPoint) -> NSScreen? {
		return self.screens.first(where: {
			NSPointInRect(locationInScreen, $0.frame)
		})
	}
}
