/*===========================================================================
 OBWFilteringMenuWindowTests.swift
 Silversides
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import XCTest
@testable import OBWControls

/*==========================================================================*/

class OBWFilteringMenuWindowTests: XCTestCase {
    
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
    func testGeometryApplication_MenuSizeChanges() {
        
        
        // Setup
        
        let screen = NSScreen.screens()!.first!
        let screenFrame = screen.frame
        
        let menu = OBWFilteringMenu()
        menu.addItem( OBWFilteringMenuItem( title: "A" ) )
        menu.addItem( OBWFilteringMenuItem( title: "B" ) )
        
        let longMenuItem = OBWFilteringMenuItem( title: "A menu item with a really long name" )
        longMenuItem.keyEquivalentModifierMask = [ .Command ]
        menu.addItem( longMenuItem )
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        
        let geometry = OBWFilteringMenuWindowGeometry( window: window, constrainToScreen: true )
        let screenCenter = NSPoint( x: screenFrame.midX, y: screenFrame.midY )
        if geometry.updateGeometryToDisplayMenuLocation( NSZeroPoint, atScreenLocation: screenCenter, allowWindowToGrowUpward: true ) {
            window.applyWindowGeometry( geometry )
        }
        
        let menuView = window.menuView
        let initialWindowFrame = window.frame
        
        // Larger menu width, window gets wider
        // Larger menu height, window gets taller
        
        let commandEvent = NSEvent.keyEventWithType( .FlagsChanged, location: NSZeroPoint, modifierFlags: [ .Command ], timestamp: NSProcessInfo.processInfo().systemUptime, windowNumber: 0, context: nil, characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: 0 )!
        menuView.handleFlagsChangedEvent( commandEvent )
        
        geometry.updateGeometryWithResizedMenu()
        window.applyWindowGeometry( geometry )
        
        let largerWindowFrame = window.frame
        
        XCTAssertTrue( largerWindowFrame.size.width > initialWindowFrame.size.width )
        XCTAssertTrue( largerWindowFrame.size.height > initialWindowFrame.size.height )
        
        // Smaller menu width, window with remains unchanged
        // Smaller menu height, window height returns to inital height
        
        let shiftEvent = NSEvent.keyEventWithType( .FlagsChanged, location: NSZeroPoint, modifierFlags: [ .Shift ], timestamp: NSProcessInfo.processInfo().systemUptime, windowNumber: 0, context: nil, characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: 0 )!
        menuView.handleFlagsChangedEvent( shiftEvent )
        
        geometry.updateGeometryWithResizedMenu()
        window.applyWindowGeometry( geometry )
        
        let reducedWindowFrame = window.frame
        
        XCTAssertEqual( reducedWindowFrame.size.width, largerWindowFrame.size.width )
        XCTAssertEqual( reducedWindowFrame.size.height, initialWindowFrame.size.height )
    }
    
    /*==========================================================================*/
    func testGeometryApplication_MenuScrolling() {
        
        // Setup
        
        let screen = NSScreen.screens()!.first!
        let screenFrame = screen.frame
        
        let menu = OBWFilteringMenu()
        for index in 1...10 {
            menu.addItem( OBWFilteringMenuItem( title: "menu item \(index)" ) )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        
        let geometry = OBWFilteringMenuWindowGeometry( window: window, constrainToScreen: true )
        let screenLocation = NSPoint( x: screenFrame.midX, y: screenFrame.origin.y + 40.0 )
        let menuLocation = NSPoint( x: 0.0, y: geometry.totalMenuItemSize.height )
        if geometry.updateGeometryToDisplayMenuLocation( menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false ) {
            window.applyWindowGeometry( geometry )
        }
        
        // Test
        
        let initialWindowFrame = window.frame
        
        let distanceToScroll: CGFloat = 25.0
        
        // Sanity check to verify that not all of the menu's contents are visible in the window, ie. there is room to scroll
        XCTAssertTrue( geometry.initialBounds.size.height + distanceToScroll < geometry.totalMenuItemSize.height )
        
        let scrolledBounds = NSRect(
            x: geometry.initialBounds.origin.x,
            y: geometry.initialBounds.origin.y - distanceToScroll,
            width: geometry.initialBounds.size.width,
            height: geometry.initialBounds.size.height + distanceToScroll
        )
        
        if geometry.updateGeometryToDisplayMenuItemBounds( scrolledBounds ) {
            window.applyWindowGeometry( geometry )
        }
        
        XCTAssertEqual( geometry.finalBounds.size.height, geometry.totalMenuItemSize.height )
        
        let scrolledWindowFrame = window.frame
        
        XCTAssertEqual( scrolledWindowFrame.size.height, initialWindowFrame.size.height + distanceToScroll )
        
        // Sanity check to verify that there is still menu content outside of the visible bounds
        XCTAssertTrue( geometry.initialBounds.size.height < geometry.totalMenuItemSize.height )
    }
}
