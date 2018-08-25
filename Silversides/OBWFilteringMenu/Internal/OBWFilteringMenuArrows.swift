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
        
        let frame = NSRect(
            width: OBWFilteringMenuArrows.arrowLongSideLength,
            height: OBWFilteringMenuArrows.arrowShortSideLength
        )
        
        let image = NSImage(size: frame.size, flipped: false, drawingHandler: {
            _ in
            
            let flatSideInset = OBWFilteringMenuArrows.longSideInset
            
            let path = NSBezierPath()
            path.move( to: NSPoint( x: frame.size.width, y: flatSideInset ) )
            path.line( to: NSPoint( x: frame.size.width / 2.0, y: frame.size.height ) )
            path.line( to: NSPoint( x: 0.0, y: flatSideInset ) )
            path.close()
            
            NSColor.secondaryLabelColor.set()
            path.fill()
            
            return true
        })
        
        return image
    }()
    
    /*==========================================================================*/
    static let downArrow: NSImage = {
        
        let frame = NSRect(
            width: OBWFilteringMenuArrows.arrowLongSideLength,
            height: OBWFilteringMenuArrows.arrowShortSideLength
        )
        
        let image = NSImage(size: frame.size, flipped: false, drawingHandler: {
            _ in
            
            let flatSideInset = OBWFilteringMenuArrows.longSideInset
            
            let path = NSBezierPath()
            path.move( to: NSPoint( x: 0.0, y: frame.size.height - flatSideInset ) )
            path.line( to: NSPoint( x: frame.size.width / 2.0, y: 0.0 ) )
            path.line( to: NSPoint( x: frame.size.width, y: frame.size.height - flatSideInset ) )
            path.close()
            
            NSColor.secondaryLabelColor.set()
            path.fill()
            
            return true
        })
        
        return image
    }()
    
    /*==========================================================================*/
    static let selectedRightArrow: NSImage = {
        
        let path = OBWFilteringMenuArrows.rightArrowPath
        let imageSize = NSIntegralRect( path.bounds ).size
        
        let image = NSImage(size: imageSize, flipped: false, drawingHandler: {
            _ in
            
            NSColor.selectedMenuItemTextColor.set()
            path.fill()
            
            return true
        })
        
        return image
    }()
    
    /*==========================================================================*/
    static let unselectedRightArrow: NSImage = {
        
        let path = OBWFilteringMenuArrows.rightArrowPath
        let imageSize = NSIntegralRect( path.bounds ).size
        
        let image = NSImage(size: imageSize, flipped: false, drawingHandler: {
            _ in
            
            NSColor.labelColor.set()
            path.fill()
            
            return true
        })
        
        return image
    }()
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuArrows private
    
    // The long side of each triangle is inset by 1.0 point to deliberately create a partially transparent edge when the image is scaled to the display size.
    private static let longSideInset: CGFloat = 1.0
    private static let arrowShortSideLength: CGFloat = 87.0
    private static let arrowLongSideLength: CGFloat = 100.0
    
    private static let rightArrowPath: NSBezierPath = {
        
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
