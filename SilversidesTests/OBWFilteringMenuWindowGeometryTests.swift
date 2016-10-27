/*===========================================================================
 OBWFilteringMenuWindowGeometryTests.swift
 Silversides
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import XCTest
@testable import OBWControls

/*==========================================================================*/

class OBWFilteringMenuWindowGeometryTests: XCTestCase {
    
    /*==========================================================================*/
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    /*==========================================================================*/
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    /*==========================================================================*/
    // MARK: - NSScreen.screenContainingLocation(_)
    
    /*==========================================================================*/
    func testThatTheCorrectScreenIsFoundFromLocationInDesktopSpace() {
        
        var desktopBounds = NSZeroRect
        
        for screen in NSScreen.screens()! {
            
            let screenFrame = screen.frame
            
            desktopBounds = NSUnionRect( desktopBounds, screenFrame )
            
            let point1 = NSPoint(
                x: screenFrame.origin.x + round( screenFrame.size.width / 2.0 ),
                y: screenFrame.origin.y + round( screenFrame.size.height / 2.0 )
            )
            XCTAssertTrue( NSScreen.screenContainingLocation( point1 ) === screen )
            
            let point2 = NSPoint(
                x: point1.x + screenFrame.size.width,
                y: point1.y
            )
            XCTAssertFalse( NSScreen.screenContainingLocation( point2 ) === screen )
            
            let point3 = NSPoint(
                x: screenFrame.origin.x + 1.0,
                y: screenFrame.origin.y + 1.0
            )
            XCTAssertTrue( NSScreen.screenContainingLocation( point3 ) === screen )
            
            let point4 = NSPoint(
                x: point3.x + screenFrame.size.width,
                y: point3.y
            )
            XCTAssertFalse( NSScreen.screenContainingLocation( point4 ) === screen )
            
            let point5 = NSPoint(
                x: screenFrame.origin.x + 1.0,
                y: screenFrame.origin.y + screenFrame.size.height - 1.0
            )
            XCTAssertTrue( NSScreen.screenContainingLocation( point5 ) === screen )
            
            let point6 = NSPoint(
                x: point5.x + screenFrame.size.width,
                y: point5.y
            )
            XCTAssertFalse( NSScreen.screenContainingLocation( point6 ) === screen )
            
            let point7 = NSPoint(
                x: screenFrame.origin.x + screenFrame.size.width - 1.0,
                y: screenFrame.origin.y + screenFrame.size.height - 1.0
            )
            XCTAssertTrue( NSScreen.screenContainingLocation( point7 ) === screen )
            
            let point8 = NSPoint(
                x: point7.x + screenFrame.size.width,
                y: point7.y
            )
            XCTAssertFalse( NSScreen.screenContainingLocation( point8 ) === screen )
            
            let point9 = NSPoint(
                x: screenFrame.origin.x + screenFrame.size.width - 1.0,
                y: screenFrame.origin.y + 1.0
            )
            XCTAssertTrue( NSScreen.screenContainingLocation( point9 ) === screen )
            
            let point10 = NSPoint(
                x: point9.x + screenFrame.size.width,
                y: point9.y
            )
            XCTAssertFalse( NSScreen.screenContainingLocation( point10 ) === screen )
            
            let point11 = NSPoint(
                x: desktopBounds.origin.x - 1.0,
                y: desktopBounds.origin.y - 1.0
            )
            XCTAssertNil( NSScreen.screenContainingLocation( point11 ) )
        }
    }
    
    /*==========================================================================*/
    // MARK: - init(window:)
    
    /*==========================================================================*/
    func testInitialGeometryLimitedToMenuSize() {
        
        let screen = NSScreen.screens()!.first!
        
        let menu = OBWFilteringMenu()
        for index in 1...5 {
            menu.addItem( OBWFilteringMenuItem( title: "Item \(index)") )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen)
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        
        XCTAssertEqual( geometry.initialBounds.size.height, geometry.totalMenuItemSize.height )
        XCTAssertEqual( geometry.finalBounds.size.height, geometry.totalMenuItemSize.height )
    }
    
