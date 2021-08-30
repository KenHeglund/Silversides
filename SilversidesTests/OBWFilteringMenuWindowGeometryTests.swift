/*===========================================================================
OBWFilteringMenuWindowGeometryTests.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import XCTest
@testable import OBWControls

class OBWFilteringMenuWindowGeometryTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	// MARK: - NSScreen.screenContainingLocation(_)
	
	func testThatTheCorrectScreenIsFoundFromLocationInDesktopSpace() throws {
		var desktopBounds = NSRect.zero
		
		for screen in NSScreen.screens {
			let screenFrame = screen.frame
			
			desktopBounds = NSUnionRect(desktopBounds, screenFrame)
			
			let point1 = NSPoint(
				x: screenFrame.minX + (screenFrame.width / 2.0).rounded(.toNearestOrAwayFromZero),
				y: screenFrame.minY + (screenFrame.height / 2.0).rounded(.toNearestOrAwayFromZero)
			)
			XCTAssertTrue(NSScreen.screenContainingLocation(point1) === screen)
			
			let point2 = NSPoint(
				x: point1.x + screenFrame.width,
				y: point1.y
			)
			XCTAssertFalse(NSScreen.screenContainingLocation(point2) === screen)
			
			let point3 = NSPoint(
				x: screenFrame.minX + 1.0,
				y: screenFrame.minY + 1.0
			)
			XCTAssertTrue(NSScreen.screenContainingLocation(point3) === screen)
			
			let point4 = NSPoint(
				x: point3.x + screenFrame.width,
				y: point3.y
			)
			XCTAssertFalse(NSScreen.screenContainingLocation(point4) === screen)
			
			let point5 = NSPoint(
				x: screenFrame.minX + 1.0,
				y: screenFrame.maxY - 1.0
			)
			XCTAssertTrue(NSScreen.screenContainingLocation(point5) === screen)
			
			let point6 = NSPoint(
				x: point5.x + screenFrame.width,
				y: point5.y
			)
			XCTAssertFalse(NSScreen.screenContainingLocation(point6) === screen)
			
			let point7 = NSPoint(
				x: screenFrame.maxX - 1.0,
				y: screenFrame.maxY - 1.0
			)
			XCTAssertTrue(NSScreen.screenContainingLocation(point7) === screen)
			
			let point8 = NSPoint(
				x: point7.x + screenFrame.width,
				y: point7.y
			)
			XCTAssertFalse(NSScreen.screenContainingLocation(point8) === screen)
			
			let point9 = NSPoint(
				x: screenFrame.maxX - 1.0,
				y: screenFrame.minY + 1.0
			)
			XCTAssertTrue(NSScreen.screenContainingLocation(point9) === screen)
			
			let point10 = NSPoint(
				x: point9.x + screenFrame.width,
				y: point9.y
			)
			XCTAssertFalse(NSScreen.screenContainingLocation(point10) === screen)
			
			let point11 = NSPoint(
				x: desktopBounds.minX - 1.0,
				y: desktopBounds.minY - 1.0
			)
			XCTAssertNil(NSScreen.screenContainingLocation(point11))
		}
	}
	
	// MARK: - init(window:)
	
	func testInitialGeometryLimitedToMenuSize() throws {
		let screen = NSScreen.screens[0]
		
		let menu = OBWFilteringMenu()
		for index in 1...5 {
			menu.addItem(OBWFilteringMenuItem(title: "Item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		
		XCTAssertEqual(geometry.initialBounds.height, geometry.totalMenuItemSize.height)
		XCTAssertEqual(geometry.finalBounds.height, geometry.totalMenuItemSize.height)
	}
	
	func testInitialGeometryLimitedToScreenSize() throws {
		let screen = NSScreen.screens[0]
		
		let menu = OBWFilteringMenu()
		for index in 1...200 {
			// There need to be enough items such that the menu is taller than the current screen
			menu.addItem(OBWFilteringMenuItem(title: "Item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		
		XCTAssertEqual(geometry.initialBounds.height, geometry.finalBounds.height)
		XCTAssertLessThan(geometry.initialBounds.height, geometry.totalMenuItemSize.height)
		XCTAssertLessThan(geometry.finalBounds.height, geometry.totalMenuItemSize.height)
	}
	
	func testMinimumFrameSize() throws {
		let screen = NSScreen.screens[0]
		let screenCenter = NSPoint(x: screen.frame.midX, y: screen.frame.midY)
		
		let menu = OBWFilteringMenu()
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		XCTAssertFalse(geometry.frame.isEmpty)
		
		geometry.updateGeometryWithResizedMenu(constrainToAnchor: true)
		XCTAssertFalse(geometry.frame.isEmpty)
		
		geometry.updateGeometryToDisplayMenuLocation(NSZeroPoint, atScreenLocation: screenCenter, allowWindowToGrowUpward: true)
		XCTAssertFalse(geometry.frame.isEmpty)
	}
	
	// MARK: - updateGeometryToDisplayMenuLocation(_:atScreenLocation:allowWindowToGrowUpward:)
	
	func testDisplayMenuLocation_MenuWidthFitsScreen() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
		
		let menu = OBWFilteringMenu()
		for index in 1...5 {
			menu.addItem(OBWFilteringMenuItem(title: "Item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		let menuView = window.menuView
		
		// Test, the window size fits the entire menu
		
		let menuLocation = NSPoint(x: geometry.initialBounds.midX, y: geometry.initialBounds.midY)
		let screenLocation = NSPoint(x: screenLimits.midX, y: screenLimits.midY)
		let updateResult = geometry.updateGeometryToDisplayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: true)
		XCTAssertTrue(updateResult)
		
		let menuFrame = NSRect(
			x: screenLocation.x - (geometry.totalMenuItemSize.width / 2.0).rounded(.down),
			y: screenLocation.y - (geometry.totalMenuItemSize.height / 2.0).rounded(.down),
			width: geometry.totalMenuItemSize.width,
			height: geometry.totalMenuItemSize.height
		)
		
		let interiorFrame = menuFrame - menuView.outerMenuMargins
		let windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
		
		XCTAssertEqual(geometry.frame, windowFrame)
		XCTAssertEqual(geometry.initialBounds.size, geometry.totalMenuItemSize)
		XCTAssertEqual(geometry.finalBounds.size, geometry.totalMenuItemSize)
		XCTAssertLessThan(geometry.frame.width, screenLimits.width)
	}
	
	func testDisplayMenuLocation_MenuWidthWiderThanScreen() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
		
		var longTitle = "Item with an enormously wide title"
		for _ in 1...4 {
			// The title needs to be too wide to fit horizontally on the screen
			longTitle = longTitle + longTitle
		}
		
		let menu = OBWFilteringMenu()
		menu.addItem(OBWFilteringMenuItem(title: longTitle))
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		let menuView = window.menuView
		
		// Test, the window should be limited to the screen size
		
		let menuLocation = NSPoint(x: geometry.initialBounds.midX, y: geometry.initialBounds.midY)
		let screenLocation = NSPoint(x: screenLimits.midX, y: screenLimits.midY)
		let updateResult = geometry.updateGeometryToDisplayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: true)
		XCTAssertTrue(updateResult)
		
		let menuFrame = NSRect(
			x: screenLocation.x - (geometry.totalMenuItemSize.width / 2.0).rounded(.down),
			y: screenLocation.y - (geometry.totalMenuItemSize.height / 2.0).rounded(.down),
			width: geometry.totalMenuItemSize.width,
			height: geometry.totalMenuItemSize.height
		)
		
		let interiorFrame = menuFrame - menuView.outerMenuMargins
		var windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
		windowFrame.origin.x = screenLimits.minX
		windowFrame.size.width = screenLimits.width
		
		let interiorLimits = screenLimits + OBWFilteringMenuWindow.interiorMargins
		let menuLimits = interiorLimits + menuView.outerMenuMargins
		
		XCTAssertEqual(geometry.frame, windowFrame)
		XCTAssertEqual(geometry.initialBounds.size, geometry.totalMenuItemSize)
		XCTAssertEqual(geometry.finalBounds.width, menuLimits.width)
	}
	
	func testDisplayMenuLocation_MenuOverlapsScreenLeftEdge() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
		
		let menu = OBWFilteringMenu()
		for index in 1...5 {
			menu.addItem(OBWFilteringMenuItem(title: "Item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		let menuView = window.menuView
		
		// Test, the window size fits the entire menu and abuts the left edge of the screen
		
		let menuLocation = NSPoint(x: geometry.initialBounds.midX, y: geometry.initialBounds.midY)
		let screenLocation = NSPoint(x: screenLimits.minX, y: screenLimits.midY)
		let updateResult = geometry.updateGeometryToDisplayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: true)
		XCTAssertTrue(updateResult)
		
		let menuFrame = NSRect(
			x: screenLocation.x - (geometry.totalMenuItemSize.width / 2.0).rounded(.down),
			y: screenLocation.y - (geometry.totalMenuItemSize.height / 2.0).rounded(.down),
			width: geometry.totalMenuItemSize.width,
			height: geometry.totalMenuItemSize.height
		)
		
		let interiorFrame = menuFrame - menuView.outerMenuMargins
		var windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
		windowFrame.origin.x = screenLimits.minX
		
		XCTAssertEqual(geometry.frame, windowFrame)
		XCTAssertEqual(geometry.initialBounds.size, geometry.totalMenuItemSize)
		XCTAssertEqual(geometry.finalBounds.size, geometry.totalMenuItemSize)
		XCTAssertLessThan(geometry.frame.width, screenLimits.width)
	}
	
	func testDisplayMenuLocation_MenuOverlapsScreenRightEdge() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
		
		let menu = OBWFilteringMenu()
		for index in 1...5 {
			menu.addItem(OBWFilteringMenuItem(title: "Item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		let menuView = window.menuView
		
		// Test, the window size fits the entire menu and abuts the right edge of the screen
		
		let menuLocation = NSPoint(x: geometry.initialBounds.midX, y: geometry.initialBounds.midY)
		let screenLocation = NSPoint(x: screenLimits.maxX, y: screenLimits.midY)
		let updateResult = geometry.updateGeometryToDisplayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: true)
		XCTAssertTrue(updateResult)
		
		let menuFrame = NSRect(
			x: screenLocation.x - (geometry.totalMenuItemSize.width / 2.0).rounded(.down),
			y: screenLocation.y - (geometry.totalMenuItemSize.height / 2.0).rounded(.down),
			width: geometry.totalMenuItemSize.width,
			height: geometry.totalMenuItemSize.height
		)
		
		let interiorFrame = menuFrame - menuView.outerMenuMargins
		var windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
		windowFrame.origin.x = screenLimits.maxX - windowFrame.width
		
		XCTAssertEqual(geometry.frame, windowFrame)
		XCTAssertEqual(geometry.initialBounds.size, geometry.totalMenuItemSize)
		XCTAssertEqual(geometry.finalBounds.size, geometry.totalMenuItemSize)
		XCTAssertLessThan(geometry.frame.width, screenLimits.width)
	}
	
	func testDisplayMenuLocation_MenuOverlapsScreenBottomEdge_GrowingUpward() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
		
		let menu = OBWFilteringMenu()
		for index in 1...5 {
			menu.addItem(OBWFilteringMenuItem(title: "Item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		let menuView = window.menuView
		
		// Test, the window size fits the entire menu and abuts the bottom edge of the screen
		
		let menuLocation = NSPoint(x: geometry.initialBounds.midX, y: geometry.initialBounds.midY)
		let screenLocation = NSPoint(x: screenLimits.midX, y: screenLimits.minY)
		let updateResult = geometry.updateGeometryToDisplayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: true)
		XCTAssertTrue(updateResult)
		
		let menuFrame = NSRect(
			x: screenLocation.x - (geometry.totalMenuItemSize.width / 2.0).rounded(.down),
			y: screenLocation.y - (geometry.totalMenuItemSize.height / 2.0).rounded(.down),
			width: geometry.totalMenuItemSize.width,
			height: geometry.totalMenuItemSize.height
		)
		
		let interiorFrame = menuFrame - menuView.outerMenuMargins
		var windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
		windowFrame.origin.y = screenLimits.minY
		
		XCTAssertEqual(geometry.frame, windowFrame)
		XCTAssertEqual(geometry.initialBounds.size, geometry.totalMenuItemSize)
		XCTAssertEqual(geometry.finalBounds.size, geometry.totalMenuItemSize)
		XCTAssertLessThan(geometry.frame.width, screenLimits.width)
	}
	
	func testDisplayMenuLocation_MenuOverlapsScreenBottomEdge_NotGrowingUpward() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
		
		let menu = OBWFilteringMenu()
		for index in 1...5 {
			menu.addItem(OBWFilteringMenuItem(title: "Item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		let menuView = window.menuView
		
		// Test, the window height is clipped and abuts the bottom edge of the screen
		
		let menuLocation = NSPoint(x: geometry.initialBounds.midX, y: geometry.initialBounds.midY)
		let screenLocation = NSPoint(x: screenLimits.midX, y: screenLimits.minY)
		let updateResult = geometry.updateGeometryToDisplayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false)
		XCTAssertTrue(updateResult)
		
		var menuFrame = NSRect(
			x: screenLocation.x - (geometry.totalMenuItemSize.width / 2.0).rounded(.down),
			y: screenLocation.y - (geometry.totalMenuItemSize.height / 2.0).rounded(.down),
			width: geometry.totalMenuItemSize.width,
			height: geometry.totalMenuItemSize.height
		)
		
		var interiorFrame = menuFrame - menuView.outerMenuMargins
		var windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
		
		let distanceBottomIsClipped = screenLimits.minY - windowFrame.minY
		windowFrame.size.height -= distanceBottomIsClipped
		windowFrame.origin.y = screenLimits.minY
		
		interiorFrame = windowFrame + OBWFilteringMenuWindow.interiorMargins
		menuFrame = interiorFrame + menuView.outerMenuMargins
		
		XCTAssertEqual(geometry.frame, windowFrame)
		XCTAssertEqual(geometry.initialBounds.size, menuFrame.size)
		XCTAssertEqual(geometry.finalBounds.size, geometry.totalMenuItemSize)
		XCTAssertLessThan(geometry.frame.width, screenLimits.width)
	}
	
	func testDisplayMenuLocation_MenuTopNearScreenBottomEdge_NotGrowingUpward() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
		
		let menu = OBWFilteringMenu()
		for index in 1...5 {
			menu.addItem(OBWFilteringMenuItem(title: "Item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		let menuView = window.menuView
		
		// Test, the window height is the minimum necessary to show the top of the menu, and abuts the bottom edge of the screen
		
		let menuLocation = NSPoint(x: geometry.initialBounds.midX, y: geometry.initialBounds.maxY)
		let screenLocation = NSPoint(x: screenLimits.midX, y: screenLimits.minY)
		let updateResult = geometry.updateGeometryToDisplayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false)
		XCTAssertTrue(updateResult)
		
		let menuFrame = NSRect(
			x: screenLocation.x - (geometry.totalMenuItemSize.width / 2.0).rounded(.down),
			y: screenLocation.y - (geometry.totalMenuItemSize.height / 2.0).rounded(.down),
			width: geometry.totalMenuItemSize.width,
			height: menuView.minimumHeightAtTop
		)
		
		let interiorFrame = menuFrame - menuView.outerMenuMargins
		var windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
		windowFrame.origin.y = screenLimits.minY
		
		XCTAssertEqual(geometry.frame, windowFrame)
		XCTAssertEqual(geometry.initialBounds.size, menuFrame.size)
		XCTAssertEqual(geometry.finalBounds.size, geometry.totalMenuItemSize)
		XCTAssertLessThan(geometry.frame.width, screenLimits.width)
	}
	
	func testDisplayMenuLocation_MenuOverlapsScreenTopEdge() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
		
		
		let menu = OBWFilteringMenu()
		for index in 1...5 {
			menu.addItem(OBWFilteringMenuItem(title: "Item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		let menuView = window.menuView
		
		// Test, the window height is clipped and abuts the top edge of the screen
		
		let menuLocation = NSPoint(x: geometry.initialBounds.midX, y: geometry.initialBounds.midY)
		let screenLocation = NSPoint(x: screenLimits.midX, y: screenLimits.maxY)
		let updateResult = geometry.updateGeometryToDisplayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false)
		XCTAssertTrue(updateResult)
		
		var menuFrame = NSRect(
			x: screenLocation.x - (geometry.totalMenuItemSize.width / 2.0).rounded(.down),
			y: screenLocation.y - (geometry.totalMenuItemSize.height / 2.0).rounded(.down),
			width: geometry.totalMenuItemSize.width,
			height: geometry.totalMenuItemSize.height
		)
		
		var interiorFrame = menuFrame - menuView.outerMenuMargins
		var windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
		
		let distanceTopIsClipped = windowFrame.maxY - screenLimits.maxY
		windowFrame.size.height -= distanceTopIsClipped
		
		interiorFrame = windowFrame + OBWFilteringMenuWindow.interiorMargins
		menuFrame = interiorFrame + menuView.outerMenuMargins
		
		XCTAssertEqual(geometry.frame, windowFrame)
		XCTAssertEqual(geometry.initialBounds.size, menuFrame.size)
		XCTAssertEqual(geometry.finalBounds.size, geometry.totalMenuItemSize)
		XCTAssertLessThan(geometry.frame.width, screenLimits.width)
	}
	
	func testDisplayMenuLocation_MenuBottomNearScreenTopEdge() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
		
		let menu = OBWFilteringMenu()
		for index in 1...5 {
			menu.addItem(OBWFilteringMenuItem(title: "Item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		let menuView = window.menuView
		
		// Test, the window height is the minimum necessary to show the bottom of the menu, and abuts the top edge of the screen
		
		let menuLocation = NSPoint(x: geometry.initialBounds.midX, y: geometry.initialBounds.minY)
		let screenLocation = NSPoint(x: screenLimits.midX, y: screenLimits.maxY)
		let updateResult = geometry.updateGeometryToDisplayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false)
		XCTAssertTrue(updateResult)
		
		let menuFrame = NSRect(
			x: screenLocation.x - (geometry.totalMenuItemSize.width / 2.0).rounded(.down),
			y: screenLocation.y - (geometry.totalMenuItemSize.height / 2.0).rounded(.down),
			width: geometry.totalMenuItemSize.width,
			height: menuView.minimumHeightAtBottom
		)
		
		let interiorFrame = menuFrame - menuView.outerMenuMargins
		var windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
		windowFrame.origin.y = screenLimits.maxY - windowFrame.height
		
		XCTAssertEqual(geometry.frame, windowFrame)
		XCTAssertEqual(geometry.initialBounds.size, menuFrame.size)
		XCTAssertEqual(geometry.finalBounds.size, geometry.totalMenuItemSize)
		XCTAssertLessThan(geometry.frame.width, screenLimits.width)
	}
	
	// MARK: - updateGeometryToDisplayMenuLocation(_:adjacentToScreenArea:preferredAlignment:)
	
	func testDisplayAdjacentToScreenArea_CenterArea() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
		
		let menu = OBWFilteringMenu()
		for index in 1...5 {
			menu.addItem(OBWFilteringMenuItem(title: "Item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		
		// Test
		
		let menuLocation = NSPoint(x: geometry.initialBounds.minX, y: geometry.initialBounds.maxY)
		
		let screenAreaSize = NSSize(width: 40.0, height: 20.0)
		
		let screenArea = NSRect(
			x: screenLimits.midX - (screenAreaSize.width / 2.0).rounded(.down),
			y: screenLimits.midY - (screenAreaSize.height / 2.0).rounded(.down),
			width: screenAreaSize.width,
			height: screenAreaSize.height
		)
		
		let rightAlignment = geometry.updateGeometryToDisplayMenuLocation(menuLocation, adjacentToScreenArea: screenArea, preferredAlignment: .trailing)
		XCTAssertEqual(rightAlignment, OBWFilteringMenu.SubmenuAlignment.trailing)
		
		let leftAlignment = geometry.updateGeometryToDisplayMenuLocation(menuLocation, adjacentToScreenArea: screenArea, preferredAlignment: .leading)
		XCTAssertEqual(leftAlignment, OBWFilteringMenu.SubmenuAlignment.leading)
	}
	
	func testDisplayAdjacentToScreenArea_AreaNearLeftScreenEdge() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenFrame = screen.frame
		let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
		
		
		let menu = OBWFilteringMenu()
		for index in 1...5 {
			menu.addItem(OBWFilteringMenuItem(title: "Item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		
		// Test
		
		let menuLocation = NSPoint(x: geometry.initialBounds.minX, y: geometry.initialBounds.maxY)
		
		let screenAreaSize = NSSize(width: 40.0, height: 20.0)
		
		let screenArea = NSRect(
			x: screenLimits.minX,
			y: screenFrame.midY - (screenAreaSize.height / 2.0).rounded(.down),
			width: screenAreaSize.width,
			height: screenAreaSize.height
		)
		
		let rightAlignment = geometry.updateGeometryToDisplayMenuLocation(menuLocation, adjacentToScreenArea: screenArea, preferredAlignment: .trailing)
		XCTAssertEqual(rightAlignment, OBWFilteringMenu.SubmenuAlignment.trailing)
		
		let leftAlignment = geometry.updateGeometryToDisplayMenuLocation(menuLocation, adjacentToScreenArea: screenArea, preferredAlignment: .leading)
		XCTAssertEqual(leftAlignment, OBWFilteringMenu.SubmenuAlignment.trailing)
	}
	
	func testDisplayAdjacentToScreenArea_AreaNearRightScreenEdge() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenFrame = screen.frame
		let screenLimits = screenFrame + OBWFilteringMenuWindowGeometry.screenMargins
		
		let menu = OBWFilteringMenu()
		for index in 1...5 {
			menu.addItem(OBWFilteringMenuItem(title: "Item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		
		// Test
		
		let menuLocation = NSPoint(x: geometry.initialBounds.minX, y: geometry.initialBounds.maxY)
		
		let screenAreaSize = NSSize(width: 40.0, height: 20.0)
		
		let screenArea = NSRect(
			x: screenLimits.maxX - screenAreaSize.width,
			y: screenFrame.midY - (screenAreaSize.height / 2.0).rounded(.down),
			width: screenAreaSize.width,
			height: screenAreaSize.height
		)
		
		let rightAlignment = geometry.updateGeometryToDisplayMenuLocation(menuLocation, adjacentToScreenArea: screenArea, preferredAlignment: .trailing)
		XCTAssertEqual(rightAlignment, OBWFilteringMenu.SubmenuAlignment.leading)
		
		let leftAlignment = geometry.updateGeometryToDisplayMenuLocation(menuLocation, adjacentToScreenArea: screenArea, preferredAlignment: .leading)
		XCTAssertEqual(leftAlignment, OBWFilteringMenu.SubmenuAlignment.leading)
	}
	
	// MARK: - updateGeometryWithResizedMenu()
	
	func testUpdateWithResizedMenu_SmallAnchor() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenFrame = screen.frame
		
		let menu = OBWFilteringMenu()
		for index in 1...9 {
			menu.addItem(OBWFilteringMenuItem(title: "Item \(index)"))
		}
		
		let interiorMargins = OBWFilteringMenuWindow.interiorMargins
		
		let anchorSize = NSSize(width: 100.0, height: 10.0)
		
		var screenAnchor = NSRect(
			x: screenFrame.midX - anchorSize.width,
			y: screenFrame.midY - (anchorSize.height / 2.0).rounded(.down),
			width: anchorSize.width,
			height: anchorSize.height
		)
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		let outerMenuMargins = window.menuView.outerMenuMargins
		
		let menuLocation = NSPoint(x: 0.0, y: geometry.initialBounds.midY)
		geometry.updateGeometryToDisplayMenuLocation(menuLocation, adjacentToScreenArea: screenAnchor, preferredAlignment: .trailing)
		
		var preResizeHeight: CGFloat = 0.0
		
		// Window spans anchor > no anchor alignment
		
		preResizeHeight = geometry.frame.height
		
		window.screenAnchor = screenAnchor
		
		window.menuView.applyFilterResults(OBWFilteringMenuItemFilterStatus.filterStatus(menu, filterString: "g/[1-8]/"))
		geometry.updateGeometryWithResizedMenu(constrainToAnchor: true)
		
		XCTAssertLessThan(geometry.frame.height, preResizeHeight)
		XCTAssertLessThan(screenAnchor.height, geometry.frame.height)
		XCTAssertGreaterThan(geometry.frame.maxY, screenAnchor.maxY)
		XCTAssertLessThan(geometry.frame.minY, screenAnchor.minY)
		
		// Window overlaps bottom of anchor > top alignment
		
		preResizeHeight = geometry.frame.height
		
		screenAnchor.origin.y = geometry.frame.maxY - (anchorSize.height / 2.0).rounded(.down)
		window.screenAnchor = screenAnchor
		
		window.menuView.applyFilterResults(OBWFilteringMenuItemFilterStatus.filterStatus(menu, filterString: "g/[1-7]/"))
		geometry.updateGeometryWithResizedMenu(constrainToAnchor: true)
		
		XCTAssertLessThan(geometry.frame.height, preResizeHeight)
		XCTAssertLessThan(screenAnchor.height, geometry.frame.height)
		XCTAssertEqual(geometry.frame.maxY, screenAnchor.maxY + interiorMargins.top + outerMenuMargins.top)
		
		// Window overlaps top of anchor > bottom alignment
		
		preResizeHeight = geometry.frame.height
		
		screenAnchor.origin.y = geometry.frame.minY - (anchorSize.height / 2.0).rounded(.down)
		window.screenAnchor = screenAnchor
		
		window.menuView.applyFilterResults(OBWFilteringMenuItemFilterStatus.filterStatus(menu, filterString: "g/[1-6]/"))
		geometry.updateGeometryWithResizedMenu(constrainToAnchor: true)
		
		XCTAssertLessThan(geometry.frame.height, preResizeHeight)
		XCTAssertLessThan(screenAnchor.height, geometry.frame.height)
		XCTAssertEqual(geometry.frame.minY, screenAnchor.minY - interiorMargins.bottom - outerMenuMargins.bottom)
		
		// Window below anchor > top alignment
		
		preResizeHeight = geometry.frame.height
		
		screenAnchor.origin.y = geometry.frame.maxY + (anchorSize.height / 2.0).rounded(.down)
		window.screenAnchor = screenAnchor
		
		window.menuView.applyFilterResults(OBWFilteringMenuItemFilterStatus.filterStatus(menu, filterString: "g/[1-5]/"))
		geometry.updateGeometryWithResizedMenu(constrainToAnchor: true)
		
		XCTAssertLessThan(geometry.frame.height, preResizeHeight)
		XCTAssertLessThan(screenAnchor.height, geometry.frame.height)
		XCTAssertEqual(geometry.frame.maxY, screenAnchor.maxY + interiorMargins.top + outerMenuMargins.top)
		
		// Window above anchor > bottom alignment
		
		preResizeHeight = geometry.frame.height
		
		screenAnchor.origin.y = geometry.frame.minY - (anchorSize.height * 2.0)
		window.screenAnchor = screenAnchor
		
		window.menuView.applyFilterResults(OBWFilteringMenuItemFilterStatus.filterStatus(menu, filterString: "g/[1-4]/"))
		geometry.updateGeometryWithResizedMenu(constrainToAnchor: true)
		
		XCTAssertLessThan(geometry.frame.height, preResizeHeight)
		XCTAssertLessThan(screenAnchor.height, geometry.frame.height)
		XCTAssertEqual(geometry.frame.minY, screenAnchor.minY - interiorMargins.bottom - outerMenuMargins.bottom)
	}
	
	func testUpdateWithResizedMenu_LargeAnchor() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenFrame = screen.frame
		let screenLimits = screenFrame + OBWFilteringMenuWindowGeometry.screenMargins
		
		let menu = OBWFilteringMenu()
		for index in 1...9 {
			menu.addItem(OBWFilteringMenuItem(title: "Item \(index)"))
		}
		
		let interiorMargins = OBWFilteringMenuWindow.interiorMargins
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		let outerMenuMargins = window.menuView.outerMenuMargins
		
		let anchorSize = NSSize(width: 100.0, height: geometry.frame.height + 40.0)
		
		var screenAnchor = NSRect(
			x: screenFrame.midX - anchorSize.width,
			y: screenFrame.midY - (anchorSize.height / 2.0).rounded(.down),
			width: anchorSize.width,
			height: anchorSize.height
		)
		
		let menuLocation = NSPoint(x: 0.0, y: geometry.initialBounds.midY)
		geometry.updateGeometryToDisplayMenuLocation(menuLocation, adjacentToScreenArea: screenAnchor, preferredAlignment: .trailing)
		
		var preResizeHeight: CGFloat = 0.0
		
		// Window within anchor > top alignment
		
		preResizeHeight = geometry.frame.height
		
		screenAnchor.origin.y = geometry.frame.minY - 20.0
		window.screenAnchor = screenAnchor
		
		window.menuView.applyFilterResults(OBWFilteringMenuItemFilterStatus.filterStatus(menu, filterString: "g/[1-8]/"))
		geometry.updateGeometryWithResizedMenu(constrainToAnchor: true)
		
		XCTAssertGreaterThan(screenAnchor.height, geometry.frame.height)
		XCTAssertLessThan(geometry.frame.height, preResizeHeight)
		XCTAssertEqual(geometry.frame.maxY, screenAnchor.maxY + interiorMargins.top + outerMenuMargins.top)
		
		// Window overlaps top of anchor > top alignment
		
		preResizeHeight = geometry.frame.height
		
		screenAnchor.origin.y = screenLimits.minY
		window.screenAnchor = screenAnchor
		
		window.menuView.applyFilterResults(OBWFilteringMenuItemFilterStatus.filterStatus(menu, filterString: "g/[1-7]/"))
		geometry.updateGeometryWithResizedMenu(constrainToAnchor: true)
		
		XCTAssertGreaterThan(screenAnchor.height, geometry.frame.height)
		XCTAssertLessThan(geometry.frame.height, preResizeHeight)
		XCTAssertEqual(geometry.frame.maxY, screenAnchor.maxY + interiorMargins.top + outerMenuMargins.top)
		
		// Window overlaps bottom of anchor > bottom alignment
		
		preResizeHeight = geometry.frame.height
		
		screenAnchor.origin.y = geometry.frame.midY
		window.screenAnchor = screenAnchor
		
		window.menuView.applyFilterResults(OBWFilteringMenuItemFilterStatus.filterStatus(menu, filterString: "g/[1-6]/"))
		geometry.updateGeometryWithResizedMenu(constrainToAnchor: true)
		
		XCTAssertGreaterThan(screenAnchor.height, geometry.frame.height)
		XCTAssertLessThan(geometry.frame.height, preResizeHeight)
		XCTAssertEqual(geometry.frame.maxY, screenAnchor.maxY + interiorMargins.top + outerMenuMargins.top)
		
		// Window above anchor > top alignment
		
		preResizeHeight = geometry.frame.height
		
		screenAnchor.origin.y = geometry.frame.minY - geometry.frame.height - 40.0
		window.screenAnchor = screenAnchor
		
		window.menuView.applyFilterResults(OBWFilteringMenuItemFilterStatus.filterStatus(menu, filterString: "g/[1-5]/"))
		geometry.updateGeometryWithResizedMenu(constrainToAnchor: true)
		
		XCTAssertGreaterThan(screenAnchor.height, geometry.frame.height)
		XCTAssertLessThan(geometry.frame.height, preResizeHeight)
		XCTAssertEqual(geometry.frame.maxY, screenAnchor.maxY + interiorMargins.top + outerMenuMargins.top)
		
		// Window below anchor > bottom alignment
		
		preResizeHeight = geometry.frame.height
		
		screenAnchor.origin.y = geometry.frame.maxY + 20.0
		window.screenAnchor = screenAnchor
		
		window.menuView.applyFilterResults(OBWFilteringMenuItemFilterStatus.filterStatus(menu, filterString: "g/[1-4]/"))
		geometry.updateGeometryWithResizedMenu(constrainToAnchor: true)
		
		XCTAssertGreaterThan(screenAnchor.height, geometry.frame.height)
		XCTAssertLessThan(geometry.frame.height, preResizeHeight)
		XCTAssertEqual(geometry.frame.maxY, screenAnchor.maxY + interiorMargins.top + outerMenuMargins.top)
	}
	
	// MARK: - updateGeometryToDisplayMenuItemBounds(_:)
	
	func testDisplayMenuItemBounds() throws {
		// Setup
		
		let screen = NSScreen.screens[0]
		let screenFrame = screen.frame
		
		let menu = OBWFilteringMenu()
		for index in 1...20 {
			menu.addItem(OBWFilteringMenuItem(title: "Item \(index)"))
		}
		
		let window = OBWFilteringMenuWindow(menu: menu, onScreen: screen, minimumWidth: OBWFilteringMenuItemView.minimumWidth)
		let geometry = OBWFilteringMenuWindowGeometry(window: window)
		
		let menuLocation = NSPoint(x: 0.0, y: geometry.initialBounds.maxY)
		let screenLocation = NSPoint(x: screenFrame.midX, y: screenFrame.minY)
		geometry.updateGeometryToDisplayMenuLocation(menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false)
		
		// Test scrolling content up - window frame changes by visible content height change
		
		var scrollDistance = (geometry.initialBounds.height / 4.0).rounded(.down)
		
		var scrolledBounds = NSRect(
			x: geometry.initialBounds.minX,
			y: geometry.initialBounds.minY - scrollDistance,
			width: geometry.initialBounds.width,
			height: geometry.initialBounds.height + scrollDistance
		)
		
		var preScrollFrame = geometry.frame
		
		geometry.updateGeometryToDisplayMenuItemBounds(scrolledBounds)
		
		XCTAssertEqual(geometry.frame.height, preScrollFrame.height + scrollDistance)
		
		// Test scrolling content down - no window frame change
		
		scrollDistance = -(scrollDistance / 2.0).rounded(.down)
		
		scrolledBounds = NSRect(
			x: geometry.initialBounds.minX,
			y: geometry.initialBounds.minY - scrollDistance,
			width: geometry.initialBounds.width,
			height: geometry.initialBounds.height
		)
		
		preScrollFrame = geometry.frame
		
		geometry.updateGeometryToDisplayMenuItemBounds(scrolledBounds)
		
		XCTAssertEqual(geometry.frame.height, preScrollFrame.height)
	}
}
