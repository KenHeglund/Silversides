/*===========================================================================
 SilversidesTests.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import XCTest
@testable import SilversidesDemo
@testable import OBWControls

/*==========================================================================*/
class SilversidesTests: XCTestCase {
    
    /*==========================================================================*/
    override func setUp() {
        
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // Spin until the application's window loads.  This also allows time for the application to asynchronously display the initial path view contents.
        
        let startDate = NSDate()
        
        while true {
            
            assert( NSDate().timeIntervalSinceDate( startDate ) < 2.0 )
            
            NSRunLoop.currentRunLoop().runUntilDate( NSDate( timeIntervalSinceNow: 0.100 ) )
            
            guard let window = NSApp.windows.first else { continue }
            guard let viewController = window.contentViewController as? ViewController else { continue }
            
            if viewController.pathViewConfigured {
                break
            }
        }
    }
    
    /*==========================================================================*/
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    /*==========================================================================*/
    func testThatTrimmingAnEmptyImageProducesNil() {
        
        let imageSize = NSSize( width: 10.0, height: 12.0 )
        let emptyImage = NSImage( size: imageSize )
        XCTAssertNil( emptyImage.imageByTrimmingTransparentEdges() )
    }
    
    /*==========================================================================*/
    func testThatTrimmingAnOpaqueImageReturnsTheOriginalImage() {
        
        let imageSize = NSSize( width: 10.0, height: 12.0 )
        let drawnFrame = NSRect( size: imageSize )
        
        let sourceImage = NSImage( size: imageSize )
        sourceImage.withLockedFocus { 
            NSColor.blackColor().set()
            NSRectFill( drawnFrame )
        }
        
        let trimmedImage = sourceImage.imageByTrimmingTransparentEdges()
        XCTAssertTrue( trimmedImage === sourceImage )
    }
    
    /*==========================================================================*/
    func testThatTrimmingAPartiallyEmptyImageProducesAProperlySizedImage() {
        
        let imageSize = NSSize( width: 10.0, height: 12.0 )
        let drawnFrame = NSRect( x: 3.0, y: 4.0, width: 2.0, height: 5.0 )
        
        let sourceImage = NSImage( size: imageSize )
        sourceImage.withLockedFocus {
            NSColor.blackColor().set()
            NSRectFill( drawnFrame )
        }
        
        let trimmedImage: NSImage! = sourceImage.imageByTrimmingTransparentEdges()
        XCTAssertNotNil( trimmedImage )
        XCTAssertTrue( NSEqualSizes( drawnFrame.size, trimmedImage.size ) )
    }
    
    /*==========================================================================*/
    func testThatImbalancedEndItemUpdateThrowsError() {
        
        let window = NSApp.windows.first!
        let windowController = window.windowController!
        let viewController = windowController.contentViewController as! ViewController
        let pathView = viewController.pathViewOutlet
        
        XCTAssertThrowsError( try pathView.endPathItemUpdate() )
        
        pathView.beginPathItemUpdate()
        try! pathView.endPathItemUpdate()
        
        XCTAssertThrowsError( try pathView.endPathItemUpdate() )
    }
    
    /*==========================================================================*/
    func testThatPathViewItemCounts() {
        
        let window = NSApp.windows.first!
        let windowController = window.windowController!
        let viewController = windowController.contentViewController as! ViewController
        let pathView = viewController.pathViewOutlet
        
        pathView.setItems( [] )
        XCTAssertEqual( pathView.numberOfItems, 0 )
        
        let items: [OBWPathItem] = [
            OBWPathItem( title: "first", image: nil, representedObject: nil, style: .Default, textColor: nil ),
            OBWPathItem( title: "second", image: nil, representedObject: nil, style: .Default, textColor: nil ),
            OBWPathItem( title: "third", image: nil, representedObject: nil, style: .Default, textColor: nil ),
        ]
        
        pathView.setItems( items )
        XCTAssertEqual( pathView.numberOfItems, items.count )
        
        try! pathView.removeItemsFromIndex( 1 )
        XCTAssertEqual( pathView.numberOfItems, 1 )
        
        let item = try! pathView.item( atIndex: 0 )
        XCTAssertEqual( item.title, items.first!.title )
    }
    
