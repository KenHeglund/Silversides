/*===========================================================================
OBWFilteringMenuActionItemViewTests.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import XCTest
@testable import OBWControls

class OBWFilteringMenuActionItemViewTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testPreferredSizeForMenuItem() throws {
		let smallMenuItem = OBWFilteringMenuItem(title: "A")
		let smallMenuItemView = OBWFilteringMenuItemView.makeViewWithMenuItem(smallMenuItem)
		let smallItemSize = smallMenuItemView.preferredSize
		XCTAssertGreaterThan(smallItemSize.width, 0.0)
		XCTAssertGreaterThan(smallItemSize.height, 0.0)
		
		let largeMenuItem = OBWFilteringMenuItem(title: "A menu item with a much longer name")
		let largeMenuItemView = OBWFilteringMenuItemView.makeViewWithMenuItem(largeMenuItem)
		let largeItemSize = largeMenuItemView.preferredSize
		XCTAssertGreaterThan(largeItemSize.width, smallItemSize.width)
		XCTAssertEqual(largeItemSize.height, smallItemSize.height)
	}
	
	func testExample() throws {
		// TODO: Find more opportunities to test OBWFilteringMenuActionItemView...
	}
}
