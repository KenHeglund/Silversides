/*===========================================================================
OBWFilteringMenuItemScrollViewTests.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import XCTest
@testable import OBWControls

class OBWFilteringMenuItemScrollViewTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testScrollViewSize() throws {
		let menu = OBWFilteringMenu(title: "menu")
		menu.addItem(OBWFilteringMenuItem(title: "A"))
		menu.addItem(OBWFilteringMenuItem(title: "B"))
		menu.addItem(OBWFilteringMenuItem(title: "A menu item with a much longer name"))
		
		let scrollView = OBWFilteringMenuItemScrollView(menu: menu, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let viewSize = scrollView.frame.size
		XCTAssertGreaterThan(viewSize.width, 0.0)
		XCTAssertGreaterThan(viewSize.height, 0.0)
	}
	
	func testMenuPartByLocation() throws {
		let menu = OBWFilteringMenu(title: "menu")
		menu.addItem(OBWFilteringMenuItem(title: "A"))
		menu.addItem(OBWFilteringMenuItem(title: "B"))
		menu.addItem(OBWFilteringMenuItem(title: "C"))
		menu.addItem(OBWFilteringMenuItem(title: "D"))
		menu.addItem(OBWFilteringMenuItem(title: "E"))
		
		let scrollView = OBWFilteringMenuItemScrollView(menu: menu, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		var viewFrame = scrollView.frame
		let menuSize = scrollView.frame.size
		
		var topCenter = NSPoint(x: viewFrame.midX, y: viewFrame.maxY - 1.0)
		XCTAssertEqual(scrollView.menuPartAtLocation(topCenter), OBWFilteringMenu.MenuPart.item)
		var bottomCenter = NSPoint(x: viewFrame.midX, y: viewFrame.minY + 1.0)
		XCTAssertEqual(scrollView.menuPartAtLocation(bottomCenter), OBWFilteringMenu.MenuPart.item)
		
		let oldFrame = viewFrame
		viewFrame.size.height /= 2.0
		scrollView.setFrameSize(viewFrame.size)
		scrollView.resizeSubviews(withOldSize: oldFrame.size)
		
		scrollView.setMenuItemBoundsOriginY(0.0)
		
		topCenter = NSPoint(x: viewFrame.midX, y: viewFrame.maxY - 1.0)
		XCTAssertEqual(scrollView.menuPartAtLocation(topCenter), OBWFilteringMenu.MenuPart.up)
		bottomCenter = NSPoint(x: viewFrame.midX, y: viewFrame.minY + 1.0)
		XCTAssertEqual(scrollView.menuPartAtLocation(bottomCenter), OBWFilteringMenu.MenuPart.item)
		
		scrollView.setMenuItemBoundsOriginY(menuSize.height - viewFrame.size.height)
		
		topCenter = NSPoint(x: viewFrame.midX, y: viewFrame.maxY - 1.0)
		XCTAssertEqual(scrollView.menuPartAtLocation(topCenter), OBWFilteringMenu.MenuPart.item)
		bottomCenter = NSPoint(x: viewFrame.midX, y: viewFrame.minY + 1.0)
		XCTAssertEqual(scrollView.menuPartAtLocation(bottomCenter), OBWFilteringMenu.MenuPart.down)
		
		scrollView.setMenuItemBoundsOriginY((menuSize.height - viewFrame.size.height) / 2.0)
		
		topCenter = NSPoint(x: viewFrame.midX, y: viewFrame.maxY - 1.0)
		XCTAssertEqual(scrollView.menuPartAtLocation(topCenter), OBWFilteringMenu.MenuPart.up)
		bottomCenter = NSPoint(x: viewFrame.midX, y: viewFrame.minY + 1.0)
		XCTAssertEqual(scrollView.menuPartAtLocation(bottomCenter), OBWFilteringMenu.MenuPart.down)
	}
	
	func testMenuItemByLocation() throws {
		let menu = OBWFilteringMenu(title: "menu")
		menu.addItem(OBWFilteringMenuItem(title: "A"))
		menu.addItem(OBWFilteringMenuItem(title: "B"))
		menu.addItem(OBWFilteringMenuItem(title: "C"))
		menu.addItem(OBWFilteringMenuItem(title: "D"))
		menu.addItem(OBWFilteringMenuItem(title: "E"))
		
		let scrollView = OBWFilteringMenuItemScrollView(menu: menu, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let viewFrame = scrollView.frame
		
		var hitPoint = NSPoint(x: viewFrame.midX, y: viewFrame.size.height * 0.90)
		XCTAssertEqual(scrollView.menuItemAtLocation(hitPoint)?.title, "A")
		
		hitPoint.y = viewFrame.size.height * 0.70
		XCTAssertEqual(scrollView.menuItemAtLocation(hitPoint)?.title, "B")
		
		hitPoint.y = viewFrame.size.height * 0.50
		XCTAssertEqual(scrollView.menuItemAtLocation(hitPoint)?.title, "C")
		
		hitPoint.y = viewFrame.size.height * 0.30
		XCTAssertEqual(scrollView.menuItemAtLocation(hitPoint)?.title, "D")
		
		hitPoint.y = viewFrame.size.height * 0.10
		XCTAssertEqual(scrollView.menuItemAtLocation(hitPoint)?.title, "E")
	}
	
	func testItemViewRetrieval() throws {
		let menuItems = [
			OBWFilteringMenuItem(title: "A"),
			OBWFilteringMenuItem(title: "B"),
			OBWFilteringMenuItem(title: "C"),
			OBWFilteringMenuItem(title: "D"),
			OBWFilteringMenuItem(title: "E"),
		]
		
		let menu = OBWFilteringMenu(title: "menu")
		menu.addItems(menuItems)
		
		let scrollView = OBWFilteringMenuItemScrollView(menu: menu, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		
		XCTAssertNotNil(scrollView.viewForMenuItem(menuItems[0]))
		XCTAssertNil(scrollView.viewForMenuItem(OBWFilteringMenuItem.separatorItem))
		XCTAssertNil(scrollView.viewForMenuItem(OBWFilteringMenuItem(title: "F")))
		
		XCTAssertTrue(scrollView.nextViewAfterItem(menuItems[1])?.menuItem === menuItems[2])
		XCTAssertTrue(scrollView.nextViewAfterItem(menuItems.last)?.menuItem === menuItems.last)
		XCTAssertTrue(scrollView.nextViewAfterItem(nil)?.menuItem === menuItems.first)
		
		XCTAssertTrue(scrollView.previousViewBeforeItem(menuItems[3])?.menuItem === menuItems[2])
		XCTAssertTrue(scrollView.previousViewBeforeItem(menuItems.first)?.menuItem === menuItems.first)
		XCTAssertTrue(scrollView.previousViewBeforeItem(nil)?.menuItem === menuItems.last)
	}
	
	func testApplyingFilterResults() throws {
		var menuItems: [OBWFilteringMenuItem] = []
		for index in 10...29 {
			menuItems.append(OBWFilteringMenuItem(title: "item \(index)"))
		}
		
		let menu = OBWFilteringMenu(title: "menu")
		menu.addItems(menuItems)
		
		let scrollView = OBWFilteringMenuItemScrollView(menu: menu, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let menuItemSize = scrollView.totalMenuItemSize
		
		_ = scrollView.applyFilterResults(OBWFilteringMenuItemFilterStatus.filterStatus(menu, filterString: "g/item 1/"))
		XCTAssertEqual(scrollView.totalMenuItemSize.height, menuItemSize.height / 2.0)
		
		_ = scrollView.applyFilterResults(OBWFilteringMenuItemFilterStatus.filterStatus(menu, filterString: ""))
		XCTAssertEqual(scrollView.totalMenuItemSize.height, menuItemSize.height)
	}
	
	func testApplyingModifierMask() throws {
		let menuItems = [
			OBWFilteringMenuItem(title: "A"),
			OBWFilteringMenuItem(title: "B"),
			OBWFilteringMenuItem(title: "C"),
			OBWFilteringMenuItem(title: "D"),
			OBWFilteringMenuItem(title: "E"),
		]
		
		menuItems[1].keyEquivalentModifierMask = [ .option ]
		menuItems[2].keyEquivalentModifierMask = [ .command, .option ]
		menuItems[3].keyEquivalentModifierMask = [ .option ]
		
		let menu = OBWFilteringMenu(title: "menu")
		menu.addItems(menuItems)
		
		let scrollView = OBWFilteringMenuItemScrollView(menu: menu, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let menuItemSize = scrollView.totalMenuItemSize
		
		_ = scrollView.applyModifierFlags([ .option ])
		XCTAssertEqual(scrollView.totalMenuItemSize.height, menuItemSize.height * 2.0)
		
		_ = scrollView.applyModifierFlags([ .command ])
		XCTAssertEqual(scrollView.totalMenuItemSize.height, menuItemSize.height)
		
		_ = scrollView.applyModifierFlags([ .option, .command ])
		XCTAssertEqual(scrollView.totalMenuItemSize.height, menuItemSize.height * 1.5)
	}
}
