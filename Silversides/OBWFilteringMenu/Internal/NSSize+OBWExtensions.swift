/*===========================================================================
 NSSize+OBWExtensions.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Foundation

/// Returns an NSSize containing the maximum width and height from the two given points.
func max(_ lhs: NSSize, _ rhs: NSSize) -> NSSize {
    
    return NSSize(
        width: max(lhs.width, rhs.width),
        height: max(lhs.height, rhs.height)
    )
}

/// Returns a size formed by adding the magnitude of the given edge insets to the given size.  Positive inset distances will result in a smaller size.  This will not return a size with a width or height less than 0.0.
func +(lhs: NSSize, rhs: NSEdgeInsets) -> NSSize {
    
    let size = lhs
    let insets = rhs
    
    return NSSize(
        width: max(size.width - insets.left - insets.right, 0.0),
        height: max(size.height - insets.top - insets.bottom, 0.0)
    )
}

/// Returns a size formed by subtracting the magnitude of the given edge insets to the given size.  Positive inset distances will result in a larger size.
func -(lhs: NSSize, rhs: NSEdgeInsets) -> NSSize {
    
    let size = lhs
    let insets = rhs
    
    return NSSize(
        width: size.width + insets.left + insets.right,
        height: size.height + insets.top + insets.bottom
    )
}
