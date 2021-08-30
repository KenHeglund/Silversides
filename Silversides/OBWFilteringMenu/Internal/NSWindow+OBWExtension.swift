/*===========================================================================
NSWindow+OBWExtension.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

extension NSWindow {
	/// Converts the given point from the receiver’s coordinate system to screen
	/// coordinates.
	///
	/// - Parameter locationInWindow: A location in the receiver’s coordinate
	/// system.
	///
	/// - Returns: `locationInWindow` converted to screen coordinates.
	func convertToScreen(_ locationInWindow: NSPoint) -> NSPoint {
		let rectInWindow = NSRect(origin: locationInWindow, size: .zero)
		let rectInScreen = self.convertToScreen(rectInWindow)
		return rectInScreen.origin
	}
	
	/// Convert the given point from screen coordinates to the recevier’s
	/// coordinate system.
	///
	/// - Parameter locationInScreen: A location in screen coordinates.
	///
	/// - Returns: `locationInScreen` converted to the receiver’s coordinate
	/// system.
	func convertFromScreen(_ locationInScreen: NSPoint) -> NSPoint {
		let rectInScreen = NSRect(origin: locationInScreen, size: .zero)
		let rectInWindow = self.convertFromScreen(rectInScreen)
		return rectInWindow.origin
	}
}
