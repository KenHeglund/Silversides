/*===========================================================================
 OBWFilteringMenuItemTests.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import XCTest
@testable import OBWControls

/*==========================================================================*/

class OBWFilteringMenuItemTests: XCTestCase {
    
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
    func testSeparatorMenuItemIdentity() {
        
        let separatorItem = OBWFilteringMenuItem.separatorItem
        XCTAssertNotNil( separatorItem )
        XCTAssertTrue( separatorItem.isSeparatorItem )
        
        let menuItem = OBWFilteringMenuItem( title: separatorItem.title! )
        XCTAssertFalse( menuItem.isSeparatorItem )
        
        XCTAssertTrue( OBWFilteringMenuItem.separatorItem === separatorItem )
    }
    
    /*==========================================================================*/
    func testThatMenuItemSelectionHandlerIsPreferredOverMenuSelectionHandler() {
        
        var menuHandlerArgument: OBWFilteringMenuItem? = nil
        var menuItemHandlerArgument: OBWFilteringMenuItem? = nil
        
        let menu = OBWFilteringMenu( title: "menu" )
        menu.actionHandler = { ( menuItem: OBWFilteringMenuItem ) in
            menuHandlerArgument = menuItem
        }
        
        let menuItem = OBWFilteringMenuItem( title: "menu item" )
        menuItem.actionHandler = { ( menuItem: OBWFilteringMenuItem ) in
            menuItemHandlerArgument = menuItem
        }
        menu.addItem( menuItem )
        
        menuItem.performAction()
        
        XCTAssertTrue( menuItemHandlerArgument === menuItem )
        XCTAssertNil( menuHandlerArgument )
    }
    
    /*==========================================================================*/
    func testThatMenuSelectionHandlerIsUsedWhenMenuItemSelectionHandlerIsNil() {
        
        var menuHandlerArgument: OBWFilteringMenuItem? = nil
        
        let menu = OBWFilteringMenu( title: "menu" )
        menu.actionHandler = { ( menuItem: OBWFilteringMenuItem ) in
            menuHandlerArgument = menuItem
        }
        
        let menuItems = [
            OBWFilteringMenuItem( title: "item 1" ),
            OBWFilteringMenuItem( title: "item 2" ),
            OBWFilteringMenuItem( title: "item 3" ),
        ]
        
        for menuItem in menuItems {
            menu.addItem( menuItem )
        }
        
        menuItems[1].performAction()
        
        XCTAssertTrue( menuHandlerArgument === menuItems[1] )
    }
    
    /*==========================================================================*/
    func testAlternateItemRetrieval() {
        
        let menu = OBWFilteringMenu( title: "menu" )
        
        let menuItems = [
            OBWFilteringMenuItem( title: "menu item 1" ),
            OBWFilteringMenuItem( title: "menu item 2" ),
        ]
        
        for menuItem in menuItems {
            menu.addItem( menuItem )
        }
        
        menuItems[1].keyEquivalentModifierMask = .Control
        
        let alternateItems = [
            OBWFilteringMenuItem( title: "item 1" ),
            OBWFilteringMenuItem( title: "item 2" ),
            OBWFilteringMenuItem( title: "item 3" ),
        ]
        
        alternateItems[0].keyEquivalentModifierMask = .Command
        alternateItems[1].keyEquivalentModifierMask = [ .Control, .Shift ]
        alternateItems[2].keyEquivalentModifierMask = .Option
        
        for alternateItem in alternateItems {
            try! menuItems[0].addAlternateItem( alternateItem )
        }
        
        XCTAssertTrue( menuItems[0].visibleItemForModifierFlags( .Command ) === alternateItems[0] )
        XCTAssertTrue( menuItems[0].visibleItemForModifierFlags( .Control ) === menuItems[0] )
        XCTAssertTrue( menuItems[0].visibleItemForModifierFlags( [] ) === menuItems[0] )
        XCTAssertTrue( menuItems[0].visibleItemForModifierFlags( [ .Command, .Shift ] ) === menuItems[0] )
        
        XCTAssertTrue( alternateItems[2].visibleItemForModifierFlags( .Option ) === alternateItems[2] )
        XCTAssertNil( alternateItems[2].visibleItemForModifierFlags( .Shift ) )
        
        XCTAssertNil( menuItems[1].visibleItemForModifierFlags( .Shift ) )
    }
    
    /*==========================================================================*/
    func testAlternateItemReplacement() {
        
        let menu = OBWFilteringMenu( title: "menu" )
        
        let menuItem = OBWFilteringMenuItem( title: "menu item" )
        menu.addItem( menuItem )
        
        let alternateItems = [
            OBWFilteringMenuItem( title: "item 1" ),
            OBWFilteringMenuItem( title: "item 2" ),
        ]
        
        for alternateItem in alternateItems {
            alternateItem.keyEquivalentModifierMask = .Command
        }
        
        try! menuItem.addAlternateItem( alternateItems[0] )
        
        XCTAssertTrue( menuItem.visibleItemForModifierFlags( .Command ) === alternateItems[0] )
        
        try! menuItem.addAlternateItem( alternateItems[1] )
        
        XCTAssertFalse( menuItem.visibleItemForModifierFlags( .Command ) === alternateItems[0] )
        XCTAssertTrue( menuItem.visibleItemForModifierFlags( .Command ) === alternateItems[1] )
    }
}
