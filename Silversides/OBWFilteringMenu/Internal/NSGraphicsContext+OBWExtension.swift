/*===========================================================================
NSGraphicsContext+OBWExtension.swift
OBWControls
Copyright (c) 2019 OrderedBytes. All rights reserved.
===========================================================================*/

import AppKit

extension NSGraphicsContext {
	/// Executes a closure with a saved graphics state.  The graphics state is
	/// restored before returning.
	///
	/// - Parameter handler: The closure to execute with a saved graphics state.
	static func withSavedGraphicsState( _ handler: () -> Void ) {
		NSGraphicsContext.saveGraphicsState()
		handler()
		NSGraphicsContext.restoreGraphicsState()
	}
}
