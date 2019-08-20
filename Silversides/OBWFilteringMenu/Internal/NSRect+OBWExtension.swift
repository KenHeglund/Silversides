/*===========================================================================
 NSRect+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit

/// Returns a rect formed by adding the given edge insets to the given rect.  Positive insets will result in a smaller rect.  Will not return a rect with a negative width or height.
func +(lhs: NSRect, rhs: NSEdgeInsets) -> NSRect {
    
    var rect = lhs
    let insets = rhs
    
    if rect.size.width > insets.width {
        rect.origin.x += insets.left
        rect.size.width -= insets.width
    }
    else {
        rect.origin.x += floor(rect.size.width * insets.left / insets.width)
        rect.size.width = 0.0
    }
    
    if rect.size.height > insets.height {
        rect.origin.y += insets.bottom
        rect.size.height -= insets.height
    }
    else {
        rect.origin.y += floor(rect.size.height * insets.bottom / insets.height)
        rect.size.height = 0.0
    }
    
    return rect
}

/// Returns a rect formed by subtracting the given edge insets from the given rect.  Positive insets will result in a larger rect.
func -(lhs: NSRect, rhs: NSEdgeInsets) -> NSRect {
    
    var rect = lhs
    let insets = rhs
    
    rect.origin.x -= insets.left
    rect.origin.y -= insets.bottom
    rect.size.width += insets.width
    rect.size.height += insets.height
    
    return rect
}

/*==========================================================================*/

extension NSRect {
    
    /// Initializes an NSRect from an NSSize.  The origin of the NSRect will be .zero.
    init(size: NSSize) {
        self.init(origin: .zero, size: size)
    }
    
    /// Initializes an NSRect from a width and height.  The origin of the NSRect will be .zero.
    init(width: CGFloat, height: CGFloat) {
        self.init(x: 0.0, y: 0.0, width: width, height: height)
    }
    
    /// Initializes an NSRect from an origin, width, and height.
    init(origin: NSPoint, width: CGFloat, height: CGFloat) {
        self.init(x: origin.x, y: origin.y, width: width, height: height)
    }
    
    /// Initializes an NSRect from X and Y positions, and a size.
    init(x: CGFloat, y: CGFloat, size: NSSize) {
        self.init(x: x, y: y, width: size.width, height: size.height)
    }
    
}
