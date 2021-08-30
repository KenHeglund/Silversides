/*===========================================================================
OBWFilteringMenuTests.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import XCTest
@testable import OBWControls

class OBWFilteringMenuTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testMenuItems() throws {
		let menu = OBWFilteringMenu(title: "menu")
		
		let items = [
			OBWFilteringMenuItem(title: "alpha"),
			OBWFilteringMenuItem(title: "bravo"),
			OBWFilteringMenuItem(title: "charlie"),
		]
		
		for item in items {
			menu.addItem(item)
		}
		
		XCTAssertNotNil(menu.itemWithTitle("bravo"))
		XCTAssertNil(menu.itemWithTitle("delta"))
		
		menu.removeAllItems()
		
		XCTAssertNil(menu.itemWithTitle("bravo"))
	}
}