    /*==========================================================================*/
    func testThatRemoveItemsFromIndexThrowsProperly() {
        
        let window = NSApp.windows.first!
        let windowController = window.windowController!
        let viewController = windowController.contentViewController as! ViewController
        let pathView = viewController.pathViewOutlet
        
        let items: [OBWPathItem] = [
            OBWPathItem( title: "first", image: nil, representedObject: nil, style: .Default, textColor: nil ),
            OBWPathItem( title: "second", image: nil, representedObject: nil, style: .Default, textColor: nil ),
            OBWPathItem( title: "third", image: nil, representedObject: nil, style: .Default, textColor: nil ),
        ]
        
        pathView.setItems( items )
        
        // Removing items from the end index should not throw
        try! pathView.removeItemsFromIndex( items.count )
        
        XCTAssertThrowsError( try pathView.removeItemsFromIndex( items.count + 1 ) )
        
        try! pathView.removeItemsFromIndex( 1 )
        // Removing items from the end index should not throw
        try! pathView.removeItemsFromIndex( 1 )
    }
    
    /*==========================================================================*/
    func testThatItemsAreReplacedProperly() {
        
        let window = NSApp.windows.first!
        let windowController = window.windowController!
        let viewController = windowController.contentViewController as! ViewController
        let pathView = viewController.pathViewOutlet
        
        let items: [OBWPathItem] = [
            OBWPathItem( title: "first", image: nil, representedObject: nil, style: .Default, textColor: nil ),
            OBWPathItem( title: "second", image: nil, representedObject: nil, style: .Default, textColor: nil ),
            OBWPathItem( title: "third", image: nil, representedObject: nil, style: .Default, textColor: nil ),
        ]
        
        pathView.setItems( items )
        XCTAssertEqual( try pathView.item( atIndex: 1 ).title, items[1].title )
        
        let newItem = OBWPathItem( title: "replacement", image: nil, representedObject: nil, style: .Default, textColor: nil )
        
        try! pathView.setItem( newItem, atIndex: 1 )
        XCTAssertEqual( try pathView.item( atIndex: 1 ).title, newItem.title )
    }
    
    /*==========================================================================*/
    func testVisualChangesSlowly() {
        
        let window = NSApp.windows.first!
        let windowController = window.windowController!
        let viewController = windowController.contentViewController as! ViewController
        
        let URL1 = NSURL.fileURLWithPath( "/Applications/Utilities/", isDirectory: true )
        viewController.configurePathViewToShowURL( URL1 )
        
        #if INTERACTIVE_TESTS
            Swift.print( "The currently displayed URL should have animated to a new URL" )
            self.waitforInterval( 3.0 )
        #endif // INTERACTIVE_TESTS
        
        let URL2 = NSURL.fileURLWithPath( "/Library/Logs/", isDirectory: true )
        viewController.configurePathViewToShowURL( URL2 )
        
        #if INTERACTIVE_TESTS
            Swift.print( "The currently displayed URL should have animated to a new URL" )
            self.waitforInterval( 3.0 )
        #endif // INTERACTIVE_TESTS
        
        let URL3 = NSURL.fileURLWithPath( "/System/Library/Extensions/AppleHIDKeyboard.kext", isDirectory: true )
        viewController.configurePathViewToShowURL( URL3 )
        
        #if INTERACTIVE_TESTS
            Swift.print( "The currently displayed URL should have animated to a new URL" )
            self.waitforInterval( 3.0 )
        #endif // INTERACTIVE_TESTS
    }
    
    /*==========================================================================*/
    private func waitforInterval( timeInterval: NSTimeInterval ) {
        
        // The simple approach:
        //  NSRunLoop.currentRunLoop().runUntilDate( NSDate( timeIntervalSinceNow: timeInterval ) )
        // doesn't allow the UI to respond to mouse movements
        
        let queue = dispatch_get_global_queue( QOS_CLASS_DEFAULT, 0 )
        
        let expectation = self.expectationWithDescription( "waitForInterval(_:)" )
        let delta = timeInterval * Double(NSEC_PER_SEC)
        dispatch_after( dispatch_time( DISPATCH_TIME_NOW, Int64(delta) ), queue ) {
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout( timeInterval * 1.1, handler: nil )
    }
}
