/*===========================================================================
 NSView+OBWExtensionTests.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import XCTest
@testable import OBWControls

/*==========================================================================*/

class NSView_OBWExtensionTests: XCTestCase {
    
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
    func testLowerLeftPoint() {
        
        let frame = NSRect( x: 11.0, y: 17.0, width: 23.0, height: 37.0 )
        
        let view = NSView( frame: frame )
        XCTAssertEqual( view.obw_boundsLowerLeftPoint, NSZeroPoint )
        
        let flippedView = FlippedView( frame: frame )
        XCTAssertEqual( flippedView.obw_boundsLowerLeftPoint, NSPoint( x: 0.0, y: frame.size.height ) )
    }
    
    /*==========================================================================*/
    func testBoundsInScreen() {
        
        let windowContentFrame = NSRect( x: 200.0, y: 300.0, width: 400.0, height: 500.0 )
        let window = NSWindow( contentRect: windowContentFrame, styleMask: NSBorderlessWindowMask, backing: .Buffered, defer: true )
        
        let viewFrame = NSRect( x: 40.0, y: 60.0, width: 35.0, height: 55.0 )
        let testView = NSView( frame: viewFrame )
        window.contentView?.addSubview( testView )
        
        let boundsInScreen = testView.obw_boundsInScreen
        
        let verificationRect = NSRect(
            x: windowContentFrame.origin.x + viewFrame.origin.x,
            y: windowContentFrame.origin.y + viewFrame.origin.y,
            width: viewFrame.size.width,
            height: viewFrame.size.height
        )
        
        XCTAssertEqual( boundsInScreen, verificationRect )
        
        let locationInView = NSPoint( x: 7.0, y: 17.0 )
        
        let verificationPoint = NSPoint(
            x: windowContentFrame.origin.x + viewFrame.origin.x + locationInView.x,
            y: windowContentFrame.origin.y + viewFrame.origin.y + locationInView.y
        )
        
        let locationInScreen = testView.obw_convertPointToScreen( locationInView )
        
        XCTAssertEqual( locationInScreen, verificationPoint )
    }
    
}

/*==========================================================================*/

private class FlippedView: NSView {
    override var flipped: Bool { return true }
}
