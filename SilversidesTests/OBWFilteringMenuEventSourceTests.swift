/*===========================================================================
 OBWFilteringMenuEventSourceTests.swift
 Silversides
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import XCTest
@testable import OBWControls

/*==========================================================================*/

class OBWFilteringMenuEventSourceTests: XCTestCase {
    
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
    func testForegroundApplicationChangedEvents() {
        
        // These tests may fail if the user is switching foreground applications while the test is running, or conceivably if Finder.app is not running.
        
        let eventMask = NSEventMask.ApplicationDefined
        let eventWaitTime: NSTimeInterval = 0.05
        let threadSleepTime: NSTimeInterval = 0.10
        var event: NSEvent?
        
        let eventSource = OBWFilteringMenuEventSource()
        eventSource.eventMask = .ApplicationDidResignActive
        
        let finderApp = NSRunningApplication.runningApplicationsWithBundleIdentifier( "com.apple.finder" ).first
        
        // Activate Finder, SHOULD receive a deactivation event
        finderApp?.activateWithOptions( [] )
        NSThread.sleepForTimeInterval( threadSleepTime )
        event = NSApp.nextEventMatchingMask( eventMask, untilDate: NSDate( timeIntervalSinceNow: eventWaitTime ), inMode: NSDefaultRunLoopMode, dequeue: true )
        XCTAssertNotNil( event )
        XCTAssertEqual( event?.subtype.rawValue, OBWApplicationEventSubtype.ApplicationDidResignActive.rawValue )
        
        // Activate self, should NOT receive an activation event
        NSApp.activateIgnoringOtherApps( true )
        NSThread.sleepForTimeInterval( threadSleepTime )
        event = NSApp.nextEventMatchingMask( eventMask, untilDate: NSDate( timeIntervalSinceNow: eventWaitTime ), inMode: NSDefaultRunLoopMode, dequeue: true )
        XCTAssertNil( event )
        
        eventSource.eventMask = .ApplicationDidBecomeActive
        
        // Activate Finder, should NOT receive a deactivation event
        finderApp?.activateWithOptions( [] )
        NSThread.sleepForTimeInterval( threadSleepTime )
        event = NSApp.nextEventMatchingMask( eventMask, untilDate: NSDate( timeIntervalSinceNow: eventWaitTime ), inMode: NSDefaultRunLoopMode, dequeue: true )
        XCTAssertNil( event )
        
        // Activate self, SHOULD receive an activation event
        NSApp.activateIgnoringOtherApps( true )
        NSThread.sleepForTimeInterval( threadSleepTime )
        event = NSApp.nextEventMatchingMask( eventMask, untilDate: NSDate( timeIntervalSinceNow: eventWaitTime ), inMode: NSDefaultRunLoopMode, dequeue: true )
        XCTAssertNotNil( event )
        XCTAssertEqual( event?.subtype.rawValue, OBWApplicationEventSubtype.ApplicationDidBecomeActive.rawValue )
        
        eventSource.eventMask = []
        
        // Activate Finder, should NOT receive a deactivation event
        finderApp?.activateWithOptions( [] )
        NSThread.sleepForTimeInterval( threadSleepTime )
        event = NSApp.nextEventMatchingMask( eventMask, untilDate: NSDate( timeIntervalSinceNow: eventWaitTime ), inMode: NSDefaultRunLoopMode, dequeue: true )
        XCTAssertNil( event )
        
        // Activate self, should NOT receive an activation event
        NSApp.activateIgnoringOtherApps( true )
        NSThread.sleepForTimeInterval( threadSleepTime )
        event = NSApp.nextEventMatchingMask( eventMask, untilDate: NSDate( timeIntervalSinceNow: eventWaitTime ), inMode: NSDefaultRunLoopMode, dequeue: true )
        XCTAssertNil( event )
        
        eventSource.eventMask = [ .ApplicationDidBecomeActive, .ApplicationDidResignActive ]
        
        // Activate Finder, SHOULD receive a deactivation event
        finderApp?.activateWithOptions( [] )
        NSThread.sleepForTimeInterval( threadSleepTime )
        event = NSApp.nextEventMatchingMask( eventMask, untilDate: NSDate( timeIntervalSinceNow: eventWaitTime ), inMode: NSDefaultRunLoopMode, dequeue: true )
        XCTAssertNotNil( event )
        XCTAssertEqual( event?.subtype.rawValue, OBWApplicationEventSubtype.ApplicationDidResignActive.rawValue )
        
        // Activate self, SHOULD receive an activation event
        NSApp.activateIgnoringOtherApps( true )
        NSThread.sleepForTimeInterval( threadSleepTime )
        event = NSApp.nextEventMatchingMask( eventMask, untilDate: NSDate( timeIntervalSinceNow: eventWaitTime ), inMode: NSDefaultRunLoopMode, dequeue: true )
        XCTAssertNotNil( event )
        XCTAssertEqual( event?.subtype.rawValue, OBWApplicationEventSubtype.ApplicationDidBecomeActive.rawValue )
        
        eventSource.eventMask = []
        
        let xcodeApp = NSRunningApplication.runningApplicationsWithBundleIdentifier( "com.orderedbytes.SilversidesApp" ).first
        xcodeApp?.activateWithOptions( [] )
    }
    
    /*==========================================================================*/
    func testPeriodicEvents() {
        
        let startInterval = NSDate.timeIntervalSinceReferenceDate()
        let eventWaitTime: NSTimeInterval = 0.25
        
        let eventSource = OBWFilteringMenuEventSource()
        
        eventSource.startPeriodicApplicationEventsAfterDelay( 0.20, withPeriod: 0.05 )
        
        let mask = NSEventMask.ApplicationDefined
        
        let cocoaEvent1 = NSApp.nextEventMatchingMask( mask, untilDate: NSDate( timeIntervalSinceNow: eventWaitTime ), inMode: NSDefaultRunLoopMode, dequeue: true )
        let eventInterval1 = NSDate.timeIntervalSinceReferenceDate()
        
        let cocoaEvent2 = NSApp.nextEventMatchingMask( mask, untilDate: NSDate( timeIntervalSinceNow: eventWaitTime ), inMode: NSDefaultRunLoopMode, dequeue: true )
        let eventInterval2 = NSDate.timeIntervalSinceReferenceDate()
        
        let cocoaEvent3 = NSApp.nextEventMatchingMask( mask, untilDate: NSDate( timeIntervalSinceNow: eventWaitTime ), inMode: NSDefaultRunLoopMode, dequeue: true )
        let eventInterval3 = NSDate.timeIntervalSinceReferenceDate()
        
        XCTAssertNotNil( cocoaEvent1 )
        XCTAssertEqualWithAccuracy( startInterval + 0.20, eventInterval1, accuracy: 0.005 )
        
        XCTAssertNotNil( cocoaEvent2 )
        XCTAssertEqualWithAccuracy( startInterval + 0.25, eventInterval2, accuracy: 0.005 )
        
        XCTAssertNotNil( cocoaEvent3 )
        XCTAssertEqualWithAccuracy( startInterval + 0.30, eventInterval3, accuracy: 0.005 )
        
        eventSource.stopPeriodicApplicationEvents()
        
        let cocoaEvent4 = NSApp.nextEventMatchingMask( mask, untilDate: NSDate( timeIntervalSinceNow: eventWaitTime ), inMode: NSDefaultRunLoopMode, dequeue: true )
        
        XCTAssertNil( cocoaEvent4 )
    }
    
}
