/*===========================================================================
OBWFilteringMenuWindowTests.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import XCTest
@testable import OBWControls

class OBWFilteringMenuWindowTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testGeometryApplication_MenuSizeChanges() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenFrame = screen.frame
		
		let menu = OBWFilteringMenu()
		menu.addItem(OBWFilteringMenuItem(title: "A"))
		menu.addItem(OBWFilteringMenuItem(title: "B"))
		
		let longMenuItem = OBWFilteringMenuItem(title: "A menu item with a really long name")
		longMenuItem.keyEquivalentModifierMask = [.command]
		menu.addItem(longMenuItem)
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen)
		
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		let screenCenter = NSPoint(x: screenFrame.midX, y: screenFrame.midY)
		if geometry.updateGeometryToDisplayMenuLocation(.zero, atScreenLocation: screenCenter, allowWindowToGrowUpward: true) {
			window.applyWindowGeometry(geometry)
		}
		
		let menuView = window.menuView
		let initialWindowFrame = window.frame
		
		// Larger menu width, window gets wider
		// Larger menu height, window gets taller
		
		menuView.applyModifierFlags([.command])
		
		geometry.updateGeometryWithResizedMenu(constrainToAnchor: true)
		window.applyWindowGeometry(geometry)
		
		let largerWindowFrame = window.frame
		
		XCTAssertGreaterThan(largerWindowFrame.width, initialWindowFrame.width)
		XCTAssertGreaterThan(largerWindowFrame.height, initialWindowFrame.height)
		
		// Smaller menu width, window with remains unchanged
		// Smaller menu height, window height returns to inital height
		
		menuView.applyModifierFlags([.shift])
		
		geometry.updateGeometryWithResizedMenu(constrainToAnchor: true)
		window.applyWindowGeometry(geometry)
		
		let reducedWindowFrame = window.frame
		
		XCTAssertEqual(reducedWindowFrame.width, largerWindowFrame.width)
		XCTAssertEqual(reducedWindowFrame.height, initialWindowFrame.height)
	}
	
	func testGeometryApplication_MenuScrolling() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenFrame = screen.frame
		
		let menu = OBWFilteringMenu()
		for index in 1...10 {
			menu.addItem(OBWFilteringMenuItem(title: "menu item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen)
		
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		let screenLocation = NSPoint(x: screenFrame.midX, y: screenFrame.minY + 40.0)
		let menuLocation = NSPoint(x: 0.0, y: geometry.totalMenuItemSize.height)
		if geometry.updateGeometryToDisplayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false) {
			window.applyWindowGeometry(geometry)
		}
		
		// Test
		
		let initialWindowFrame = window.frame
		
		let distanceToScroll: CGFloat = 25.0
		
		// Sanity check to verify that not all of the menu's contents are visible in the window, ie. there is room to scroll
		XCTAssertLessThan(geometry.initialBounds.height + distanceToScroll, geometry.totalMenuItemSize.height)
		
		let scrolledBounds = NSRect(
			x: geometry.initialBounds.minX,
			y: geometry.initialBounds.minY - distanceToScroll,
			width: geometry.initialBounds.width,
			height: geometry.initialBounds.height + distanceToScroll
		)
		
		if geometry.updateGeometryToDisplayMenuItemBounds(scrolledBounds) {
			window.applyWindowGeometry(geometry)
		}
		
		XCTAssertEqual(geometry.finalBounds.height, geometry.totalMenuItemSize.height)
		
		let scrolledWindowFrame = window.frame
		
		XCTAssertEqual(scrolledWindowFrame.height, initialWindowFrame.height + distanceToScroll)
		
		// Sanity check to verify that there is still menu content outside of the visible bounds
		XCTAssertLessThan(geometry.initialBounds.height, geometry.totalMenuItemSize.height)
	}
	
	func testMinimumWindowSize() throws {
		let screen = NSScreen.screens[0]
		let menu = OBWFilteringMenu(title: "menu")
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen)
		XCTAssertFalse(window.frame.isEmpty)
	}
}
