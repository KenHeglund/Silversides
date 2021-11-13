/*===========================================================================
NSEvent+OBWExtensionTests.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import XCTest
@testable import OBWControls

class NSEvent_OBWExtensionTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testLocationInScreen() throws {
		let timestamp = ProcessInfo().systemUptime
		var event: NSEvent
		var locationInScreen: NSPoint? = nil
		
		event = try XCTUnwrap(NSEvent.otherEvent(
			with: .applicationDefined,
			location: NSPoint(x: 100.0, y: 100.0),
			modifierFlags: [],
			timestamp: timestamp,
			windowNumber: 0,
			context: nil,
			subtype: 1,
			data1: 2,
			data2: 3
		))
		XCTAssertNil(event.locationInScreen)
		
		event = try XCTUnwrap(NSEvent.otherEvent(
			with: .periodic,
			location: NSPoint(x: 100.0, y: 100.0),
			modifierFlags: [],
			timestamp: timestamp,
			windowNumber: 0,
			context: nil,
			subtype: 1,
			data1: 2,
			data2: 3
		))
		XCTAssertNil(event.locationInScreen)
		
		let windowContentFrame = NSRect(
			x: 200.0,
			y: 300.0,
			width: 400.0,
			height: 500.0
		)
		
		let testLocation = NSPoint(x: 40.0, y: 60.0)
		let verificationPoint = NSPoint(
			x: windowContentFrame.origin.x + testLocation.x,
			y: windowContentFrame.origin.y + testLocation.y
		)
		
		let window = NSWindow(
			contentRect: windowContentFrame,
			styleMask: .borderless,
			backing: .buffered,
			defer: true
		)
		window.orderFrontRegardless()
		
		event = try XCTUnwrap(NSEvent.mouseEvent(
			with: .otherMouseDragged,
			location: testLocation,
			modifierFlags: [],
			timestamp: timestamp,
			windowNumber: window.windowNumber,
			context: nil,
			eventNumber: 123,
			clickCount: 1,
			pressure: 1.0
		))
		
		locationInScreen = event.locationInScreen
		XCTAssertEqual(locationInScreen, verificationPoint)
		
		event = try XCTUnwrap(NSEvent.mouseEvent(
			with: .otherMouseUp,
			location: testLocation,
			modifierFlags: [],
			timestamp: timestamp,
			windowNumber: 0,
			context: nil,
			eventNumber: 124,
			clickCount: 1,
			pressure: 0.0
		))
		
		locationInScreen = event.locationInScreen
		XCTAssertEqual(locationInScreen, testLocation)
	}
	
	func testLocationInView() throws {
		let timestamp = ProcessInfo().systemUptime
		
		var event: NSEvent
		var locationInView: NSPoint? = nil
		var testLocation: NSPoint = .zero
		var verificationPoint: NSPoint = .zero
		
		let windowContentFrame = NSRect(
			x: 200.0,
			y: 300.0,
			width: 400.0,
			height: 500.0
		)
		
		let window = NSWindow(
			contentRect: windowContentFrame,
			styleMask: .borderless,
			backing: .buffered,
			defer: true
		)
		window.orderFrontRegardless()
		
		let viewFrame = NSRect(
			x: 35.0,
			y: 65.0,
			width: 75.0,
			height: 95.0
		)
		
		let testView = NSView(frame: viewFrame)
		testLocation = NSPoint(x: 50.0, y: 100.0)
		
		event = try XCTUnwrap(NSEvent.mouseEvent(
			with: .otherMouseDragged,
			location: testLocation,
			modifierFlags: [],
			timestamp: timestamp,
			windowNumber: window.windowNumber,
			context: nil,
			eventNumber: 123,
			clickCount: 1,
			pressure: 1.0
		))
		XCTAssertNil(event.locationInView(testView))
		
		window.contentView?.addSubview(testView)
		
		verificationPoint = NSPoint(
			x: testLocation.x - viewFrame.origin.x,
			y: testLocation.y - viewFrame.origin.y
		)
		
		event = try XCTUnwrap(NSEvent.mouseEvent(
			with: .otherMouseDragged,
			location: testLocation,
			modifierFlags: [],
			timestamp: timestamp,
			windowNumber: window.windowNumber,
			context: nil,
			eventNumber: 123,
			clickCount: 1,
			pressure: 1.0
		))
		
		locationInView = event.locationInView(testView)
		XCTAssertEqual(locationInView, verificationPoint)
		
		testLocation = NSPoint(x: 250.0, y: 400.0)
		verificationPoint = NSPoint(
			x: testLocation.x - viewFrame.origin.x - windowContentFrame.origin.x,
			y: testLocation.y - viewFrame.origin.y - windowContentFrame.origin.y
		)
		
		event = try XCTUnwrap(NSEvent.mouseEvent(
			with: .otherMouseUp,
			location: testLocation,
			modifierFlags: [],
			timestamp: timestamp,
			windowNumber: 0,
			context: nil,
			eventNumber: 124,
			clickCount: 1,
			pressure: 0.0
		))
		
		locationInView = event.locationInView(testView)
		XCTAssertEqual(locationInView, verificationPoint)
		
		event = try XCTUnwrap(NSEvent.otherEvent(
			with: .applicationDefined,
			location: testLocation,
			modifierFlags: [],
			timestamp: timestamp,
			windowNumber: 0,
			context: nil,
			subtype: 1,
			data1: 2,
			data2: 3
		))
		XCTAssertNil(event.locationInView(testView))
		
		event = try XCTUnwrap(NSEvent.otherEvent(
			with: .periodic,
			location: testLocation,
			modifierFlags: [],
			timestamp: timestamp,
			windowNumber: 0,
			context: nil,
			subtype: 1,
			data1: 2,
			data2: 3
		))
		XCTAssertNil(event.locationInView(testView))
	}
}
