/*===========================================================================
 NSEvent+OBWExtensionTests.swift
 Silversides
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import XCTest
@testable import OBWControls

/*==========================================================================*/

class NSEvent_OBWExtensionTests: XCTestCase {
    
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
    func testLocationInScreen() {
        
        let timestamp = NSProcessInfo.processInfo().systemUptime
        
        var event: NSEvent!
        var locationInScreen: NSPoint?
        
        event = NSEvent.otherEventWithType(
            .ApplicationDefined,
            location: NSPoint( x: 100.0, y: 100.0 ),
            modifierFlags: [],
            timestamp: timestamp,
            windowNumber: 0,
            context: nil,
            subtype: 1,
            data1: 2,
            data2: 3
        )
        XCTAssertNotNil( event )
        XCTAssertNil( event.obw_locationInScreen )
        
        event = NSEvent.otherEventWithType(
            .Periodic,
            location: NSPoint( x: 100.0, y: 100.0 ),
            modifierFlags: [],
            timestamp: timestamp,
            windowNumber: 0,
            context: nil,
            subtype: 1,
            data1: 2,
            data2: 3
        )
        XCTAssertNotNil( event )
        XCTAssertNil( event.obw_locationInScreen )
        
        let windowContentFrame = NSRect(
            x: 200.0,
            y: 300.0,
            width: 400.0,
            height: 500.0
        )
        
        let testLocation = NSPoint( x: 40.0, y: 60.0 )
        let verificationPoint = NSPoint(
            x: windowContentFrame.origin.x + testLocation.x,
            y: windowContentFrame.origin.y + testLocation.y
        )
        
        let window = NSWindow(
            contentRect: windowContentFrame,
            styleMask: NSBorderlessWindowMask,
            backing: .Buffered,
            defer: true
        )
        
        event = NSEvent.mouseEventWithType(
            .OtherMouseDragged,
            location: testLocation,
            modifierFlags: [],
            timestamp: timestamp,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 123,
            clickCount: 1,
            pressure: 1.0
        )
        XCTAssertNotNil( event )
        
        locationInScreen = event.obw_locationInScreen
        XCTAssertEqual( locationInScreen, verificationPoint )
        
        event = NSEvent.mouseEventWithType(
            .OtherMouseUp,
            location: testLocation,
            modifierFlags: [],
            timestamp: timestamp,
            windowNumber: 0,
            context: nil,
            eventNumber: 124,
            clickCount: 1,
            pressure: 0.0
        )
        XCTAssertNotNil( event )
        
        locationInScreen = event.obw_locationInScreen
        XCTAssertEqual( locationInScreen, testLocation )
    }
    
    /*==========================================================================*/
    func testLocationInView() {
        
        let timestamp = NSProcessInfo.processInfo().systemUptime
        
        var event: NSEvent!
        var locationInView: NSPoint?
        var testLocation: NSPoint
        var verificationPoint: NSPoint
        
        let windowContentFrame = NSRect(
            x: 200.0,
            y: 300.0,
            width: 400.0,
            height: 500.0
        )
        
        let window = NSWindow(
            contentRect: windowContentFrame,
            styleMask: NSBorderlessWindowMask,
            backing: .Buffered,
            defer: true
        )
        
        let viewFrame = NSRect(
            x: 35.0,
            y: 65.0,
            width: 75.0,
            height: 95.0
        )
        
        let testView = NSView( frame: viewFrame )
        testLocation = NSPoint( x: 50.0, y: 100.0 )
        
        event = NSEvent.mouseEventWithType(
            .OtherMouseDragged,
            location: testLocation,
            modifierFlags: [],
            timestamp: timestamp,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 123,
            clickCount: 1,
            pressure: 1.0
        )
        XCTAssertNotNil( event )
        XCTAssertNil( event.obw_locationInView( testView ) )
        
        window.contentView?.addSubview( testView )
        
        verificationPoint = NSPoint(
            x: testLocation.x - viewFrame.origin.x,
            y: testLocation.y - viewFrame.origin.y
        )
        
        event = NSEvent.mouseEventWithType(
            .OtherMouseDragged,
            location: testLocation,
            modifierFlags: [],
            timestamp: timestamp,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 123,
            clickCount: 1,
            pressure: 1.0
        )
        XCTAssertNotNil( event )
        
        locationInView = event.obw_locationInView( testView )
        XCTAssertEqual( locationInView, verificationPoint )
        
        testLocation = NSPoint( x: 250.0, y: 400.0 )
        verificationPoint = NSPoint(
            x: testLocation.x - viewFrame.origin.x - windowContentFrame.origin.x,
            y: testLocation.y - viewFrame.origin.y - windowContentFrame.origin.y
        )
        
        event = NSEvent.mouseEventWithType(
            .OtherMouseUp,
            location: testLocation,
            modifierFlags: [],
            timestamp: timestamp,
            windowNumber: 0,
            context: nil,
            eventNumber: 124,
            clickCount: 1,
            pressure: 0.0
        )
        XCTAssertNotNil( event )
        
        locationInView = event.obw_locationInView( testView )
        XCTAssertEqual( locationInView, verificationPoint )
        
        event = NSEvent.otherEventWithType(
            .ApplicationDefined,
            location: testLocation,
            modifierFlags: [],
            timestamp: timestamp,
            windowNumber: 0,
            context: nil,
            subtype: 1,
            data1: 2,
            data2: 3
        )
        XCTAssertNotNil( event )
        XCTAssertNil( event.obw_locationInView( testView ) )
        
        event = NSEvent.otherEventWithType(
            .Periodic,
            location: testLocation,
            modifierFlags: [],
            timestamp: timestamp,
            windowNumber: 0,
            context: nil,
            subtype: 1,
            data1: 2,
            data2: 3
        )
        XCTAssertNotNil( event )
        XCTAssertNil( event.obw_locationInView( testView ) )
    }
}
