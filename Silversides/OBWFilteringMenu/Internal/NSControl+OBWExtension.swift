/*===========================================================================
 NSControl+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

extension NSControl {
    
    /*==========================================================================*/
    class func obw_controlSizeForFontSize( _ fontPointSize: CGFloat ) -> NSControlSize {
        
        if fontPointSize <= NSFont.systemFontSize( for: .mini ) {
            return .mini
        }
        if fontPointSize <= NSFont.systemFontSize( for: .small ) {
            return .small
        }
        
        return .regular
    }
    
}
