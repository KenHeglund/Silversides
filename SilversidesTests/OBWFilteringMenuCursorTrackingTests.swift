/*===========================================================================
OBWFilteringMenuCursorTrackingTests.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import XCTest
@testable import OBWControls

class OBWFilteringMenuCursorTrackingTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testContinuationWithFastCursorMovement() throws {
		let menuItem = OBWFilteringMenuItem(title: "menuItem")
		
		let sourceLine = NSRect(
			x: 100.0,
			y: 190.0,
			width: 0.0,
			height: 20.0
		)
		
		let destinationArea = NSRect(
			x: 300.0,
			y: 100.0,
			width: 100.0,
			height: 200.0
		)
		
		let cursorTracking = OBWFilteringMenuCursorTracking(subviewOfItem: menuItem, fromSourceLine: sourceLine, toArea: destinationArea)
		
		let distancePerEvent: CGFloat = 5.0
		var locationInScreen = NSPoint(
			x: sourceLine.origin.x,
			y: sourceLine.origin.y + floor(sourceLine.size.height / 2.0)
		)
		
		let intervalPerEvent = 0.05
		var timestamp = ProcessInfo().systemUptime
		
		var result = true
		
		for _ in 1...20 {
			locationInScreen.x += distancePerEvent
			timestamp += intervalPerEvent
			
			let event = try XCTUnwrap(NSEvent.mouseEvent(
				with: .mouseMoved,
				location: locationInScreen,
				modifierFlags: [],
				timestamp: timestamp,
				windowNumber: 0,
				context: nil,
				eventNumber: 0,
				clickCount: 0,
				pressure: 0
			))
			
			if cursorTracking.isCursorProgressingTowardSubmenu(event) == false {
				result = false
			}
		}
		
		XCTAssertTrue(result)
	}
	
	func testContinuationWithSlowCursorMovement() throws {
		let menuItem = OBWFilteringMenuItem(title: "menuItem")
		
		let sourceLine = NSRect(
			x: 100.0,
			y: 190.0,
			width: 0.0,
			height: 20.0
		)
		
		let destinationArea = NSRect(
			x: 300.0,
			y: 100.0,
			width: 100.0,
			height: 200.0
		)
		
		let cursorTracking = OBWFilteringMenuCursorTracking(subviewOfItem: menuItem, fromSourceLine: sourceLine, toArea: destinationArea)
		
		let distancePerEvent: CGFloat = 0.5
		var locationInScreen = NSPoint(
			x: sourceLine.origin.x,
			y: sourceLine.origin.y + floor(sourceLine.size.height / 2.0)
		)
		
		let intervalPerEvent = 0.1
		var timestamp = ProcessInfo().systemUptime
		
		var result = true
		
		for _ in 1...20 {
			locationInScreen.x += distancePerEvent
			timestamp += intervalPerEvent
			
			let event = try XCTUnwrap(NSEvent.mouseEvent(
				with: .mouseMoved,
				location: locationInScreen,
				modifierFlags: [],
				timestamp: timestamp,
				windowNumber: 0,
				context: nil,
				eventNumber: 0,
				clickCount: 0,
				pressure: 0
			))
			
			if cursorTracking.isCursorProgressingTowardSubmenu(event) == false {
				result = false
			}
		}
		
		XCTAssertFalse(result)
	}
	
	func testContinuationWithCursorMovementBeyondBounds() throws {
		let menuItem = OBWFilteringMenuItem(title: "menuItem")
		
		let sourceLine = NSRect(
			x: 100.0,
			y: 190.0,
			width: 0.0,
			height: 20.0
		)
		
		let destinationArea = NSRect(
			x: 300.0,
			y: 100.0,
			width: 100.0,
			height: 200.0
		)
		
		let cursorTracking = OBWFilteringMenuCursorTracking(subviewOfItem: menuItem, fromSourceLine: sourceLine, toArea: destinationArea)
		
		let offsetPerEvent = NSSize(width: 5.0, height: 20.0)
		
		var locationInScreen = NSPoint(
			x: sourceLine.origin.x,
			y: sourceLine.origin.y + floor(sourceLine.size.height / 2.0)
		)
		
		let intervalPerEvent = 0.05
		var timestamp = ProcessInfo().systemUptime
		
		var result = true
		
		for _ in 1...20 {
			locationInScreen.x += offsetPerEvent.width
			locationInScreen.y += offsetPerEvent.height
			
			timestamp += intervalPerEvent
			
			let event = try XCTUnwrap(NSEvent.mouseEvent(
				with: .mouseMoved,
				location: locationInScreen,
				modifierFlags: [],
				timestamp: timestamp,
				windowNumber: 0,
				context: nil,
				eventNumber: 0,
				clickCount: 0,
				pressure: 0
			))
			
			if cursorTracking.isCursorProgressingTowardSubmenu(event) == false {
				result = false
			}
		}
		
		XCTAssertFalse(result)
	}
}
