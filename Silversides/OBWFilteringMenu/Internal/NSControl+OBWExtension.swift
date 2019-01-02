/*===========================================================================
 NSControl+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

extension NSControl {
    
    /*==========================================================================*/
    class func controlSizeForFontSize(_ fontPointSize: CGFloat) -> NSControl.ControlSize {
        
        if fontPointSize <= NSFont.systemFontSize(for: .mini) {
            return .mini
        }
        if fontPointSize <= NSFont.systemFontSize(for: .small) {
            return .small
        }
        
        return .regular
    }
}
