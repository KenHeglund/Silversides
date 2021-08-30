/*===========================================================================
OBWFilteringMenuDebugView.swift
Silversides
Copyright (c) 2019 OrderedBytes. All rights reserved.
===========================================================================*/

import AppKit

typealias DrawingHandler = (NSView) -> Void

/// A window for debug drawing over the screen contents.
class OBWFilteringMenuDebugView: NSView {
	/// Invoke the drawing handlers.
	override func draw(_ dirtyRect: NSRect) {
		NSColor.clear.set()
		self.bounds.fill()
		
		for (_, handler) in self.drawingHandlers {
			handler(self)
		}
	}
	
	
	// MARK: - OBWFilteringMenuDebugView Interface
	
	/// Add a new drawing handler.
	///
	/// - Parameter handler: The drawing handler to add.
	///
	/// - Returns: A unique identifier that can be used to remove the drawing
	/// handler.
	@discardableResult
	func addDrawingHandler(_ handler: @escaping DrawingHandler) -> UUID {
		let uuid = UUID()
		self.drawingHandlers[uuid] = handler
		self.needsDisplay = true
		print("add: \(self.drawingHandlers.keys)")
		return uuid
	}
	
	/// Remove an existing drawing handler.
	///
	/// - Parameter identifier: An identifier identifying the drawing handler to
	/// removed.  This value is obtained from the `addDrawingHandler(_:)`
	/// function.
	func removeDrawingHandler(withIdentifier identifier: UUID) {
		self.drawingHandlers[identifier] = nil
		self.needsDisplay = true
		print("remove: \(self.drawingHandlers.keys)")
	}
	
	/// Remove all drawing handlers
	func removeAllDrawingHandlers() {
		self.drawingHandlers = [:]
		self.needsDisplay = true
		print("removeAll: \(self.drawingHandlers.keys)")
	}
	
	
	// MARK: - Private
	
	private var drawingHandlers: [UUID: DrawingHandler] = [:]
}
