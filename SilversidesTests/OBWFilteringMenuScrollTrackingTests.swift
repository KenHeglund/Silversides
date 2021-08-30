/*===========================================================================
OBWFilteringMenuScrollTrackingTests.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import XCTest
@testable import OBWControls

class OBWFilteringMenuScrollTrackingTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	// This "test" exists to allow scroll wheel events to printed as a string.  In normal circumstances it should be disabled.  It can be re-enabled if new scroll events need to be recorded.
	#if false
	func testPrintingScrollEvents() throws {
		scrollTrackingEventPrinter = PrintEventDataAsEncodedString
		self.waitForInterval(milliseconds: 10 * 1000)
	}
	#endif
	
	func testWhenEntireMenuIsAlreadyVisible() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenFrame = screen.frame
		
		let menu = OBWFilteringMenu(title: "menu")
		for index in 1...20 {
			menu.addItem(OBWFilteringMenuItem(title: "item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		
		let menuLocation = NSPoint(
			x: (geometry.totalMenuItemSize.width / 2.0).rounded(.down),
			y: (geometry.totalMenuItemSize.height / 2.0).rounded(.down)
		)
		
		let screenLocation = NSPoint(
			x: floor(screenFrame.midX),
			y: floor(screenFrame.midY)
		)
		
		geometry.updateGeometryToDisplayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false)
		
		let scrollTracking = OBWFilteringMenuScrollTracking()
		scrollTracking.reset(geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds)
		
		let scrollContentUpEvent = try XCTUnwrap(self.scrollContentUpEvent)
		let scrollContentDownEvent = try XCTUnwrap(self.scrollContentDownEvent)
		
		// Test
		
		let boundsChangedNotification = OBWFilteringMenuScrollTracking.boundsChangedNotification
		
		// Notification should not be sent when scrolling up.
		let upExpectation = self.expectation(forNotification: boundsChangedNotification, object: nil, handler: nil)
		upExpectation.isInverted = true
		
		scrollTracking.scrollEvent(scrollContentUpEvent)
		self.wait(for: [upExpectation], timeout: 0.25)
		
		// Notification should not be sent when scrolling down.
		let downExpectation = self.expectation(forNotification: boundsChangedNotification, object: nil, handler: nil)
		downExpectation.isInverted = true
		
		scrollTracking.scrollEvent(scrollContentDownEvent)
		self.wait(for: [downExpectation], timeout: 0.25)
	}
	
	func testScrollingDownWhenMenuOverlapsBottomOfScreen() throws {
		// When scrolling down while the menu overlaps the bottom of the screen, the content bounds origin should increase while the bounds height remains the same.  This is elastic movement of the menu content.
		
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenFrame = screen.frame
		
		let menu = OBWFilteringMenu(title: "menu")
		for index in 1...20 {
			menu.addItem(OBWFilteringMenuItem(title: "item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		
		let menuLocation = NSPoint(x: 0.0, y: geometry.totalMenuItemSize.height)
		let screenLocation = NSPoint(
			x: screenFrame.midX,
			y: screenFrame.minY + (geometry.totalMenuItemSize.height / 5.0).rounded(.down)
		)
		
		geometry.updateGeometryToDisplayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false)
		
		let scrollTracking = OBWFilteringMenuScrollTracking()
		scrollTracking.reset(geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds)
		
		let scrollContentDownEvent = try XCTUnwrap(self.scrollContentDownEvent)
		
		// Record
		
		var originYMax = geometry.initialBounds.minY
		let observation = NotificationCenter.default.addObserver(forName: OBWFilteringMenuScrollTracking.boundsChangedNotification, object: nil, queue: nil) {
			(notification: Notification) in
			
			guard let bounds = notification.userInfo?[OBWFilteringMenuScrollTracking.Key.bounds] as? NSRect else {
				return
			}
			
			originYMax = max(originYMax, bounds.minY)
		}
		defer {
			NotificationCenter.default.removeObserver(observation)
		}
		
		// Test
		
		scrollTracking.scrollEvent(scrollContentDownEvent)
		scrollTracking.scrollEvent(scrollContentDownEvent)
		scrollTracking.scrollEvent(scrollContentDownEvent)
		scrollTracking.scrollEvent(scrollContentDownEvent)
		scrollTracking.scrollEvent(scrollContentDownEvent)
		
		XCTAssertGreaterThan(originYMax, geometry.initialBounds.minY)
	}
	
	func testScrollingUpWhenMenuOverlapsBottomOfScreen() throws {
		// When scrolling up while the menu overlaps the bottom of the screen, the content bounds origin should decrease while the bounds height increases.  This is the menu content resizing upward.
		
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenFrame = screen.frame
		
		let menu = OBWFilteringMenu(title: "menu")
		for index in 1...20 {
			menu.addItem(OBWFilteringMenuItem(title: "item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		
		let menuLocation = NSPoint(x: 0.0, y: geometry.totalMenuItemSize.height)
		let screenLocation = NSPoint(
			x: screenFrame.midX,
			y: screenFrame.minY + (geometry.totalMenuItemSize.height / 5.0).rounded(.down)
		)
		
		geometry.updateGeometryToDisplayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false)
		
		let scrollTracking = OBWFilteringMenuScrollTracking()
		scrollTracking.reset(geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds)
		
		let scrollContentUpEvent = try XCTUnwrap(self.scrollContentUpEvent)
		
		// Record
		
		var notificationBounds = NSZeroRect
		let observation = NotificationCenter.default.addObserver(forName: OBWFilteringMenuScrollTracking.boundsChangedNotification, object: nil, queue: nil) { (notification: Notification) in
			
			guard let bounds = notification.userInfo?[OBWFilteringMenuScrollTracking.Key.bounds] as? NSRect else {
				return
			}
			
			notificationBounds = bounds
		}
		defer {
			NotificationCenter.default.removeObserver(observation)
		}
		
		// Test
		
		scrollTracking.scrollEvent(scrollContentUpEvent)
		scrollTracking.scrollEvent(scrollContentUpEvent)
		scrollTracking.scrollEvent(scrollContentUpEvent)
		scrollTracking.scrollEvent(scrollContentUpEvent)
		scrollTracking.scrollEvent(scrollContentUpEvent)
		
		XCTAssertLessThan(notificationBounds.minY, geometry.initialBounds.minY)
		XCTAssertGreaterThan(notificationBounds.height, geometry.initialBounds.height)
	}
	
	func testScrollingUpWhenMenuOverlapsTopOfScreen() throws {
		// When scrolling up while the menu overlaps the top of the screen, the content bounds origin should decrease while the bounds height remains the same.  This is elastic movement of the menu content.
		
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenFrame = screen.frame
		
		let menu = OBWFilteringMenu(title: "menu")
		for index in 1...20 {
			menu.addItem(OBWFilteringMenuItem(title: "item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		
		let menuLocation = NSZeroPoint
		let screenLocation = NSPoint(
			x: screenFrame.midX,
			y: screenFrame.maxY - (geometry.totalMenuItemSize.height / 5.0).rounded(.down)
		)
		
		_ = geometry.updateGeometryToDisplayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false)
		
		let scrollTracking = OBWFilteringMenuScrollTracking()
		scrollTracking.reset(geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds)
		
		let scrollContentUpEvent = try XCTUnwrap(self.scrollContentUpEvent)
		
		// Record
		
		var notificationBounds = NSZeroRect
		let observation = NotificationCenter.default.addObserver(forName: OBWFilteringMenuScrollTracking.boundsChangedNotification, object: nil, queue: nil) { (notification: Notification) in
			
			guard  let bounds = notification.userInfo?[OBWFilteringMenuScrollTracking.Key.bounds] as? NSRect else {
				return
			}
			
			notificationBounds = bounds
		}
		defer {
			NotificationCenter.default.removeObserver(observation)
		}
		
		// Test
		
		scrollTracking.scrollEvent(scrollContentUpEvent)
		scrollTracking.scrollEvent(scrollContentUpEvent)
		scrollTracking.scrollEvent(scrollContentUpEvent)
		scrollTracking.scrollEvent(scrollContentUpEvent)
		scrollTracking.scrollEvent(scrollContentUpEvent)
		
		XCTAssertLessThan(notificationBounds.minY, geometry.initialBounds.minY)
		XCTAssertEqual(notificationBounds.height, geometry.initialBounds.height)
	}
	
	func testScrollingDownWhenMenuOverlapsTopOfScreen() throws {
		// When scrolling down while the menu overlaps the top of the screen, the content bounds origin should remain the same while the bounds height increases.  This is the menu content resizing downward.
		
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenFrame = screen.frame
		
		let menu = OBWFilteringMenu(title: "menu")
		for index in 1...20 {
			menu.addItem(OBWFilteringMenuItem(title: "item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		
		let menuLocation = NSZeroPoint
		let screenLocation = NSPoint(
			x: screenFrame.midX,
			y: screenFrame.maxY - (geometry.totalMenuItemSize.height / 5.0).rounded(.down)
		)
		
		geometry.updateGeometryToDisplayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false)
		
		let scrollTracking = OBWFilteringMenuScrollTracking()
		scrollTracking.reset(geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds)
		
		let scrollContentDownEvent = try XCTUnwrap(self.scrollContentDownEvent)
		
		// Record
		
		var notificationBounds = NSZeroRect
		let observation = NotificationCenter.default.addObserver(forName: OBWFilteringMenuScrollTracking.boundsChangedNotification, object: nil, queue: nil) { (notification: Notification) in
			
			guard let bounds = notification.userInfo?[OBWFilteringMenuScrollTracking.Key.bounds] as? NSRect else {
				return
			}
			
			notificationBounds = bounds
		}
		defer {
			NotificationCenter.default.removeObserver(observation)
		}
		
		// Test
		
		scrollTracking.scrollEvent(scrollContentDownEvent)
		scrollTracking.scrollEvent(scrollContentDownEvent)
		scrollTracking.scrollEvent(scrollContentDownEvent)
		scrollTracking.scrollEvent(scrollContentDownEvent)
		scrollTracking.scrollEvent(scrollContentDownEvent)
		
		XCTAssertEqual(notificationBounds.origin.y, geometry.initialBounds.origin.y)
		XCTAssertGreaterThan(notificationBounds.size.height, geometry.initialBounds.size.height)
	}
	
	private let scrollContentUpEvent: NSEvent? = {
		// Recorded from the trackpad, scroll delta = -20.0
		let encodedContentUpEvent = "AAAAAgABQDUAAAADAAFANgAAAAAAAUA3AAAAFgACwDhDiVwAQw2wAAACwDlBG4AAQqFgAAABADos9I93AAAGmgABQDsAAAAAAAFAMwAAA0sAAUA0AALPQwABAKks9I93AAAGmgABQGoAAADyAAFAawAABBoAAUAL/////wABQAwAAAAAAAFADQAAAAAAAUBYAAAAAQABQIkAAAABAAFAXf/+GZkAAUBeAAAAAAABQF8AAAAAAAFAYP///+wAAUBhAAAAAgABQGIAAAAAAAFAewAAAAAAAUBjAAAAAgABQGQAAAAA"
		
		return OBWFilteringMenuScrollTrackingTests.eventWithString(base64EncodedString: encodedContentUpEvent)
	}()
	
	private let scrollContentDownEvent: NSEvent? = {
		// Recorded from the trackpad, scroll delta = 20.0
		let encodedContentDownEvent =  "AAAAAgABQDUAAAADAAFANgAAAAAAAUA3AAAAFgACwDhDiLCAQvkEAAACwDlBBhAAQn4IAAABADrFfmWeAAAGjwABQDsAAAAAAAFAMwAAAzkAAUA0AAkdnwABAKnFfmWeAAAGjwABQGoAAADyAAFAawAABBoAAUALAAAAAgABQAwAAAAAAAFADQAAAAAAAUBYAAAAAQABQIkAAAABAAFAXQACAAAAAUBeAAAAAAABQF8AAAAAAAFAYAAAABQAAUBh/////gABQGIAAAAAAAFAewAAAAAAAUBjAAAAAgABQGQAAAAA"
		
		return OBWFilteringMenuScrollTrackingTests.eventWithString(base64EncodedString: encodedContentDownEvent)
	}()
	
	private class func eventWithString(base64EncodedString encodedString: String) -> NSEvent? {
		guard
			let scrollEventData = Data(base64Encoded: encodedString, options: []),
			let cgEvent = CGEvent(withDataAllocator: kCFAllocatorDefault, data: scrollEventData as CFData),
			let nsEvent = NSEvent(cgEvent: cgEvent)
		else {
			return nil
		}
		
		return nsEvent
	}
}
