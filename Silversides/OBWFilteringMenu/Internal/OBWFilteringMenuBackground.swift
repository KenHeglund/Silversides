/*===========================================================================
 OBWFilteringMenuBackground.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

struct OBWFilteringMenuCorners: OptionSetType {
    
    init( rawValue: UInt ) {
        self.rawValue = rawValue & 0xF
    }
    
    private(set) var rawValue: UInt
    
    static let TopLeft      = OBWFilteringMenuCorners( rawValue: 1 << 0 )
    static let TopRight     = OBWFilteringMenuCorners( rawValue: 1 << 1 )
    static let BottomLeft   = OBWFilteringMenuCorners( rawValue: 1 << 2 )
    static let BottomRight  = OBWFilteringMenuCorners( rawValue: 1 << 3 )
    
    static let All: OBWFilteringMenuCorners = [ TopLeft, TopRight, BottomLeft, BottomRight ]
}

/*==========================================================================*/
// MARK: -

class OBWFilteringMenuBackground: NSVisualEffectView {
    
    /*==========================================================================*/
    override init( frame frameRect: NSRect ) {
        
        super.init( frame: frameRect )
        
        self.autoresizingMask = [ .ViewWidthSizable, .ViewHeightSizable ]
        self.autoresizesSubviews = true
        
        self.material = .Menu
        self.state = .Active
        
        self.resetMaskImage()
    }
    
    /*==========================================================================*/
    required init?( coder: NSCoder ) {
        fatalError( "init(coder:) has not been implemented" )
    }
    
    /*==========================================================================*/
    // MARK: - NSView overrides
    
    /*==========================================================================*/
    override func resizeWithOldSuperviewSize( oldSize: NSSize ) {
        
        super.resizeWithOldSuperviewSize( oldSize )
        
        // TODO: -NSImage.capInsets / -NSImage.resizingMode
        // Look into using the NSImage -capInsets and -resizingMode properties of the view's mask image to account for different view sizes.  It may be possible to use a single image (for a given combination of rounded corners) regardless of view size.  That would eliminate the need to rebuild the mask image when the view resizes.
        
        self.resetMaskImage()
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuBackground internal
    
    /*==========================================================================*/
    var roundedCorners = OBWFilteringMenuCorners.All {
        
        didSet ( previousCorners ) {
            
            let changedCorners = self.roundedCorners.exclusiveOr( previousCorners )
            
            if changedCorners.isEmpty { return }
            
            let bounds = self.bounds
            let roundedCornerRadius = OBWFilteringMenuBackground.roundedCornerRadius
            
            var dirtyRect = NSRect(
                x: bounds.origin.x,
                y: bounds.origin.y,
                width: roundedCornerRadius,
                height: roundedCornerRadius )
            
            if changedCorners.contains( .BottomLeft ) {
                self.setNeedsDisplayInRect( dirtyRect )
            }
            
            dirtyRect.origin.y = bounds.maxY - roundedCornerRadius
            
            if changedCorners.contains( .TopLeft ) {
                self.setNeedsDisplayInRect( dirtyRect )
            }
            
            dirtyRect.origin.x = bounds.maxX - roundedCornerRadius
            
            if changedCorners.contains( .TopRight ) {
                self.setNeedsDisplayInRect( dirtyRect )
            }
            
            dirtyRect.origin.y = bounds.origin.y
            
            if changedCorners.contains( .BottomRight ) {
                self.setNeedsDisplayInRect( dirtyRect )
            }
            
            self.resetMaskImage()
        }
    }
    
    /*==========================================================================*/
    func resetMaskImage() {
        
        let maskImage = NSImage( size: self.frame.size )
        maskImage.withLockedFocus { 
            self.maskPath.fill()
        }
        
        self.maskImage = maskImage
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuBackground private
    
    static let roundedCornerRadius: CGFloat = 6.0
    static let squareCornerRadius: CGFloat = 0.0
    
    /*==========================================================================*/
    private var maskPath: NSBezierPath {
        
        let roundedCorners = self.roundedCorners
        let roundedCornerRadius = OBWFilteringMenuBackground.roundedCornerRadius
        let squareCornerRadius = OBWFilteringMenuBackground.squareCornerRadius
        
        let topLeftRadius = roundedCorners.contains( .TopLeft ) ? roundedCornerRadius : squareCornerRadius
        let bottomLeftRadius = roundedCorners.contains( .BottomLeft ) ? roundedCornerRadius : squareCornerRadius
        let bottomRightRadius = roundedCorners.contains( .BottomRight ) ? roundedCornerRadius : squareCornerRadius
        let topRightRadius = roundedCorners.contains( .TopRight ) ? roundedCornerRadius : squareCornerRadius
        
        let bounds = self.bounds
        
        let topLeftPoint = NSPoint( x: bounds.origin.x + topLeftRadius, y: bounds.maxY - topLeftRadius )
        let bottomLeftPoint = NSPoint( x: bounds.origin.x + bottomLeftRadius, y: bounds.origin.y + bottomLeftRadius )
        let bottomRightPoint = NSPoint( x: bounds.maxX - bottomRightRadius, y: bounds.origin.y + bottomRightRadius )
        let topRightPoint = NSPoint( x: bounds.maxX - topRightRadius, y: bounds.maxY - topRightRadius )
        
        let path = NSBezierPath()
        path.appendBezierPathWithArcWithCenter( bottomLeftPoint, radius: bottomLeftRadius, startAngle: -180.0, endAngle: -90.0 )
        path.appendBezierPathWithArcWithCenter( bottomRightPoint, radius: bottomRightRadius, startAngle: -90.0, endAngle: 0.0 )
        path.appendBezierPathWithArcWithCenter( topRightPoint, radius: topRightRadius, startAngle: 0.0, endAngle: 90.0 )
        path.appendBezierPathWithArcWithCenter( topLeftPoint, radius: topLeftRadius, startAngle: 90.0, endAngle: 180.0 )
        path.closePath()
        
        return path
    }
    
}
