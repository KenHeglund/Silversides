/*===========================================================================
 NSSize+OBWExtensions.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/
func max(_ lhs: NSSize, _ rhs: NSSize) -> NSSize {
    
    return NSSize(
        width: max(lhs.width, rhs.width),
        height: max(lhs.height, rhs.height)
    )
}

/*==========================================================================*/
func +(lhs: NSSize, rhs: NSEdgeInsets) -> NSSize {
    
    let size = lhs
    let insets = rhs
    
    return NSSize(
        width: max(size.width - insets.left - insets.right, 0.0),
        height: max(size.height - insets.top - insets.bottom, 0.0)
    )
}

/*==========================================================================*/
func -(lhs: NSSize, rhs: NSEdgeInsets) -> NSSize {
    
    let size = lhs
    let insets = rhs
    
    return NSSize(
        width: size.width + insets.left + insets.right,
        height: size.height + insets.top + insets.bottom
    )
}
