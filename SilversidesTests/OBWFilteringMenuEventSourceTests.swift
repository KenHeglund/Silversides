/*===========================================================================
 OBWFilteringMenuEventSourceTests.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import XCTest
@testable import OBWControls

class OBWFilteringMenuEventSourceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testForegroundApplicationChangedEvents() {
        
        // These tests may fail if the user is switching foreground applications while the test is running, or conceivably if Finder.app is not running.
        
        let eventMask = NSEvent.EventTypeMask.applicationDefined
        let eventWaitTime: TimeInterval = 0.050
        let threadSleepTime: TimeInterval = 0.100
        var event: NSEvent?
        
        let eventSource = OBWFilteringMenuEventSource()
        eventSource.isApplicationDidResignActiveEventEnabled = true
        
        let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder")[0]
        
        NSApp.activate(ignoringOtherApps: true)
        Thread.sleep(forTimeInterval: threadSleepTime)
        
        // Activate Finder, SHOULD receive a deactivation event
        finderApp.activate(options: [])
        Thread.sleep(forTimeInterval: threadSleepTime)
        event = NSApp.nextEvent(matching: eventMask, until: Date(timeIntervalSinceNow: eventWaitTime), inMode: .default, dequeue: true)
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.subtype.rawValue, OBWFilteringMenuEventSubtype.applicationDidResignActive.rawValue)
        
        // Activate self, should NOT receive an activation event
        NSApp.activate(ignoringOtherApps: true)
        Thread.sleep(forTimeInterval: threadSleepTime)
        event = NSApp.nextEvent(matching: eventMask, until: Date(timeIntervalSinceNow: eventWaitTime), inMode: .default, dequeue: true)
        XCTAssertNil(event)
        
        eventSource.isApplicationDidResignActiveEventEnabled = false
        eventSource.isApplicationDidBecomeActiveEventEnabled = true

        // Activate Finder, should NOT receive a deactivation event
        finderApp.activate(options: [])
        Thread.sleep(forTimeInterval: threadSleepTime)
        event = NSApp.nextEvent(matching: eventMask, until: Date(timeIntervalSinceNow: eventWaitTime), inMode: .default, dequeue: true)
        XCTAssertNil(event)
        
        // Activate self, SHOULD receive an activation event
        NSApp.activate(ignoringOtherApps: true)
        Thread.sleep(forTimeInterval: threadSleepTime)
        event = NSApp.nextEvent(matching: eventMask, until: Date(timeIntervalSinceNow: eventWaitTime), inMode: .default, dequeue: true)
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.subtype.rawValue, OBWFilteringMenuEventSubtype.applicationDidBecomeActive.rawValue)
        
        eventSource.isApplicationDidBecomeActiveEventEnabled = false

        // Activate Finder, should NOT receive a deactivation event
        finderApp.activate(options: [])
        Thread.sleep(forTimeInterval: threadSleepTime)
        event = NSApp.nextEvent(matching: eventMask, until: Date(timeIntervalSinceNow: eventWaitTime), inMode: .default, dequeue: true)
        XCTAssertNil(event)
        
        // Activate self, should NOT receive an activation event
        NSApp.activate(ignoringOtherApps: true)
        Thread.sleep(forTimeInterval: threadSleepTime)
        event = NSApp.nextEvent(matching: eventMask, until: Date(timeIntervalSinceNow: eventWaitTime), inMode: .default, dequeue: true)
        XCTAssertNil(event)
        
        eventSource.isApplicationDidBecomeActiveEventEnabled = true
        eventSource.isApplicationDidResignActiveEventEnabled = true

        // Activate Finder, SHOULD receive a deactivation event
        finderApp.activate(options: [])
        Thread.sleep(forTimeInterval: threadSleepTime)
        event = NSApp.nextEvent(matching: eventMask, until: Date(timeIntervalSinceNow: eventWaitTime), inMode: .default, dequeue: true)
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.subtype.rawValue, OBWFilteringMenuEventSubtype.applicationDidResignActive.rawValue)
        
        // Activate self, SHOULD receive an activation event
        NSApp.activate(ignoringOtherApps: true)
        Thread.sleep(forTimeInterval: threadSleepTime)
        event = NSApp.nextEvent(matching: eventMask, until: Date(timeIntervalSinceNow: eventWaitTime), inMode: .default, dequeue: true)
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.subtype.rawValue, OBWFilteringMenuEventSubtype.applicationDidBecomeActive.rawValue)
        
        eventSource.isApplicationDidBecomeActiveEventEnabled = false
        eventSource.isApplicationDidResignActiveEventEnabled = false
    }
    
    func testPeriodicEvents() {
        
        let startInterval = Date.timeIntervalSinceReferenceDate
        let eventWaitTime: TimeInterval = 0.25
        
        let eventSource = OBWFilteringMenuEventSource()
        
        eventSource.startPeriodicApplicationEvents(afterDelay: 0.20, withPeriod: 0.05)
        
        let mask = NSEvent.EventTypeMask.applicationDefined
        
        let cocoaEvent1 = NSApp.nextEvent(matching: mask, until: Date(timeIntervalSinceNow: eventWaitTime), inMode: .default, dequeue: true)
        let eventInterval1 = Date.timeIntervalSinceReferenceDate
        
        let cocoaEvent2 = NSApp.nextEvent(matching: mask, until: Date(timeIntervalSinceNow: eventWaitTime), inMode: .default, dequeue: true)
        let eventInterval2 = Date.timeIntervalSinceReferenceDate
        
        let cocoaEvent3 = NSApp.nextEvent(matching: mask, until: Date(timeIntervalSinceNow: eventWaitTime), inMode: .default, dequeue: true)
        let eventInterval3 = Date.timeIntervalSinceReferenceDate
        
        XCTAssertNotNil(cocoaEvent1)
        XCTAssertEqual(startInterval + 0.20, eventInterval1, accuracy: 0.005)
        
        XCTAssertNotNil(cocoaEvent2)
        XCTAssertEqual(startInterval + 0.25, eventInterval2, accuracy: 0.005)
        
        XCTAssertNotNil(cocoaEvent3)
        XCTAssertEqual(startInterval + 0.30, eventInterval3, accuracy: 0.005)
        
        eventSource.stopPeriodicApplicationEvents()
        
        let cocoaEvent4 = NSApp.nextEvent(matching: mask, until: Date(timeIntervalSinceNow: eventWaitTime), inMode: .default, dequeue: true)
        
        XCTAssertNil(cocoaEvent4)
    }
    
}
