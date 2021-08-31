/*===========================================================================
OBWFilteringMenuDebugWindow.swift
Silversides
Copyright (c) 2019 OrderedBytes. All rights reserved.
===========================================================================*/

import AppKit

/// A window for debug drawing over the screen contents.
class OBWFilteringMenuDebugWindow: NSWindow {
	/// Initialization of the debug window.
	init() {
		let screenFrame = NSScreen.screens.first?.frame ?? .zero
		let drawingView = OBWFilteringMenuDebugView(frame: screenFrame)
		self.drawingView = drawingView
		
		super.init(contentRect: screenFrame, styleMask: .borderless, backing: .buffered, defer: false)
		
		self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) - 10)
		self.isOpaque = false
		self.backgroundColor = NSColor.clear
		self.hasShadow = false
		self.ignoresMouseEvents = true
		self.acceptsMouseMovedEvents = false
		self.isReleasedWhenClosed = false
		self.animationBehavior = .none
		
		self.contentView?.addSubview(drawingView)
	}
	
	
	// MARK: - OBWFilteringMenuDebugWindow Interface
	
	/// The shared instance, creating it if necessary.
	static var shared = OBWFilteringMenuDebugWindow()
	
	/// Prepares the shared debug window for drawing.  Drawing occurs in screen
	/// coordinates.
	static func prepare(for screen: NSScreen?) {
		// Resize the window to fit the entire screen
		let frameInScreen = screen?.frame ?? .zero
		self.shared.setFrame(frameInScreen, display: true)
		
		// Resize the debug view to fit the entire window
		let frameInWindow = NSRect(origin: .zero, size: frameInScreen.size)
		self.shared.drawingView.frame = frameInWindow
		
		// Setup the coordinates of the debug view to match screen coordinates.
		self.shared.drawingView.bounds = frameInScreen
		
		self.shared.orderFront(nil)
	}
	
	/// Remove the window.
	static func orderOut(_ sender: Any?) {
		self.shared.orderOut(sender)
	}
	
	/// Add a new drawing handler.  The handler should perform drawing in the
	/// screen coordinate system.
	///
	/// - Parameter handler: The drawing handler to remove.
	///
	/// - Returns: A unique identifier that can be used to remove the drawing
	/// handler.
	@discardableResult
	static func addDrawingHandler(_ handler: @escaping DrawingHandler) -> UUID? {
		return self.shared.drawingView.addDrawingHandler(handler)
	}
	
	/// Remove an existing drawing handler.
	///
	/// - Parameter identifier: An identifier identifying the drawing handler to
	/// removed.  This value is obtained from the `addDrawingHandler(_:)`
	/// function.
	static func removeDrawingHandler(withIdentifier identifier: UUID) {
		self.shared.drawingView.removeDrawingHandler(withIdentifier: identifier)
	}
	
	/// Remove all drawing handlers
	static func removeAllDrawingHandlers() {
		self.shared.drawingView.removeAllDrawingHandlers()
	}
	
	/// Redisplay the window.
	static func displayNow() {
		self.shared.drawingView.needsDisplay = true
		self.shared.display()
	}
	
	
	// MARK: - Private
	
	private unowned let drawingView: OBWFilteringMenuDebugView
}
