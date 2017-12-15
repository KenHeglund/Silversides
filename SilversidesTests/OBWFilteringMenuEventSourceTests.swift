/*===========================================================================
 OBWFilteringMenuEventSourceTests.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
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
        
        let eventMask = NSEventMask.applicationDefined
        let eventWaitTime: TimeInterval = 0.050
        let threadSleepTime: TimeInterval = 0.100
        var event: NSEvent?
        
        let eventSource = OBWFilteringMenuEventSource()
        eventSource.eventMask = .ApplicationDidResignActive
        
        let finderApp = NSRunningApplication.runningApplications( withBundleIdentifier: "com.apple.finder" ).first!
        
        NSApp.activate( ignoringOtherApps: true )
        Thread.sleep( forTimeInterval: threadSleepTime )
        
        // Activate Finder, SHOULD receive a deactivation event
        finderApp.activate( options: [] )
        Thread.sleep( forTimeInterval: threadSleepTime )
        event = NSApp.nextEvent( matching: eventMask, until: Date( timeIntervalSinceNow: eventWaitTime ), inMode: RunLoopMode.defaultRunLoopMode, dequeue: true )
        XCTAssertNotNil( event )
        XCTAssertEqual( event?.subtype.rawValue, OBWApplicationEventSubtype.ApplicationDidResignActive.rawValue )
        
        // Activate self, should NOT receive an activation event
        NSApp.activate( ignoringOtherApps: true )
        Thread.sleep( forTimeInterval: threadSleepTime )
        event = NSApp.nextEvent( matching: eventMask, until: Date( timeIntervalSinceNow: eventWaitTime ), inMode: RunLoopMode.defaultRunLoopMode, dequeue: true )
        XCTAssertNil( event )
        
        eventSource.eventMask = .ApplicationDidBecomeActive
        
        // Activate Finder, should NOT receive a deactivation event
        finderApp.activate( options: [] )
        Thread.sleep( forTimeInterval: threadSleepTime )
        event = NSApp.nextEvent( matching: eventMask, until: Date( timeIntervalSinceNow: eventWaitTime ), inMode: RunLoopMode.defaultRunLoopMode, dequeue: true )
        XCTAssertNil( event )
        
        // Activate self, SHOULD receive an activation event
        NSApp.activate( ignoringOtherApps: true )
        Thread.sleep( forTimeInterval: threadSleepTime )
        event = NSApp.nextEvent( matching: eventMask, until: Date( timeIntervalSinceNow: eventWaitTime ), inMode: RunLoopMode.defaultRunLoopMode, dequeue: true )
        XCTAssertNotNil( event )
        XCTAssertEqual( event?.subtype.rawValue, OBWApplicationEventSubtype.ApplicationDidBecomeActive.rawValue )
        
        eventSource.eventMask = []
        
        // Activate Finder, should NOT receive a deactivation event
        finderApp.activate( options: [] )
        Thread.sleep( forTimeInterval: threadSleepTime )
        event = NSApp.nextEvent( matching: eventMask, until: Date( timeIntervalSinceNow: eventWaitTime ), inMode: RunLoopMode.defaultRunLoopMode, dequeue: true )
        XCTAssertNil( event )
        
        // Activate self, should NOT receive an activation event
        NSApp.activate( ignoringOtherApps: true )
        Thread.sleep( forTimeInterval: threadSleepTime )
        event = NSApp.nextEvent( matching: eventMask, until: Date( timeIntervalSinceNow: eventWaitTime ), inMode: RunLoopMode.defaultRunLoopMode, dequeue: true )
        XCTAssertNil( event )
        
        eventSource.eventMask = [ .ApplicationDidBecomeActive, .ApplicationDidResignActive ]
        
        // Activate Finder, SHOULD receive a deactivation event
        finderApp.activate( options: [] )
        Thread.sleep( forTimeInterval: threadSleepTime )
        event = NSApp.nextEvent( matching: eventMask, until: Date( timeIntervalSinceNow: eventWaitTime ), inMode: RunLoopMode.defaultRunLoopMode, dequeue: true )
        XCTAssertNotNil( event )
        XCTAssertEqual( event?.subtype.rawValue, OBWApplicationEventSubtype.ApplicationDidResignActive.rawValue )
        
        // Activate self, SHOULD receive an activation event
        NSApp.activate( ignoringOtherApps: true )
        Thread.sleep( forTimeInterval: threadSleepTime )
        event = NSApp.nextEvent( matching: eventMask, until: Date( timeIntervalSinceNow: eventWaitTime ), inMode: RunLoopMode.defaultRunLoopMode, dequeue: true )
        XCTAssertNotNil( event )
        XCTAssertEqual( event?.subtype.rawValue, OBWApplicationEventSubtype.ApplicationDidBecomeActive.rawValue )
        
        eventSource.eventMask = []
    }
    
    /*==========================================================================*/
    func testPeriodicEvents() {
        
        let startInterval = Date.timeIntervalSinceReferenceDate
        let eventWaitTime: TimeInterval = 0.25
        
        let eventSource = OBWFilteringMenuEventSource()
        
        eventSource.startPeriodicApplicationEventsAfterDelay( 0.20, withPeriod: 0.05 )
        
        let mask = NSEventMask.applicationDefined
        
        let cocoaEvent1 = NSApp.nextEvent( matching: mask, until: Date( timeIntervalSinceNow: eventWaitTime ), inMode: RunLoopMode.defaultRunLoopMode, dequeue: true )
        let eventInterval1 = Date.timeIntervalSinceReferenceDate
        
        let cocoaEvent2 = NSApp.nextEvent( matching: mask, until: Date( timeIntervalSinceNow: eventWaitTime ), inMode: RunLoopMode.defaultRunLoopMode, dequeue: true )
        let eventInterval2 = Date.timeIntervalSinceReferenceDate
        
        let cocoaEvent3 = NSApp.nextEvent( matching: mask, until: Date( timeIntervalSinceNow: eventWaitTime ), inMode: RunLoopMode.defaultRunLoopMode, dequeue: true )
        let eventInterval3 = Date.timeIntervalSinceReferenceDate
        
        XCTAssertNotNil( cocoaEvent1 )
        XCTAssertEqualWithAccuracy( startInterval + 0.20, eventInterval1, accuracy: 0.005 )
        
        XCTAssertNotNil( cocoaEvent2 )
        XCTAssertEqualWithAccuracy( startInterval + 0.25, eventInterval2, accuracy: 0.005 )
        
        XCTAssertNotNil( cocoaEvent3 )
        XCTAssertEqualWithAccuracy( startInterval + 0.30, eventInterval3, accuracy: 0.005 )
        
        eventSource.stopPeriodicApplicationEvents()
        
        let cocoaEvent4 = NSApp.nextEvent( matching: mask, until: Date( timeIntervalSinceNow: eventWaitTime ), inMode: RunLoopMode.defaultRunLoopMode, dequeue: true )
        
        XCTAssertNil( cocoaEvent4 )
    }
    
}
