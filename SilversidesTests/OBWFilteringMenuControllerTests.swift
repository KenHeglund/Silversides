/*===========================================================================
 OBWFilteringMenuControllerTests.swift
 Silversides
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import XCTest
@testable import OBWControls

/*==========================================================================*/

class OBWFilteringMenuControllerTests: XCTestCase {
    
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
    func testInteractionWithMenus() {
        
        let firstMenu = OBWFilteringMenu( title: "First Menu" )
        
        for index in 1...2016 {
            
            let menuItem = OBWFilteringMenuItem( title: "item \(index)" )
            
            firstMenu.addItem( menuItem )
            
        }
        
        let screenFrame = NSScreen.screens()!.first!.frame
        let locationInScreen = NSPoint(
            x: screenFrame.maxX - 20.0,
            y: screenFrame.minY + 100.0
        )
        
        #if INTERACTIVE_TESTS
            Swift.print( "Make a menu selection in the lower-right corner of the screen..." )
            OBWFilteringMenuController.popUpMenuPositioningItem( firstMenu.itemArray.first!, atLocation: locationInScreen, inView: nil, withEvent: nil, highlighted: false )
        #endif // INTERACTIVE_TESTS
        
        let secondMenu = OBWFilteringMenu( title: "Second Menu" )
        
        for index in 1...20 {
            
            let menuItem = OBWFilteringMenuItem( title: "item \(index)" )
            
            secondMenu.addItem( menuItem )
            
            if ( index % 7 ) == 4 {
                
                let submenu = OBWFilteringMenu( title: "submenu" )
                
                for index in 1...10 {
                    submenu.addItem( OBWFilteringMenuItem( title: "sub item \(index)" ) )
                }
                
                menuItem.submenu = submenu
            }
            
            if ( index % 7 ) == 6 {
                
                let alternateItem = OBWFilteringMenuItem( title: "alternate \(index)" )
                alternateItem.keyEquivalentModifierMask = .Option
                
                try! menuItem.addAlternateItem( alternateItem )
                
                menuItem.title = "original \(index)"
            }
        }
        
        #if INTERACTIVE_TESTS
            Swift.print( "Make a menu selection in the lower-right corner of the screen..." )
            OBWFilteringMenuController.popUpMenuPositioningItem( secondMenu.itemArray.first!, atLocation: locationInScreen, inView: nil, withEvent: nil, highlighted: false )
        #endif // INTERACTIVE_TESTS
    }
    
}
