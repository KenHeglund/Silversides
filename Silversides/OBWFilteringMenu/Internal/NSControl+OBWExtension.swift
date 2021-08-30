/*===========================================================================
NSControl+OBWExtension.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

extension NSControl {
	/// Returns a control size for the given font point size.
	///
	/// - Parameter fontPointSize: The font point size to find the control size
	/// for.
	///
	/// - Returns: A control size that is appropriate for a font with the given
	/// point size.
	class func controlSizeForFontSize(_ fontPointSize: CGFloat) -> NSControl.ControlSize {
		if fontPointSize <= NSFont.systemFontSize(for: .mini) {
			return .mini
		}
		if fontPointSize <= NSFont.systemFontSize(for: .small) {
			return .small
		}
		
		return .regular
	}
}