    /*==========================================================================*/
    func testInitialGeometryLimitedToScreenSize() {
        
        let screen = NSScreen.screens()!.first!
        
        let menu = OBWFilteringMenu()
        for index in 1...200 {
            // There need to be enough items such that the menu is taller than the current screen
            menu.addItem( OBWFilteringMenuItem( title: "Item \(index)" ) )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        
        XCTAssertEqual( geometry.initialBounds.size.height, geometry.finalBounds.size.height )
        XCTAssertTrue( geometry.initialBounds.size.height < geometry.totalMenuItemSize.height )
        XCTAssertTrue( geometry.finalBounds.size.height < geometry.totalMenuItemSize.height )
    }
    
    /*==========================================================================*/
    // MARK: - updateGeometryToDisplayMenuLocation(_:atScreenLocation:allowWindowToGrowUpward:)
    
    /*==========================================================================*/
    func testDisplayMenuLocation_MenuWidthFitsScreen() {
        
        // Setup
        
        let screen = NSScreen.screens()!.first!
        let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
        
        let menu = OBWFilteringMenu()
        for index in 1...5 {
            menu.addItem( OBWFilteringMenuItem( title: "Item \(index)") )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        let menuView = window.menuView
        
        // Test, the window size fits the entire menu
        
        let menuLocation = NSPoint( x: geometry.initialBounds.midX, y: geometry.initialBounds.midY )
        let screenLocation = NSPoint( x: screenLimits.midX, y: screenLimits.midY )
        let updateResult = geometry.updateGeometryToDisplayMenuLocation( menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: true )
        XCTAssertTrue( updateResult )
        
        let menuFrame = NSRect(
            x: screenLocation.x - floor( geometry.totalMenuItemSize.width / 2.0 ),
            y: screenLocation.y - floor( geometry.totalMenuItemSize.height / 2.0 ),
            width: geometry.totalMenuItemSize.width,
            height: geometry.totalMenuItemSize.height
        )
        
        let interiorFrame = menuFrame - menuView.outerMenuMargins
        let windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
        
        XCTAssertEqual( geometry.frame, windowFrame )
        XCTAssertEqual( geometry.initialBounds.size, geometry.totalMenuItemSize )
        XCTAssertEqual( geometry.finalBounds.size, geometry.totalMenuItemSize )
        XCTAssertTrue( geometry.frame.width < screenLimits.size.width )
    }
    
    /*==========================================================================*/
    func testDisplayMenuLocation_MenuWidthWiderThanScreen() {
        
        // Setup
        
        let screen = NSScreen.screens()!.first!
        let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
        
        var longTitle = "Item with an enormously wide title"
        for _ in 1...4 {
            // The title needs to be too wide to fit horizontally on the screen
            longTitle = longTitle + longTitle
        }
        
        let menu = OBWFilteringMenu()
        menu.addItem( OBWFilteringMenuItem( title: longTitle ) )
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        let menuView = window.menuView
        
        // Test, the window should be limited to the screen size
        
        let menuLocation = NSPoint( x: geometry.initialBounds.midX, y: geometry.initialBounds.midY )
        let screenLocation = NSPoint( x: screenLimits.midX, y: screenLimits.midY )
        let updateResult = geometry.updateGeometryToDisplayMenuLocation( menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: true )
        XCTAssertTrue( updateResult )
        
        let menuFrame = NSRect(
            x: screenLocation.x - floor( geometry.totalMenuItemSize.width / 2.0 ),
            y: screenLocation.y - floor( geometry.totalMenuItemSize.height / 2.0 ),
            width: geometry.totalMenuItemSize.width,
            height: geometry.totalMenuItemSize.height
        )
        
        let interiorFrame = menuFrame - menuView.outerMenuMargins
        var windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
        windowFrame.origin.x = screenLimits.origin.x
        windowFrame.size.width = screenLimits.size.width
        
        let interiorLimits = screenLimits + OBWFilteringMenuWindow.interiorMargins
        let menuLimits = interiorLimits + menuView.outerMenuMargins
        
        XCTAssertEqual( geometry.frame, windowFrame )
        XCTAssertEqual( geometry.initialBounds.size, geometry.totalMenuItemSize )
        XCTAssertEqual( geometry.finalBounds.size.width, menuLimits.size.width )
    }
    
    /*==========================================================================*/
    func testDisplayMenuLocation_MenuOverlapsScreenLeftEdge() {
        
        // Setup
        
        let screen = NSScreen.screens()!.first!
        let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
        
        let menu = OBWFilteringMenu()
        for index in 1...5 {
            menu.addItem( OBWFilteringMenuItem( title: "Item \(index)") )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        let menuView = window.menuView
        
        // Test, the window size fits the entire menu and abuts the left edge of the screen
        
        let menuLocation = NSPoint( x: geometry.initialBounds.midX, y: geometry.initialBounds.midY )
        let screenLocation = NSPoint( x: screenLimits.origin.x, y: screenLimits.midY )
        let updateResult = geometry.updateGeometryToDisplayMenuLocation( menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: true )
        XCTAssertTrue( updateResult )
        
        let menuFrame = NSRect(
            x: screenLocation.x - floor( geometry.totalMenuItemSize.width / 2.0 ),
            y: screenLocation.y - floor( geometry.totalMenuItemSize.height / 2.0 ),
            width: geometry.totalMenuItemSize.width,
            height: geometry.totalMenuItemSize.height
        )
        
        let interiorFrame = menuFrame - menuView.outerMenuMargins
        var windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
        windowFrame.origin.x = screenLimits.origin.x
        
        XCTAssertEqual( geometry.frame, windowFrame )
        XCTAssertEqual( geometry.initialBounds.size, geometry.totalMenuItemSize )
        XCTAssertEqual( geometry.finalBounds.size, geometry.totalMenuItemSize )
        XCTAssertTrue( geometry.frame.width < screenLimits.size.width )
    }
    
    /*==========================================================================*/
    func testDisplayMenuLocation_MenuOverlapsScreenRightEdge() {
        
        // Setup
        
        let screen = NSScreen.screens()!.first!
        let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
        
        let menu = OBWFilteringMenu()
        for index in 1...5 {
            menu.addItem( OBWFilteringMenuItem( title: "Item \(index)") )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        let menuView = window.menuView
        
        // Test, the window size fits the entire menu and abuts the right edge of the screen
        
        let menuLocation = NSPoint( x: geometry.initialBounds.midX, y: geometry.initialBounds.midY )
        let screenLocation = NSPoint( x: screenLimits.maxX, y: screenLimits.midY )
        let updateResult = geometry.updateGeometryToDisplayMenuLocation( menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: true )
        XCTAssertTrue( updateResult )
        
        let menuFrame = NSRect(
            x: screenLocation.x - floor( geometry.totalMenuItemSize.width / 2.0 ),
            y: screenLocation.y - floor( geometry.totalMenuItemSize.height / 2.0 ),
            width: geometry.totalMenuItemSize.width,
            height: geometry.totalMenuItemSize.height
        )
        
        let interiorFrame = menuFrame - menuView.outerMenuMargins
        var windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
        windowFrame.origin.x = screenLimits.maxX - windowFrame.size.width
        
        XCTAssertEqual( geometry.frame, windowFrame )
        XCTAssertEqual( geometry.initialBounds.size, geometry.totalMenuItemSize )
        XCTAssertEqual( geometry.finalBounds.size, geometry.totalMenuItemSize )
        XCTAssertTrue( geometry.frame.width < screenLimits.size.width )
    }
    
    /*==========================================================================*/
    func testDisplayMenuLocation_MenuOverlapsScreenBottomEdge_GrowingUpward() {
        
        // Setup
        
        let screen = NSScreen.screens()!.first!
        let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
        
        let menu = OBWFilteringMenu()
        for index in 1...5 {
            menu.addItem( OBWFilteringMenuItem( title: "Item \(index)") )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        let menuView = window.menuView
        
        // Test, the window size fits the entire menu and abuts the bottom edge of the screen
        
        let menuLocation = NSPoint( x: geometry.initialBounds.midX, y: geometry.initialBounds.midY )
        let screenLocation = NSPoint( x: screenLimits.midX, y: screenLimits.origin.y )
        let updateResult = geometry.updateGeometryToDisplayMenuLocation( menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: true )
        XCTAssertTrue( updateResult )
        
        let menuFrame = NSRect(
            x: screenLocation.x - floor( geometry.totalMenuItemSize.width / 2.0 ),
            y: screenLocation.y - floor( geometry.totalMenuItemSize.height / 2.0 ),
            width: geometry.totalMenuItemSize.width,
            height: geometry.totalMenuItemSize.height
        )
        
        let interiorFrame = menuFrame - menuView.outerMenuMargins
        var windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
        windowFrame.origin.y = screenLimits.origin.y
        
        XCTAssertEqual( geometry.frame, windowFrame )
        XCTAssertEqual( geometry.initialBounds.size, geometry.totalMenuItemSize )
        XCTAssertEqual( geometry.finalBounds.size, geometry.totalMenuItemSize )
        XCTAssertTrue( geometry.frame.width < screenLimits.size.width )
    }
    
    /*==========================================================================*/
    func testDisplayMenuLocation_MenuOverlapsScreenBottomEdge_NotGrowingUpward() {
        
        // Setup
        
        let screen = NSScreen.screens()!.first!
        let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
        
        let menu = OBWFilteringMenu()
        for index in 1...5 {
            menu.addItem( OBWFilteringMenuItem( title: "Item \(index)") )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        let menuView = window.menuView
        
        // Test, the window height is clipped and abuts the bottom edge of the screen
        
        let menuLocation = NSPoint( x: geometry.initialBounds.midX, y: geometry.initialBounds.midY )
        let screenLocation = NSPoint( x: screenLimits.midX, y: screenLimits.origin.y )
        let updateResult = geometry.updateGeometryToDisplayMenuLocation( menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false )
        XCTAssertTrue( updateResult )
        
        var menuFrame = NSRect(
            x: screenLocation.x - floor( geometry.totalMenuItemSize.width / 2.0 ),
            y: screenLocation.y - floor( geometry.totalMenuItemSize.height / 2.0 ),
            width: geometry.totalMenuItemSize.width,
            height: geometry.totalMenuItemSize.height
        )
        
        var interiorFrame = menuFrame - menuView.outerMenuMargins
        var windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
        
        let distanceBottomIsClipped = screenLimits.origin.y - windowFrame.origin.y
        windowFrame.size.height -= distanceBottomIsClipped
        windowFrame.origin.y = screenLimits.origin.y
        
        interiorFrame = windowFrame + OBWFilteringMenuWindow.interiorMargins
        menuFrame = interiorFrame + menuView.outerMenuMargins
        
        XCTAssertEqual( geometry.frame, windowFrame )
        XCTAssertEqual( geometry.initialBounds.size, menuFrame.size )
        XCTAssertEqual( geometry.finalBounds.size, geometry.totalMenuItemSize )
        XCTAssertTrue( geometry.frame.width < screenLimits.size.width )
    }
    
    /*==========================================================================*/
    func testDisplayMenuLocation_MenuTopNearScreenBottomEdge_NotGrowingUpward() {
        
        // Setup
        
        let screen = NSScreen.screens()!.first!
        let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
        
        let menu = OBWFilteringMenu()
        for index in 1...5 {
            menu.addItem( OBWFilteringMenuItem( title: "Item \(index)") )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        let menuView = window.menuView
        
        // Test, the window height is the minimum necessary to show the top of the menu, and abuts the bottom edge of the screen
        
        let menuLocation = NSPoint( x: geometry.initialBounds.midX, y: geometry.initialBounds.maxY )
        let screenLocation = NSPoint( x: screenLimits.midX, y: screenLimits.origin.y )
        let updateResult = geometry.updateGeometryToDisplayMenuLocation( menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false )
        XCTAssertTrue( updateResult )
        
        let menuFrame = NSRect(
            x: screenLocation.x - floor( geometry.totalMenuItemSize.width / 2.0 ),
            y: screenLocation.y - floor( geometry.totalMenuItemSize.height / 2.0 ),
            width: geometry.totalMenuItemSize.width,
            height: menuView.minimumHeightAtTop
        )
        
        let interiorFrame = menuFrame - menuView.outerMenuMargins
        var windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
        windowFrame.origin.y = screenLimits.origin.y
        
        XCTAssertEqual( geometry.frame, windowFrame )
        XCTAssertEqual( geometry.initialBounds.size, menuFrame.size )
        XCTAssertEqual( geometry.finalBounds.size, geometry.totalMenuItemSize )
        XCTAssertTrue( geometry.frame.width < screenLimits.size.width )
    }
    
    /*==========================================================================*/
    func testDisplayMenuLocation_MenuOverlapsScreenTopEdge() {
        
        // Setup
        
        let screen = NSScreen.screens()!.first!
        let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins

        
        let menu = OBWFilteringMenu()
        for index in 1...5 {
            menu.addItem( OBWFilteringMenuItem( title: "Item \(index)") )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        let menuView = window.menuView
        
        // Test, the window height is clipped and abuts the top edge of the screen
        
        let menuLocation = NSPoint( x: geometry.initialBounds.midX, y: geometry.initialBounds.midY )
        let screenLocation = NSPoint( x: screenLimits.midX, y: screenLimits.maxY )
        let updateResult = geometry.updateGeometryToDisplayMenuLocation( menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false )
        XCTAssertTrue( updateResult )
        
        var menuFrame = NSRect(
            x: screenLocation.x - floor( geometry.totalMenuItemSize.width / 2.0 ),
            y: screenLocation.y - floor( geometry.totalMenuItemSize.height / 2.0 ),
            width: geometry.totalMenuItemSize.width,
            height: geometry.totalMenuItemSize.height
        )
        
        var interiorFrame = menuFrame - menuView.outerMenuMargins
        var windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
        
        let distanceTopIsClipped = windowFrame.maxY - screenLimits.maxY
        windowFrame.size.height -= distanceTopIsClipped
        
        interiorFrame = windowFrame + OBWFilteringMenuWindow.interiorMargins
        menuFrame = interiorFrame + menuView.outerMenuMargins
        
        XCTAssertEqual( geometry.frame, windowFrame )
        XCTAssertEqual( geometry.initialBounds.size, menuFrame.size )
        XCTAssertEqual( geometry.finalBounds.size, geometry.totalMenuItemSize )
        XCTAssertTrue( geometry.frame.width < screenLimits.size.width )
    }
    
    /*==========================================================================*/
    func testDisplayMenuLocation_MenuBottomNearScreenTopEdge() {
        
        // Setup
        
        let screen = NSScreen.screens()!.first!
        let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
        
        let menu = OBWFilteringMenu()
        for index in 1...5 {
            menu.addItem( OBWFilteringMenuItem( title: "Item \(index)") )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        let menuView = window.menuView
        
        // Test, the window height is the minimum necessary to show the bottom of the menu, and abuts the top edge of the screen
        
        let menuLocation = NSPoint( x: geometry.initialBounds.midX, y: geometry.initialBounds.minY )
        let screenLocation = NSPoint( x: screenLimits.midX, y: screenLimits.maxY )
        let updateResult = geometry.updateGeometryToDisplayMenuLocation( menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false )
        XCTAssertTrue( updateResult )
        
        let menuFrame = NSRect(
            x: screenLocation.x - floor( geometry.totalMenuItemSize.width / 2.0 ),
            y: screenLocation.y - floor( geometry.totalMenuItemSize.height / 2.0 ),
            width: geometry.totalMenuItemSize.width,
            height: menuView.minimumHeightAtBottom
        )
        
        let interiorFrame = menuFrame - menuView.outerMenuMargins
        var windowFrame = interiorFrame - OBWFilteringMenuWindow.interiorMargins
        windowFrame.origin.y = screenLimits.maxY - windowFrame.size.height
        
        XCTAssertEqual( geometry.frame, windowFrame )
        XCTAssertEqual( geometry.initialBounds.size, menuFrame.size )
        XCTAssertEqual( geometry.finalBounds.size, geometry.totalMenuItemSize )
        XCTAssertTrue( geometry.frame.width < screenLimits.size.width )
    }
    
    /*==========================================================================*/
    // MARK: - updateGeometryToDisplayMenuLocation(_:adjacentToScreenArea:preferredAlignment:)
    
    /*==========================================================================*/
    func testDisplayAdjacentToScreenArea_CenterArea() {
        
        // Setup
        
        let screen = NSScreen.screens()!.first!
        let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
        
        let menu = OBWFilteringMenu()
        for index in 1...5 {
            menu.addItem( OBWFilteringMenuItem( title: "Item \(index)") )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        
        // Test
        
        let menuLocation = NSPoint( x: geometry.initialBounds.minX, y: geometry.initialBounds.maxY )
        
        let screenAreaSize = NSSize( width: 40.0, height: 20.0 )
        
        let screenArea = NSRect(
            x: screenLimits.midX - floor( screenAreaSize.width / 2.0 ),
            y: screenLimits.midY - floor( screenAreaSize.height / 2.0 ),
            width: screenAreaSize.width,
            height: screenAreaSize.height
        )
        
        let rightAlignment = geometry.updateGeometryToDisplayMenuLocation( menuLocation, adjacentToScreenArea: screenArea, preferredAlignment: .Right )
        XCTAssertEqual( rightAlignment, OBWFilteringMenuAlignment.Right )
        
        let leftAlignment = geometry.updateGeometryToDisplayMenuLocation( menuLocation, adjacentToScreenArea: screenArea, preferredAlignment: .Left )
        XCTAssertEqual( leftAlignment, OBWFilteringMenuAlignment.Left )
    }
    
    /*==========================================================================*/
    func testDisplayAdjacentToScreenArea_AreaNearLeftScreenEdge() {
        
        // Setup
        
        let screen = NSScreen.screens()!.first!
        let screenFrame = screen.frame
        let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins

        
        let menu = OBWFilteringMenu()
        for index in 1...5 {
            menu.addItem( OBWFilteringMenuItem( title: "Item \(index)") )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        
        // Test
        
        let menuLocation = NSPoint( x: geometry.initialBounds.minX, y: geometry.initialBounds.maxY )
        
        let screenAreaSize = NSSize( width: 40.0, height: 20.0 )
        
        let screenArea = NSRect(
            x: screenLimits.minX,
            y: screenFrame.midY - floor( screenAreaSize.height / 2.0 ),
            width: screenAreaSize.width,
            height: screenAreaSize.height
        )
        
        let rightAlignment = geometry.updateGeometryToDisplayMenuLocation( menuLocation, adjacentToScreenArea: screenArea, preferredAlignment: .Right )
        XCTAssertEqual( rightAlignment, OBWFilteringMenuAlignment.Right )
        
        let leftAlignment = geometry.updateGeometryToDisplayMenuLocation( menuLocation, adjacentToScreenArea: screenArea, preferredAlignment: .Left )
        XCTAssertEqual( leftAlignment, OBWFilteringMenuAlignment.Right )
    }
    
    /*==========================================================================*/
    func testDisplayAdjacentToScreenArea_AreaNearRightScreenEdge() {
        
        // Setup
        
        let screen = NSScreen.screens()!.first!
        let screenFrame = screen.frame
        let screenLimits = screenFrame + OBWFilteringMenuWindowGeometry.screenMargins
        
        let menu = OBWFilteringMenu()
        for index in 1...5 {
            menu.addItem( OBWFilteringMenuItem( title: "Item \(index)") )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        
        // Test
        
        let menuLocation = NSPoint( x: geometry.initialBounds.minX, y: geometry.initialBounds.maxY )
        
        let screenAreaSize = NSSize( width: 40.0, height: 20.0 )
        
        let screenArea = NSRect(
            x: screenLimits.maxX - screenAreaSize.width,
            y: screenFrame.midY - floor( screenAreaSize.height / 2.0 ),
            width: screenAreaSize.width,
            height: screenAreaSize.height
        )
        
        let rightAlignment = geometry.updateGeometryToDisplayMenuLocation( menuLocation, adjacentToScreenArea: screenArea, preferredAlignment: .Right )
        XCTAssertEqual( rightAlignment, OBWFilteringMenuAlignment.Left )
        
        let leftAlignment = geometry.updateGeometryToDisplayMenuLocation( menuLocation, adjacentToScreenArea: screenArea, preferredAlignment: .Left )
        XCTAssertEqual( leftAlignment, OBWFilteringMenuAlignment.Left )
    }
    
    /*==========================================================================*/
    // MARK: - updateGeometryWithResizedMenu()
    
    /*==========================================================================*/
    func testUpdateWithResizedMenu_SmallAnchor() {
        
        // Setup
        
        let screen = NSScreen.screens()!.first!
        let screenFrame = screen.frame
        
        let menu = OBWFilteringMenu()
        for index in 1...9 {
            menu.addItem( OBWFilteringMenuItem( title: "Item \(index)") )
        }
        
        let interiorMargins = OBWFilteringMenuWindow.interiorMargins
        
        let anchorSize = NSSize( width: 100.0, height: 10.0 )
        
        var screenAnchor = NSRect(
            x: screenFrame.midX - anchorSize.width,
            y: screenFrame.midY - floor( anchorSize.height / 2.0 ),
            width: anchorSize.width,
            height: anchorSize.height
        )
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        let outerMenuMargins = window.menuView.outerMenuMargins
        
        let menuLocation = NSPoint( x: 0.0, y: geometry.initialBounds.midY )
        geometry.updateGeometryToDisplayMenuLocation( menuLocation, adjacentToScreenArea: screenAnchor, preferredAlignment: .Right )
        
        var preResizeHeight: CGFloat = 0.0
        
        // Window spans anchor > no anchor alignment
        
        preResizeHeight = geometry.frame.size.height
        
        window.screenAnchor = screenAnchor
        
        window.menuView.applyFilterResults( OBWFilteringMenuItemFilterStatus.filterStatus( menu, filterString: "g/[1-8]/" ) )
        geometry.updateGeometryWithResizedMenu()
        
        XCTAssertTrue( geometry.frame.size.height < preResizeHeight )
        XCTAssertTrue( screenAnchor.size.height < geometry.frame.size.height )
        XCTAssertTrue( geometry.frame.maxY > screenAnchor.maxY )
        XCTAssertTrue( geometry.frame.minY < screenAnchor.minY )
        
        // Window overlaps bottom of anchor > top alignment
        
        preResizeHeight = geometry.frame.size.height
        
        screenAnchor.origin.y = geometry.frame.maxY - floor( anchorSize.height / 2.0 )
        window.screenAnchor = screenAnchor
        
        window.menuView.applyFilterResults( OBWFilteringMenuItemFilterStatus.filterStatus( menu, filterString: "g/[1-7]/" ) )
        geometry.updateGeometryWithResizedMenu()
        
        XCTAssertTrue( geometry.frame.size.height < preResizeHeight )
        XCTAssertTrue( screenAnchor.size.height < geometry.frame.size.height )
        XCTAssertEqual( geometry.frame.maxY, screenAnchor.maxY + interiorMargins.top + outerMenuMargins.top )
        
        // Window overlaps top of anchor > bottom alignment
        
        preResizeHeight = geometry.frame.size.height
        
        screenAnchor.origin.y = geometry.frame.minY - floor( anchorSize.height / 2.0 )
        window.screenAnchor = screenAnchor
        
        window.menuView.applyFilterResults( OBWFilteringMenuItemFilterStatus.filterStatus( menu, filterString: "g/[1-6]/" ) )
        geometry.updateGeometryWithResizedMenu()
        
        XCTAssertTrue( geometry.frame.size.height < preResizeHeight )
        XCTAssertTrue( screenAnchor.size.height < geometry.frame.size.height )
        XCTAssertEqual( geometry.frame.minY, screenAnchor.minY - interiorMargins.bottom - outerMenuMargins.bottom )
        
        // Window below anchor > top alignment
        
        preResizeHeight = geometry.frame.size.height
        
        screenAnchor.origin.y = geometry.frame.maxY + floor( anchorSize.height / 2.0 )
        window.screenAnchor = screenAnchor
        
        window.menuView.applyFilterResults( OBWFilteringMenuItemFilterStatus.filterStatus( menu, filterString: "g/[1-5]/" ) )
        geometry.updateGeometryWithResizedMenu()
        
        XCTAssertTrue( geometry.frame.size.height < preResizeHeight )
        XCTAssertTrue( screenAnchor.size.height < geometry.frame.size.height )
        XCTAssertEqual( geometry.frame.maxY, screenAnchor.maxY + interiorMargins.top + outerMenuMargins.top )
        
        // Window above anchor > bottom alignment
        
        preResizeHeight = geometry.frame.size.height
        
        screenAnchor.origin.y = geometry.frame.minY - ( anchorSize.height * 2.0 )
        window.screenAnchor = screenAnchor
        
        window.menuView.applyFilterResults( OBWFilteringMenuItemFilterStatus.filterStatus( menu, filterString: "g/[1-4]/" ) )
        geometry.updateGeometryWithResizedMenu()
        
        XCTAssertTrue( geometry.frame.size.height < preResizeHeight )
        XCTAssertTrue( screenAnchor.size.height < geometry.frame.size.height )
        XCTAssertEqual( geometry.frame.minY, screenAnchor.minY - interiorMargins.bottom - outerMenuMargins.bottom )
    }
    
    /*==========================================================================*/
    func testUpdateWithResizedMenu_LargeAnchor() {
        
        // Setup
        
        let screen = NSScreen.screens()!.first!
        let screenFrame = screen.frame
        let screenLimits = screenFrame + OBWFilteringMenuWindowGeometry.screenMargins
        
        let menu = OBWFilteringMenu()
        for index in 1...9 {
            menu.addItem( OBWFilteringMenuItem( title: "Item \(index)") )
        }
        
        let interiorMargins = OBWFilteringMenuWindow.interiorMargins
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        let outerMenuMargins = window.menuView.outerMenuMargins
        
        let anchorSize = NSSize( width: 100.0, height: geometry.frame.size.height + 40.0 )
        
        var screenAnchor = NSRect(
            x: screenFrame.midX - anchorSize.width,
            y: screenFrame.midY - floor( anchorSize.height / 2.0 ),
            width: anchorSize.width,
            height: anchorSize.height
        )
        
        let menuLocation = NSPoint( x: 0.0, y: geometry.initialBounds.midY )
        geometry.updateGeometryToDisplayMenuLocation( menuLocation, adjacentToScreenArea: screenAnchor, preferredAlignment: .Right )
        
        var preResizeHeight: CGFloat = 0.0
        
        // Window within anchor > top alignment
        
        preResizeHeight = geometry.frame.size.height
        
        screenAnchor.origin.y = geometry.frame.minY - 20.0
        window.screenAnchor = screenAnchor
        
        window.menuView.applyFilterResults( OBWFilteringMenuItemFilterStatus.filterStatus( menu, filterString: "g/[1-8]/" ) )
        geometry.updateGeometryWithResizedMenu()
        
        XCTAssertTrue( screenAnchor.size.height > geometry.frame.size.height )
        XCTAssertTrue( geometry.frame.size.height < preResizeHeight )
        XCTAssertEqual( geometry.frame.maxY, screenAnchor.maxY + interiorMargins.top + outerMenuMargins.top )
        
        // Window overlaps top of anchor > top alignment
        
        preResizeHeight = geometry.frame.size.height
        
        screenAnchor.origin.y = screenLimits.minY
        window.screenAnchor = screenAnchor
        
        window.menuView.applyFilterResults( OBWFilteringMenuItemFilterStatus.filterStatus( menu, filterString: "g/[1-7]/" ) )
        geometry.updateGeometryWithResizedMenu()
        
        XCTAssertTrue( screenAnchor.size.height > geometry.frame.size.height )
        XCTAssertTrue( geometry.frame.size.height < preResizeHeight )
        XCTAssertEqual( geometry.frame.maxY, screenAnchor.maxY + interiorMargins.top + outerMenuMargins.top )
        
        // Window overlaps bottom of anchor > bottom alignment
        
        preResizeHeight = geometry.frame.size.height
        
        screenAnchor.origin.y = geometry.frame.midY
        window.screenAnchor = screenAnchor
        
        window.menuView.applyFilterResults( OBWFilteringMenuItemFilterStatus.filterStatus( menu, filterString: "g/[1-6]/" ) )
        geometry.updateGeometryWithResizedMenu()
        
        XCTAssertTrue( screenAnchor.size.height > geometry.frame.size.height )
        XCTAssertTrue( geometry.frame.size.height < preResizeHeight )
        XCTAssertEqual( geometry.frame.maxY, screenAnchor.maxY + interiorMargins.top + outerMenuMargins.top )
        
        // Window above anchor > top alignment
        
        preResizeHeight = geometry.frame.size.height
        
        screenAnchor.origin.y = geometry.frame.minY - geometry.frame.size.height - 40.0
        window.screenAnchor = screenAnchor
        
        window.menuView.applyFilterResults( OBWFilteringMenuItemFilterStatus.filterStatus( menu, filterString: "g/[1-5]/" ) )
        geometry.updateGeometryWithResizedMenu()
        
        XCTAssertTrue( screenAnchor.size.height > geometry.frame.size.height )
        XCTAssertTrue( geometry.frame.size.height < preResizeHeight )
        XCTAssertEqual( geometry.frame.maxY, screenAnchor.maxY + interiorMargins.top + outerMenuMargins.top )
        
        // Window below anchor > bottom alignment
        
        preResizeHeight = geometry.frame.size.height
        
        screenAnchor.origin.y = geometry.frame.maxY + 20.0
        window.screenAnchor = screenAnchor
        
        window.menuView.applyFilterResults( OBWFilteringMenuItemFilterStatus.filterStatus( menu, filterString: "g/[1-4]/" ) )
        geometry.updateGeometryWithResizedMenu()
        
        XCTAssertTrue( screenAnchor.size.height > geometry.frame.size.height )
        XCTAssertTrue( geometry.frame.size.height < preResizeHeight )
        XCTAssertEqual( geometry.frame.maxY, screenAnchor.maxY + interiorMargins.top + outerMenuMargins.top )
    }
    
    /*==========================================================================*/
    // MARK: - updateGeometryToDisplayMenuItemBounds(_:)
    
    /*==========================================================================*/
    func testDisplayMenuItemBounds() {
        
        // Setup
        
        let screen = NSScreen.screens()!.first!
        let screenFrame = screen.frame
        
        let menu = OBWFilteringMenu()
        for index in 1...20 {
            menu.addItem( OBWFilteringMenuItem( title: "Item \(index)") )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        
        let menuLocation = NSPoint( x: 0.0, y: geometry.initialBounds.maxY )
        let screenLocation = NSPoint( x: screenFrame.midX, y: screenFrame.minY )
        geometry.updateGeometryToDisplayMenuLocation( menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false )
        
        // Test scrolling content up - window frame changes by visible content height change
        
        var scrollDistance = floor( geometry.initialBounds.size.height / 4.0 )
        
        var scrolledBounds = NSRect(
            x: geometry.initialBounds.origin.x,
            y: geometry.initialBounds.origin.y - scrollDistance,
            width: geometry.initialBounds.size.width,
            height: geometry.initialBounds.size.height + scrollDistance
        )
        
        var preScrollFrame = geometry.frame
        
        geometry.updateGeometryToDisplayMenuItemBounds( scrolledBounds )
        
        XCTAssertEqual( geometry.frame.size.height, preScrollFrame.size.height + scrollDistance )
        
        // Test scrolling content down - no window frame change
        
        scrollDistance = -floor( scrollDistance / 2.0 )
        
        scrolledBounds = NSRect(
            x: geometry.initialBounds.origin.x,
            y: geometry.initialBounds.origin.y - scrollDistance,
            width: geometry.initialBounds.size.width,
            height: geometry.initialBounds.size.height
        )
        
        preScrollFrame = geometry.frame
        
        geometry.updateGeometryToDisplayMenuItemBounds( scrolledBounds )
        
        XCTAssertEqual( geometry.frame.size.height, preScrollFrame.size.height )
    }
 
}
