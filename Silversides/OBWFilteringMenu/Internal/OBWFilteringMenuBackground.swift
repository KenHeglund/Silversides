/*===========================================================================
 OBWFilteringMenuBackground.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

struct OBWFilteringMenuCorners: OptionSet, Hashable {
    
    init(rawValue: UInt) {
        self.rawValue = rawValue & 0xF
    }
    
    private(set) var rawValue: UInt
    
    static let topLeft      = OBWFilteringMenuCorners(rawValue: 1 << 0)
    static let topRight     = OBWFilteringMenuCorners(rawValue: 1 << 1)
    static let bottomLeft   = OBWFilteringMenuCorners(rawValue: 1 << 2)
    static let bottomRight  = OBWFilteringMenuCorners(rawValue: 1 << 3)
    
    static let all: OBWFilteringMenuCorners = [topLeft, topRight, bottomLeft, bottomRight]
}

/*==========================================================================*/
// MARK: -

class OBWFilteringMenuBackground: NSVisualEffectView {
    
    /*==========================================================================*/
    override init(frame frameRect: NSRect) {
        
        super.init(frame: frameRect)
        
        self.autoresizingMask = [.width, .height]
        self.autoresizesSubviews = true
        
        self.material = .menu
        self.state = .active
        
        self.updateMaskImage()
    }
    
    /*==========================================================================*/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuBackground internal
    
    /*==========================================================================*/
    var roundedCorners = OBWFilteringMenuCorners.all {
        
        didSet {
            self.updateMaskImage()
        }
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuBackground private
    
    static let roundedCornerRadius: CGFloat = 6.0
    static let squareCornerRadius: CGFloat = 0.0
    
    private static var maskImageCache: [OBWFilteringMenuCorners:NSImage] = [:]
    
    /*==========================================================================*/
    func updateMaskImage() {
        
        let maskImage: NSImage
        
        if let existingImage = OBWFilteringMenuBackground.maskImageCache[self.roundedCorners] {
            maskImage = existingImage
        }
        else {
            maskImage = OBWFilteringMenuBackground.maskImage(self.roundedCorners)
            OBWFilteringMenuBackground.maskImageCache[self.roundedCorners] = maskImage
        }
        
        self.maskImage = maskImage
    }
    
    /*==========================================================================*/
    private static func maskImage(_ roundedCorners: OBWFilteringMenuCorners) -> NSImage {
        
        let roundedCornerRadius = OBWFilteringMenuBackground.roundedCornerRadius
        let squareCornerRadius = OBWFilteringMenuBackground.squareCornerRadius
        
        let topLeftRadius = roundedCorners.contains(.topLeft) ? roundedCornerRadius : squareCornerRadius
        let bottomLeftRadius = roundedCorners.contains(.bottomLeft) ? roundedCornerRadius : squareCornerRadius
        let bottomRightRadius = roundedCorners.contains(.bottomRight) ? roundedCornerRadius : squareCornerRadius
        let topRightRadius = roundedCorners.contains(.topRight) ? roundedCornerRadius : squareCornerRadius
        
        let bounds = NSRect(
            width: roundedCornerRadius * 3.0,
            height: roundedCornerRadius * 3.0
        )
        
        let topLeftPoint = NSPoint(x: bounds.origin.x + topLeftRadius, y: bounds.maxY - topLeftRadius)
        let bottomLeftPoint = NSPoint(x: bounds.origin.x + bottomLeftRadius, y: bounds.origin.y + bottomLeftRadius)
        let bottomRightPoint = NSPoint(x: bounds.maxX - bottomRightRadius, y: bounds.origin.y + bottomRightRadius)
        let topRightPoint = NSPoint(x: bounds.maxX - topRightRadius, y: bounds.maxY - topRightRadius)
        
        let path = NSBezierPath()
        path.appendArc(withCenter: bottomLeftPoint, radius: bottomLeftRadius, startAngle: -180.0, endAngle: -90.0)
        path.appendArc(withCenter: bottomRightPoint, radius: bottomRightRadius, startAngle: -90.0, endAngle: 0.0)
        path.appendArc(withCenter: topRightPoint, radius: topRightRadius, startAngle: 0.0, endAngle: 90.0)
        path.appendArc(withCenter: topLeftPoint, radius: topLeftRadius, startAngle: 90.0, endAngle: 180.0)
        path.close()
        
        let maskImage = NSImage(size: bounds.size)
        maskImage.withLockedFocus {
            path.fill()
        }
        
        maskImage.resizingMode = .stretch
        maskImage.capInsets = NSEdgeInsets(
            top: roundedCornerRadius + 1.0,
            left: roundedCornerRadius + 1.0,
            bottom: roundedCornerRadius + 1.0,
            right: roundedCornerRadius + 1.0
        )
        
        return maskImage
    }
}
