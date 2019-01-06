/*===========================================================================
 NSAppearance+OBWExtension.swift
 OBWControls
 Copyright (c) 2018 OrderedBytes. All rights reserved.
 ===========================================================================*/

import AppKit

/*==========================================================================*/

extension NSAppearance {
    
    /*==========================================================================*/
    static func withAppearance(_ appearance: NSAppearance, handler: () -> Void) {
        
        NSAppearance.current = appearance
        handler()
        NSAppearance.current = nil
    }
}
