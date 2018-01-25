/*===========================================================================
 OBWFilteringMenuScrollTrackingTests.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import XCTest
@testable import OBWControls

/*==========================================================================*/

class OBWFilteringMenuScrollTrackingTests: XCTestCase {
    
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
    func testWhenEntireMenuIsAlreadyVisible() {
        
        // Setup
        
        let screen = NSScreen.screens.first!
        let screenFrame = screen.frame
        
        var notificationCount = 0
        let observation = NotificationCenter.default.addObserver( forName: OBWFilteringMenuScrollTrackingBoundsChangedNotification, object: nil, queue: nil) { ( notification: Notification ) in
            notificationCount += 1
        }
        
        let menu = OBWFilteringMenu( title: "menu" )
        for index in 1...20 {
            menu.addItem( OBWFilteringMenuItem( title: "item \(index)" ) )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        
        let menuLocation = NSPoint(
            x: floor( geometry.totalMenuItemSize.width / 2.0 ),
            y: floor( geometry.totalMenuItemSize.height / 2.0 )
        )
        
        let screenLocation = NSPoint(
            x: floor( screenFrame.midX ),
            y: floor( screenFrame.midY )
        )
        
        _ = geometry.updateGeometryToDisplayMenuLocation( menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false )
        
        let scrollTracking = OBWFilteringMenuScrollTracking()
        scrollTracking.reset( geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds )
        
        // Test
        
        scrollTracking.scrollEvent( self.scrollContentUpEvent )
        RunLoop.current.run( until: Date( timeIntervalSinceNow: 0.25 ) )
        XCTAssertEqual( notificationCount, 0 )
        
        scrollTracking.scrollEvent( self.scrollContentDownEvent )
        RunLoop.current.run( until: Date( timeIntervalSinceNow: 0.25 ) )
        XCTAssertEqual( notificationCount, 0 )
        
        NotificationCenter.default.removeObserver( observation )
    }
    
    /*==========================================================================*/
    func testScrollingDownWhenMenuOverlapsBottomOfScreen() {
        
        // When scrolling down while the menu overlaps the bottom of the screen, the content bounds origin should increase while the bounds height remains the same.  This is elastic movement of the menu content.
        
        // Setup
        
        let screen = NSScreen.screens.first!
        let screenFrame = screen.frame
        
        var notificationBounds = NSZeroRect
        let observation = NotificationCenter.default.addObserver( forName: OBWFilteringMenuScrollTrackingBoundsChangedNotification, object: nil, queue: nil) { ( notification: Notification ) in
            
            guard notificationBounds.isEmpty else { return }
            
            let userInfo = notification.userInfo!
            let boundsAsValue = userInfo[OBWFilteringMenuScrollTrackingBoundsValueKey] as! NSValue
            notificationBounds = boundsAsValue.rectValue
        }
        
        let menu = OBWFilteringMenu( title: "menu" )
        for index in 1...20 {
            menu.addItem( OBWFilteringMenuItem( title: "item \(index)" ) )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        
        let menuLocation = NSPoint( x: 0.0, y: geometry.totalMenuItemSize.height )
        let screenLocation = NSPoint(
            x: screenFrame.midX,
            y: screenFrame.origin.y + floor( geometry.totalMenuItemSize.height / 5.0 )
        )
        
        _ = geometry.updateGeometryToDisplayMenuLocation( menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false )
        
        let scrollTracking = OBWFilteringMenuScrollTracking()
        scrollTracking.reset( geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds )
        
        // Test
        
        scrollTracking.scrollEvent( self.scrollContentDownEvent )
        RunLoop.current.run( until: Date( timeIntervalSinceNow: 0.100 ) )
        XCTAssertGreaterThan( notificationBounds.origin.y, geometry.initialBounds.origin.y )
        XCTAssertEqual( notificationBounds.size.height, geometry.initialBounds.size.height )
        
        NotificationCenter.default.removeObserver( observation )
    }
    
    /*==========================================================================*/
    func testScrollingUpWhenMenuOverlapsBottomOfScreen() {
        
        // When scrolling up while the menu overlaps the bottom of the screen, the content bounds origin should decrease while the bounds height increases.  This is the menu content resizing upward.
        
        // Setup
        
        let screen = NSScreen.screens.first!
        let screenFrame = screen.frame
        
        var notificationBounds = NSZeroRect
        let observation = NotificationCenter.default.addObserver( forName: OBWFilteringMenuScrollTrackingBoundsChangedNotification, object: nil, queue: nil) { ( notification: Notification ) in
            
            guard notificationBounds.isEmpty else { return }
            
            let userInfo = notification.userInfo!
            let boundsAsValue = userInfo[OBWFilteringMenuScrollTrackingBoundsValueKey] as! NSValue
            notificationBounds = boundsAsValue.rectValue
        }
        
        let menu = OBWFilteringMenu( title: "menu" )
        for index in 1...20 {
            menu.addItem( OBWFilteringMenuItem( title: "item \(index)" ) )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        
        let menuLocation = NSPoint( x: 0.0, y: geometry.totalMenuItemSize.height )
        let screenLocation = NSPoint(
            x: screenFrame.midX,
            y: screenFrame.origin.y + floor( geometry.totalMenuItemSize.height / 5.0 )
        )
        
        _ = geometry.updateGeometryToDisplayMenuLocation( menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false )
        
        let scrollTracking = OBWFilteringMenuScrollTracking()
        scrollTracking.reset( geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds )
        
        // Test
        
        scrollTracking.scrollEvent( self.scrollContentUpEvent )
        RunLoop.current.run( until: Date( timeIntervalSinceNow: 0.500 ) )
        XCTAssertLessThan( notificationBounds.origin.y, geometry.initialBounds.origin.y )
        XCTAssertGreaterThan( notificationBounds.size.height, geometry.initialBounds.size.height )
        
        NotificationCenter.default.removeObserver( observation )
    }
    
    /*==========================================================================*/
    func testScrollingUpWhenMenuOverlapsTopOfScreen() {
        
        // When scrolling up while the menu overlaps the top of the screen, the content bounds origin should decrease while the bounds height remains the same.  This is elastic movement of the menu content.
        
        // Setup
        
        let screen = NSScreen.screens.first!
        let screenFrame = screen.frame
        
        var notificationBounds = NSZeroRect
        let observation = NotificationCenter.default.addObserver( forName: OBWFilteringMenuScrollTrackingBoundsChangedNotification, object: nil, queue: nil) { ( notification: Notification ) in
            
            guard notificationBounds.isEmpty else { return }
            
            let userInfo = notification.userInfo!
            let boundsAsValue = userInfo[OBWFilteringMenuScrollTrackingBoundsValueKey] as! NSValue
            notificationBounds = boundsAsValue.rectValue
        }
        
        let menu = OBWFilteringMenu( title: "menu" )
        for index in 1...20 {
            menu.addItem( OBWFilteringMenuItem( title: "item \(index)" ) )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        
        let menuLocation = NSZeroPoint
        let screenLocation = NSPoint(
            x: screenFrame.midX,
            y: screenFrame.maxY - floor( geometry.totalMenuItemSize.height / 5.0 )
        )
        
        _ = geometry.updateGeometryToDisplayMenuLocation( menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false )
        
        let scrollTracking = OBWFilteringMenuScrollTracking()
        scrollTracking.reset( geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds )
        
        // Test
        
        scrollTracking.scrollEvent( self.scrollContentUpEvent )
        RunLoop.current.run( until: Date( timeIntervalSinceNow: 0.25 ) )
        XCTAssertLessThan( notificationBounds.origin.y, geometry.initialBounds.origin.y )
        XCTAssertEqual( notificationBounds.size.height, geometry.initialBounds.size.height )
        
        NotificationCenter.default.removeObserver( observation )
    }
    
    /*==========================================================================*/
    func testScrollingDownWhenMenuOverlapsTopOfScreen() {
        
        // When scrolling down while the menu overlaps the top of the screen, the content bounds origin should remain the same while the bounds height increases.  This is the menu content resizing downward.
        
        // Setup
        
        let screen = NSScreen.screens.first!
        let screenFrame = screen.frame
        
        var notificationBounds = NSZeroRect
        let observation = NotificationCenter.default.addObserver( forName: OBWFilteringMenuScrollTrackingBoundsChangedNotification, object: nil, queue: nil) { ( notification: Notification ) in
            
            guard notificationBounds.isEmpty else { return }
            
            let userInfo = notification.userInfo!
            let boundsAsValue = userInfo[OBWFilteringMenuScrollTrackingBoundsValueKey] as! NSValue
            notificationBounds = boundsAsValue.rectValue
        }
        
        let menu = OBWFilteringMenu( title: "menu" )
        for index in 1...20 {
            menu.addItem( OBWFilteringMenuItem( title: "item \(index)" ) )
        }
        
        let window = OBWFilteringMenuWindow( menu: menu, screen: screen )
        let geometry = OBWFilteringMenuWindowGeometry( window: window )
        
        let menuLocation = NSZeroPoint
        let screenLocation = NSPoint(
            x: screenFrame.midX,
            y: screenFrame.maxY - floor( geometry.totalMenuItemSize.height / 5.0 )
        )
        
        _ = geometry.updateGeometryToDisplayMenuLocation( menuLocation, atScreenLocation: screenLocation, allowWindowToGrowUpward: false )
        
        let scrollTracking = OBWFilteringMenuScrollTracking()
        scrollTracking.reset( geometry.totalMenuItemSize, initialBounds: geometry.initialBounds, finalBounds: geometry.finalBounds )
        
        // Test
        
        scrollTracking.scrollEvent( self.scrollContentDownEvent )
        RunLoop.current.run( until: Date( timeIntervalSinceNow: 0.25 ) )
        XCTAssertEqual( notificationBounds.origin.y, geometry.initialBounds.origin.y )
        XCTAssertGreaterThan( notificationBounds.size.height, geometry.initialBounds.size.height )
        
        NotificationCenter.default.removeObserver( observation )
    }
    
    /*==========================================================================*/
    private let scrollContentUpEvent: NSEvent = {
        
        // Recorded from the trackpad
        let encodedContentUpEvent = "AAAAAgABQDUAAAADAAFANgAAAAAAAUA3AAAAFgACwDhEdkAARI6gAAACwDlByAAAQjgAAAABADpFSWCOAACUVgABQDsAAAEAAAFAMwAAI70AAUA0AAHH4wABQJIAAAAAAAFAagAAAGMAAUBrAAAEsAABQAv////8AAFADAAAAAAAAUANAAAAAAABQFgAAAABAAFAiQAAAAEAAUBd//szIAABQF4AAAAAAAFAXwAAAAAAAUBg////0AABQGEAAAADAAFAYgAAAAAAAUB7AAAAAAABQGMAAAACAAFAZAAAAAA="
        
        return OBWFilteringMenuScrollTrackingTests.eventWithString( base64EncodedString: encodedContentUpEvent )
    }()
    
    /*==========================================================================*/
    private let scrollContentDownEvent: NSEvent = {
        
        // Recorded from the trackpad
        let encodedContentDownEvent = "AAAAAgABQDUAAAADAAFANgAAAAAAAUA3AAAAFgACwDhEeEAARI0AAAACwDlCBAAAQgAAAAABADpKU4eYAACUdQABQDsAAAEAAAFAMwAAI+MAAUA0AAHg5wABQJIAAAAAAAFAagAAAGIAAUBrAAAEsAABQAsAAAA1AAFADP////8AAUANAAAAAAABQFgAAAABAAFAiQAAAAEAAUBdADVnPAABQF7//xmWAAFAXwAAAAAAAUBgAAACFgABQGH////4AAFAYgAAAAAAAUB7AAAAAAABQGMAAAACAAFAZAAAAAE="
        
        return OBWFilteringMenuScrollTrackingTests.eventWithString( base64EncodedString: encodedContentDownEvent )
    }()
    
    /*==========================================================================*/
    private class func eventWithString( base64EncodedString encodedString: String ) -> NSEvent {
        
        let scrollEventData = Data( base64Encoded: encodedString, options: [] )!
        let event = CGEvent( withDataAllocator: kCFAllocatorDefault, data: scrollEventData as CFData )!
        
        return NSEvent( cgEvent: event )!
    }
    
}
