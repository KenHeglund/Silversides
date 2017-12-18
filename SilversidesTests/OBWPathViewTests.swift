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
        
        let startDate = Date()
        
        while true {
            
            assert( Date().timeIntervalSince( startDate ) < 2.0 )
            
            RunLoop.current.run( until: Date( timeIntervalSinceNow: 0.100 ) )
            
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
        let drawnFrame = NSRect( origin: NSPoint.zero, size: imageSize)
        
        let sourceImage = NSImage( size: imageSize )
        sourceImage.withLockedFocus { 
            NSColor.black.set()
            drawnFrame.fill()
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
            NSColor.black.set()
            drawnFrame.fill()
        }
        
        let trimmedImage: NSImage! = sourceImage.imageByTrimmingTransparentEdges()
        XCTAssertNotNil( trimmedImage )
        XCTAssertEqual( drawnFrame.size, trimmedImage.size )
    }
    
    /*==========================================================================*/
    func testThatImbalancedEndItemUpdateThrowsError() {
        
        let window = NSApp.windows.first!
        let windowController = window.windowController!
        let viewController = windowController.contentViewController as! ViewController
        let pathView = viewController.pathViewOutlet!
        
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
        let pathView = viewController.pathViewOutlet!
        
        pathView.setItems( [] )
        XCTAssertEqual( pathView.numberOfItems, 0 )
        
        let items: [OBWPathItem] = [
            OBWPathItem( title: "first", image: nil, representedObject: nil, style: .default, textColor: nil ),
            OBWPathItem( title: "second", image: nil, representedObject: nil, style: .default, textColor: nil ),
            OBWPathItem( title: "third", image: nil, representedObject: nil, style: .default, textColor: nil ),
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
        let pathView = viewController.pathViewOutlet!
        
        let items: [OBWPathItem] = [
            OBWPathItem( title: "first", image: nil, representedObject: nil, style: .default, textColor: nil ),
            OBWPathItem( title: "second", image: nil, representedObject: nil, style: .default, textColor: nil ),
            OBWPathItem( title: "third", image: nil, representedObject: nil, style: .default, textColor: nil ),
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
        let pathView = viewController.pathViewOutlet!
        
        let items: [OBWPathItem] = [
            OBWPathItem( title: "first", image: nil, representedObject: nil, style: .default, textColor: nil ),
            OBWPathItem( title: "second", image: nil, representedObject: nil, style: .default, textColor: nil ),
            OBWPathItem( title: "third", image: nil, representedObject: nil, style: .default, textColor: nil ),
        ]
        
        pathView.setItems( items )
        XCTAssertEqual( try pathView.item( atIndex: 1 ).title, items[1].title )
        
        let newItem = OBWPathItem( title: "replacement", image: nil, representedObject: nil, style: .default, textColor: nil )
        
        try! pathView.setItem( newItem, atIndex: 1 )
        XCTAssertEqual( try pathView.item( atIndex: 1 ).title, newItem.title )
    }
    
    /*==========================================================================*/
    func testVisualChangesSlowly() {
        
        let window = NSApp.windows.first!
        let windowController = window.windowController!
        let viewController = windowController.contentViewController as! ViewController
        
        let URL1 = URL( fileURLWithPath: "/Applications/Utilities/", isDirectory: true )
        viewController.configurePathViewToShowURL( URL1 )
        
        #if INTERACTIVE_TESTS
            Swift.print( "The currently displayed URL should have animated to a new URL" )
            self.waitforInterval( 3.0 )
        #endif // INTERACTIVE_TESTS
        
        let URL2 = URL( fileURLWithPath: "/Library/Logs/", isDirectory: true )
        viewController.configurePathViewToShowURL( URL2 )
        
        #if INTERACTIVE_TESTS
            Swift.print( "The currently displayed URL should have animated to a new URL" )
            self.waitforInterval( 3.0 )
        #endif // INTERACTIVE_TESTS
        
        let URL3 = URL( fileURLWithPath: "/System/Library/Extensions/AppleHIDKeyboard.kext", isDirectory: true )
        viewController.configurePathViewToShowURL( URL3 )
        
        #if INTERACTIVE_TESTS
            Swift.print( "The currently displayed URL should have animated to a new URL" )
            self.waitforInterval( 3.0 )
        #endif // INTERACTIVE_TESTS
    }
    
    /*==========================================================================*/
    fileprivate func waitforInterval( _ timeInterval: TimeInterval ) {
        
        // The simple approach:
        //  NSRunLoop.currentRunLoop().runUntilDate( NSDate( timeIntervalSinceNow: timeInterval ) )
        // doesn't allow the UI to respond to mouse movements
        
        let queue = DispatchQueue.global( qos: DispatchQoS.QoSClass.default)
        
        let expectation = self.expectation( description: "waitForInterval(_:)" )
        let delta = timeInterval * Double(NSEC_PER_SEC)
        queue.asyncAfter( deadline: DispatchTime.now() + Double(Int64(delta)) / Double(NSEC_PER_SEC)) {
            expectation.fulfill()
        }
        
        self.waitForExpectations( timeout: timeInterval * 1.1, handler: nil )
    }
}
