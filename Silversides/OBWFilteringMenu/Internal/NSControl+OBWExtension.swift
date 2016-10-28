/*===========================================================================
 NSControl+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

extension NSControl {
    
    /*==========================================================================*/
    class func obw_controlSizeForFontSize( fontPointSize: CGFloat ) -> NSControlSize {
        
        if fontPointSize <= NSFont.systemFontSizeForControlSize( .Mini ) {
            return .Mini
        }
        if fontPointSize <= NSFont.systemFontSizeForControlSize( .Small ) {
            return .Small
        }
        
        return .Regular
    }
    
}
