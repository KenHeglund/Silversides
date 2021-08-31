/*===========================================================================
OBWFilteringMenuCursorTracking.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

/// A class to facilitate cursor tracking when the cursor is moving from a menu
/// item to its submenu.
class OBWFilteringMenuCursorTracking {
	/// Initialize tracking from the vertical line within the given menu item, to the area occupied by its submenu.
	///
	/// - Parameters:
	///   - menuItem: The menu item from which the cursor is moving.
	///   - sourceLine: The vertical line in screen coordinates that represents
	///   the limit in the “leading” direction that the cursor may move to and
	///   still be considered to be moving toward the submenu.
	///   - submenuArea: The rectangle in screen coordinates occupied by the
	///   menu item’s submenu.
	init(subviewOfItem menuItem: OBWFilteringMenuItem, fromSourceLine sourceLine: NSRect, toArea submenuArea: NSRect) {
		self.sourceMenuItem = menuItem
		self.destinationArea = submenuArea
		self.sourceLine = sourceLine
		
		self.recalculateLimitPath()
		self.resetWaypoints()
		
		#if DEBUG_CURSOR_TRACKING
		self.debugDrawingIdentifier = OBWFilteringMenuDebugWindow.addDrawingHandler({
			[weak self]
			view in
			
			guard let cursorTracking = self, let path = cursorTracking.cursorLimitPath else {
				return
			}
			
			NSColor.systemRed.withAlphaComponent(0.15).set()
			path.fill()
			
			NSColor.systemRed.withAlphaComponent(0.5).set()
			path.stroke()
		})
		
		OBWFilteringMenuDebugWindow.displayNow()
		#endif
	}
	
	/// Deinitialization.
	deinit {
		#if DEBUG_CURSOR_TRACKING
		if let drawingIdentifier = self.debugDrawingIdentifier {
			OBWFilteringMenuDebugWindow.removeDrawingHandler(withIdentifier: drawingIdentifier)
		}
		#endif
	}
	
	
	// MARK: - OBWFilteringMenuCursorTracking Interface
	
	/// The menu item where the cursor movement originated.
	unowned let sourceMenuItem: OBWFilteringMenuItem
	
	/// The line in screen coordinates that represents the limit in the
	/// “leading” direction that the cursor may move and still be considered to
	/// be moving toward the destination.
	var sourceLine: NSRect = .zero {
		didSet {
			self.recalculateLimitPath()
			self.resetWaypoints()
			
			#if DEBUG_CURSOR_TRACKING
			OBWFilteringMenuDebugWindow.displayNow()
			#endif
		}
	}
	
	/// Determines if the cursor is still making definite progress toward the
	/// destination.
	func isCursorProgressingTowardSubmenu(_ event: NSEvent) -> Bool {
		if let eventLocation = event.locationInScreen {
			if let path = self.cursorLimitPath {
				if path.contains(eventLocation) == false {
					return false
				}
				
				if self.isCursorMovingFastEnough(event.timestamp, locationInScreen: eventLocation) == false {
					return false
				}
			}
			
			self.previousCursorTimestamp = event.timestamp
		}
		else if let previousCursorTimestamp = self.previousCursorTimestamp {
			if event.timestamp - previousCursorTimestamp > OBWFilteringMenuCursorTracking.trackingInterval {
				return false
			}
		}
		
		return true
	}
	
	
	// MARK: - Private
	
	/// A struct that records a cursor position and time.
	private struct Waypoint {
		/// The time at which the cursor position was captured.
		let timestamp: TimeInterval
		/// The location in screen coordinates of the cursor.
		let locationInScreen: NSPoint
	}
	
	/// The maximum interval between cursor positions.
	private static let trackingInterval = 0.10
	
	/// The minumum speed in point per second that the cursor must move to be
	/// considered “fast enough”.
	private static let minimumSpeed = 10.0
	
	/// The destination of the cursor in screen coordinates.
	private let destinationArea: NSRect
	
	/// The most recent time at which the cusor position was captured.
	private var previousCursorTimestamp: TimeInterval?
	
	/// An array of recent cursor positions and timestamps.
	private var cursorWaypoints: [Waypoint] = []
	
	/// The path that defines the region in which the cursor may move to be
	/// considered as moving toward the destination submenu.
	private var cursorLimitPath: NSBezierPath?
	
	/// Identifier for the debug drawing handler.
	private var debugDrawingIdentifier: UUID?
	
	/// Recalculates the limit path.
	private func recalculateLimitPath() {
		let sourceLine = self.sourceLine
		let destinationArea = self.destinationArea
		
		if sourceLine.minX < destinationArea.minX {
			
			let leadingEdge = self.sourceLine.insetBy(dx: -2.0, dy: -6.0)
			let trailingEdge = self.destinationArea.insetBy(dx: 0.0, dy: -40.0)
			
			let path = NSBezierPath()
			path.move(to: NSPoint(x: leadingEdge.minX, y: leadingEdge.minY))
			path.line(to: NSPoint(x: trailingEdge.minX, y: trailingEdge.minY))
			path.line(to: NSPoint(x: trailingEdge.maxX, y: trailingEdge.minY))
			path.line(to: NSPoint(x: trailingEdge.maxX, y: trailingEdge.maxY))
			path.line(to: NSPoint(x: trailingEdge.minX, y: trailingEdge.maxY))
			path.line(to: NSPoint(x: leadingEdge.minX, y: leadingEdge.maxY))
			path.close()
			
			self.cursorLimitPath = path
		}
		else if sourceLine.minX > destinationArea.maxX {
			
			let leadingEdge = self.sourceLine.insetBy(dx: -2.0, dy: -6.0)
			let trailingEdge = self.destinationArea.insetBy(dx: 0.0, dy: -40.0)
			
			let path = NSBezierPath()
			path.move(to: NSPoint(x: trailingEdge.minX, y: trailingEdge.minY))
			path.line(to: NSPoint(x: trailingEdge.maxX, y: trailingEdge.minY))
			path.line(to: NSPoint(x: leadingEdge.maxX, y: leadingEdge.minY))
			path.line(to: NSPoint(x: leadingEdge.maxX, y: leadingEdge.maxY))
			path.line(to: NSPoint(x: trailingEdge.maxX, y: trailingEdge.maxY))
			path.line(to: NSPoint(x: trailingEdge.minX, y: trailingEdge.maxY))
			path.close()
			
			self.cursorLimitPath = path
		}
		else {
			
			self.cursorLimitPath = nil
		}
	}
	
	/// Reset the captured cursor positions.
	private func resetWaypoints() {
		self.cursorWaypoints = []
	}
	
	/// Determines if the cursor is moving “fast enough” toward the destination.
	private func isCursorMovingFastEnough(_ timestamp: TimeInterval, locationInScreen: NSPoint) -> Bool {
		self.cursorWaypoints.append(Waypoint(timestamp: timestamp, locationInScreen: locationInScreen))
		
		guard self.cursorWaypoints.count > 1 else {
			return true
		}
		
		let maxWaypointCount = 20
		
		self.cursorWaypoints = Array(self.cursorWaypoints.suffix(maxWaypointCount))
		
		let oldestWaypoint = self.cursorWaypoints[0]
		let distanceX = oldestWaypoint.locationInScreen.x - locationInScreen.x
		let distanceY = oldestWaypoint.locationInScreen.y - locationInScreen.y
		
		let distance = Double(abs(distanceX) + abs(distanceY))
		let time = timestamp - oldestWaypoint.timestamp
		
		guard time > 0.0 else {
			return true
		}
		
		let speed = distance / time
		
		return speed >= OBWFilteringMenuCursorTracking.minimumSpeed
	}
}
