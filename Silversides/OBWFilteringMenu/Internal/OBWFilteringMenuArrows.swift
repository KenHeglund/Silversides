/*===========================================================================
 OBWFilteringMenuArrows.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

class OBWFilteringMenuArrows {
    
    // MARK: - OBWFilteringMenuArrows implementation
    
    /*==========================================================================*/
    static let upArrow: NSImage = {
        
        let flatSideInset = OBWFilteringMenuArrows.longSideInset
        
        let frame = NSRect(
            width: OBWFilteringMenuArrows.arrowLongSideLength,
            height: OBWFilteringMenuArrows.arrowShortSideLength
        )
        
        let path = NSBezierPath()
        path.move( to: NSPoint( x: frame.size.width, y: flatSideInset ) )
        path.line( to: NSPoint( x: frame.size.width / 2.0, y: frame.size.height ) )
        path.line( to: NSPoint( x: 0.0, y: flatSideInset ) )
        path.close()
        
        let image = NSImage( size: frame.size )
        image.withLockedFocus {
            NSColor( deviceWhite: 0.25, alpha: 1.0 ).set()
            path.fill()
        }
        
        return image
    }()
    
    /*==========================================================================*/
    static let downArrow: NSImage = {
        
        let flatSideInset = OBWFilteringMenuArrows.longSideInset
        
        let frame = NSRect(
            width: OBWFilteringMenuArrows.arrowLongSideLength,
            height: OBWFilteringMenuArrows.arrowShortSideLength
        )
        
        let path = NSBezierPath()
        path.move( to: NSPoint( x: 0.0, y: frame.size.height - flatSideInset ) )
        path.line( to: NSPoint( x: frame.size.width / 2.0, y: 0.0 ) )
        path.line( to: NSPoint( x: frame.size.width, y: frame.size.height - flatSideInset ) )
        path.close()
        
        let image = NSImage( size: frame.size )
        image.withLockedFocus {
            NSColor( deviceWhite: 0.25, alpha: 1.0 ).set()
            path.fill()
        }
        
        return image
    }()
    
    /*==========================================================================*/
    static let whiteRightArrow: NSImage = {
        
        let path = OBWFilteringMenuArrows.rightArrowPath
        
        let imageSize = NSIntegralRect( path.bounds ).size
        let image = NSImage( size: imageSize )
        image.withLockedFocus {
            NSColor( deviceWhite: 1.0, alpha: 1.0 ).set()
            path.fill()
        }
        
        return image
    }()
    
    /*==========================================================================*/
    static let blackRightArrow: NSImage = {
        
        let path = OBWFilteringMenuArrows.rightArrowPath
        
        let imageSize = NSIntegralRect( path.bounds ).size
        let image = NSImage( size: imageSize )
        image.withLockedFocus {
            NSColor( deviceWhite: 0.25, alpha: 1.0 ).set()
            path.fill()
        }
        
        return image
    }()
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuArrows private
    
    // The long side of each triangle is inset by 1.0 point to deliberately create a partially transparent edge when the image is scaled to the display size.
    fileprivate static let longSideInset: CGFloat = 1.0
    fileprivate static let arrowShortSideLength: CGFloat = 87.0
    fileprivate static let arrowLongSideLength: CGFloat = 100.0
    
    fileprivate static let rightArrowPath: NSBezierPath = {
        
        let flatSideInset = OBWFilteringMenuArrows.longSideInset
        
        let frame = NSRect(
            width: OBWFilteringMenuArrows.arrowShortSideLength,
            height: OBWFilteringMenuArrows.arrowLongSideLength
        )
        
        let rightArrowPath = NSBezierPath()
        rightArrowPath.move( to: NSPoint( x: flatSideInset, y: 0.0 ) )
        rightArrowPath.line( to: NSPoint( x: frame.size.width, y: frame.size.height / 2.0 ) )
        rightArrowPath.line( to: NSPoint( x: flatSideInset, y: frame.size.height ) )
        rightArrowPath.close()
        
        return rightArrowPath
    }()
    
}
