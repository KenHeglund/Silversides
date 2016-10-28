/*===========================================================================
 OBWFilteringMenuBackgroundTests.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import XCTest
@testable import OBWControls

/*==========================================================================*/

class OBWFilteringMenuBackgroundTests: XCTestCase {
    
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
    func testThatAllCornersAreRoundedByDefault() {
        
        let frame = NSRect( width: 40.0, height: 60.0 )
        let background = OBWFilteringMenuBackground( frame: frame )
        XCTAssertEqual( self.roundedCornersForBackground( background ), OBWFilteringMenuCorners.All )
    }
    
    /*==========================================================================*/
    func testThatTheMaskImageUpdatesCornersCorrectly() {
        
        let frame = NSRect( width: 40.0, height: 60.0 )
        let background = OBWFilteringMenuBackground( frame: frame )
        
        for rawValue: UInt in 0...15 {
            
            let corners = OBWFilteringMenuCorners( rawValue: rawValue )
            background.roundedCorners = corners
            XCTAssertEqual( self.roundedCornersForBackground( background ), corners, "corners: \(rawValue)" )
        }
    }
    
    /*==========================================================================*/
    private func roundedCornersForBackground( view: OBWFilteringMenuBackground ) -> OBWFilteringMenuCorners {
        
        guard let image = view.maskImage else { return [] }
        let imageFrame = NSRect( size: image.size )
        
        var roundedCorners: OBWFilteringMenuCorners = []
        
        var testRect = NSRect( x: imageFrame.origin.x, y: imageFrame.maxY - 1.0, width: 1.0, height: 1.0 )
        if !image.hitTestRect( testRect, withImageDestinationRect: imageFrame, context: nil, hints: nil, flipped: false ) {
            roundedCorners.insert( .TopLeft )
        }
        
        testRect.origin.y = imageFrame.origin.y
        if !image.hitTestRect( testRect, withImageDestinationRect: imageFrame, context: nil, hints: nil, flipped: false ) {
            roundedCorners.insert( .BottomLeft )
        }
        
        testRect.origin.x = imageFrame.maxX - 1.0
        if !image.hitTestRect( testRect, withImageDestinationRect: imageFrame, context: nil, hints: nil, flipped: false ) {
            roundedCorners.insert( .BottomRight )
        }

        testRect.origin.y = imageFrame.maxY - 1.0
        if !image.hitTestRect( testRect, withImageDestinationRect: imageFrame, context: nil, hints: nil, flipped: false ) {
            roundedCorners.insert( .TopRight )
        }
        
        return roundedCorners
    }
    
}
