/*===========================================================================
OBWFilteringMenuItemTests.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import XCTest
@testable import OBWControls

class OBWFilteringMenuItemTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testSeparatorMenuItemIdentity() throws {
		let separatorItem = OBWFilteringMenuItem.separatorItem
		XCTAssertNotNil(separatorItem)
		XCTAssertTrue(separatorItem.isSeparatorItem)
		
		let menuItem = OBWFilteringMenuItem(title: separatorItem.title ?? "")
		XCTAssertFalse(menuItem.isSeparatorItem)
		
		XCTAssertTrue(OBWFilteringMenuItem.separatorItem === separatorItem)
	}
	
	func testThatMenuItemSelectionHandlerIsPreferredOverMenuSelectionHandler() throws {
		var menuHandlerArgument: OBWFilteringMenuItem? = nil
		var menuItemHandlerArgument: OBWFilteringMenuItem? = nil
		
		let menu = OBWFilteringMenu(title: "menu")
		menu.actionHandler = { (menuItem: OBWFilteringMenuItem) in
			menuHandlerArgument = menuItem
		}
		
		let menuItem = OBWFilteringMenuItem(title: "menu item")
		menuItem.actionHandler = { (menuItem: OBWFilteringMenuItem) in
			menuItemHandlerArgument = menuItem
		}
		menu.addItem(menuItem)
		
		menuItem.performAction()
		
		XCTAssertTrue(menuItemHandlerArgument === menuItem)
		XCTAssertNil(menuHandlerArgument)
	}
	
	func testThatMenuSelectionHandlerIsUsedWhenMenuItemSelectionHandlerIsNil() throws {
		var menuHandlerArgument: OBWFilteringMenuItem? = nil
		
		let menu = OBWFilteringMenu(title: "menu")
		menu.actionHandler = { (menuItem: OBWFilteringMenuItem) in
			menuHandlerArgument = menuItem
		}
		
		let menuItems = [
			OBWFilteringMenuItem(title: "item 1"),
			OBWFilteringMenuItem(title: "item 2"),
			OBWFilteringMenuItem(title: "item 3"),
		]
		
		for menuItem in menuItems {
			menu.addItem(menuItem)
		}
		
		menuItems[1].performAction()
		
		XCTAssertTrue(menuHandlerArgument === menuItems[1])
	}
	
	func testAlternateItemRetrieval() throws {
		let menu = OBWFilteringMenu(title: "menu")
		
		let menuItems = [
			OBWFilteringMenuItem(title: "menu item 1"),
			OBWFilteringMenuItem(title: "menu item 2"),
		]
		
		for menuItem in menuItems {
			menu.addItem(menuItem)
		}
		
		menuItems[1].keyEquivalentModifierMask = .control
		
		let alternateItems = [
			OBWFilteringMenuItem(title: "item 1"),
			OBWFilteringMenuItem(title: "item 2"),
			OBWFilteringMenuItem(title: "item 3"),
		]
		
		alternateItems[0].keyEquivalentModifierMask = .command
		alternateItems[1].keyEquivalentModifierMask = [.control, .shift]
		alternateItems[2].keyEquivalentModifierMask = .option
		
		for alternateItem in alternateItems {
			try! menuItems[0].addAlternateItem(alternateItem)
		}
		
		XCTAssertTrue(menuItems[0].visibleItemForModifierFlags(.command) === alternateItems[0])
		XCTAssertTrue(menuItems[0].visibleItemForModifierFlags(.control) === menuItems[0])
		XCTAssertTrue(menuItems[0].visibleItemForModifierFlags([]) === menuItems[0])
		XCTAssertTrue(menuItems[0].visibleItemForModifierFlags([.command, .shift]) === menuItems[0])
		
		XCTAssertTrue(alternateItems[2].visibleItemForModifierFlags(.option) === alternateItems[2])
		XCTAssertNil(alternateItems[2].visibleItemForModifierFlags(.shift))
		
		XCTAssertNil(menuItems[1].visibleItemForModifierFlags(.shift))
	}
	
	func testAlternateItemReplacement() throws {
		let menu = OBWFilteringMenu(title: "menu")
		
		let menuItem = OBWFilteringMenuItem(title: "menu item")
		menu.addItem(menuItem)
		
		let alternateItems = [
			OBWFilteringMenuItem(title: "item 1"),
			OBWFilteringMenuItem(title: "item 2"),
		]
		
		for alternateItem in alternateItems {
			alternateItem.keyEquivalentModifierMask = .command
		}
		
		try! menuItem.addAlternateItem(alternateItems[0])
		
		XCTAssertTrue(menuItem.visibleItemForModifierFlags(.command) === alternateItems[0])
		
		try! menuItem.addAlternateItem(alternateItems[1])
		
		XCTAssertFalse(menuItem.visibleItemForModifierFlags(.command) === alternateItems[0])
		XCTAssertTrue(menuItem.visibleItemForModifierFlags(.command) === alternateItems[1])
	}
}
