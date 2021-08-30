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
	static var shared: OBWFilteringMenuDebugWindow = {
		let shared = OBWFilteringMenuDebugWindow()
		OBWFilteringMenuDebugWindow.sharedOrNil = shared
		return shared
	}()
	
	/// The shared instance, if it exists.
	static private(set) var sharedOrNil: OBWFilteringMenuDebugWindow?
	
	/// Bring the window forward.
	static func orderFront(_ sender: Any?) {
		self.sharedOrNil?.orderFront(sender)
	}
	
	/// Remove the window.
	static func orderOut(_ sender: Any?) {
		self.sharedOrNil?.orderOut(sender)
	}
	
	/// Add a new drawing handler.
	///
	/// - Parameter handler: The drawing handler to remove.
	///
	/// - Returns: A unique identifier that can be used to remove the drawing
	/// handler.
	@discardableResult
	static func addDrawingHandler(_ handler: @escaping DrawingHandler) -> UUID? {
		return self.sharedOrNil?.drawingView.addDrawingHandler(handler)
	}
	
	/// Remove an existing drawing handler.
	///
	/// - Parameter identifier: An identifier identifying the drawing handler to
	/// removed.  This value is obtained from the `addDrawingHandler(_:)`
	/// function.
	static func removeDrawingHandler(withIdentifier identifier: UUID) {
		self.sharedOrNil?.drawingView.removeDrawingHandler(withIdentifier: identifier)
	}
	
	/// Remove all drawing handlers
	static func removeAllDrawingHandlers() {
		self.sharedOrNil?.drawingView.removeAllDrawingHandlers()
	}
	
	/// Redisplay the window.
	static func displayNow() {
		self.sharedOrNil?.drawingView.needsDisplay = true
		self.sharedOrNil?.display()
	}
	
	
	// MARK: - Private
	
	private unowned let drawingView: OBWFilteringMenuDebugView
}
