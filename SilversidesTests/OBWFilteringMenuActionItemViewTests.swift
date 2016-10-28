/*===========================================================================
 OBWFilteringMenuActionItemViewTests.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import XCTest
@testable import OBWControls

/*==========================================================================*/

class OBWFilteringMenuActionItemViewTests: XCTestCase {
    
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
    func testPreferredSizeForMenuItem() {
        
        let smallMenuItem = OBWFilteringMenuItem( title: "A" )
        let smallItemSize = OBWFilteringMenuItemView.preferredSizeForMenuItem( smallMenuItem )
        XCTAssertGreaterThan( smallItemSize.width, 0.0 )
        XCTAssertGreaterThan( smallItemSize.height, 0.0 )
        
        let largeMenuItem = OBWFilteringMenuItem( title: "A menu item with a much longer name" )
        let largeItemSize = OBWFilteringMenuItemView.preferredSizeForMenuItem( largeMenuItem )
        XCTAssertGreaterThan( largeItemSize.width, smallItemSize.width )
        XCTAssertEqual( largeItemSize.height, smallItemSize.height )
    }
    
    /*==========================================================================*/
    func testExample() {
        // TODO: Find more opportunities to test OBWFilteringMenuActionItemView...
    }
}
