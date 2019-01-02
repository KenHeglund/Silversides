/*===========================================================================
 NSRect+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/
// Insets an NSRect by NSEdgeInsets.
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

/*==========================================================================*/
// Expands an NSRect by NSEdgeInsets
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
    
    /*==========================================================================*/
    init(size: NSSize) {
        self.init(origin: .zero, size: size)
    }
    
    /*==========================================================================*/
    init(width: CGFloat, height: CGFloat) {
        self.init(x: 0.0, y: 0.0, width: width, height: height)
    }
    
    /*==========================================================================*/
    init(origin: NSPoint, width: CGFloat, height: CGFloat) {
        self.init(x: origin.x, y: origin.y, width: width, height: height)
    }
    
    /*==========================================================================*/
    init(x: CGFloat, y: CGFloat, size: NSSize) {
        self.init(x: x, y: y, width: size.width, height: size.height)
    }
    
}
