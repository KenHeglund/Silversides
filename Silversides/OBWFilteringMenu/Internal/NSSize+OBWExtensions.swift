/*===========================================================================
 NSSize+OBWExtensions.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/
func max( _ firstSize: NSSize, _ secondSize: NSSize ) -> NSSize {
    
    return NSSize(
        width: max( firstSize.width, secondSize.width ),
        height: max( firstSize.height, secondSize.height )
    )
}

/*==========================================================================*/
func +( lhs: NSSize, rhs: EdgeInsets ) -> NSSize {
    
    let size = lhs
    let insets = rhs
    
    return NSSize(
        width: max( size.width - insets.left - insets.right, 0.0 ),
        height: max( size.height - insets.top - insets.bottom, 0.0 )
    )
}

/*==========================================================================*/
func -( lhs: NSSize, rhs: EdgeInsets ) -> NSSize {
    
    let size = lhs
    let insets = rhs
    
    return NSSize(
        width: size.width + insets.left + insets.right,
        height: size.height + insets.top + insets.bottom
    )
}
