/*===========================================================================
 NSScreen+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

extension NSScreen {
    
    /*==========================================================================*/
    class func screenContainingLocation(_ locationInScreen: NSPoint) -> NSScreen? {
        
        return self.screens.first(where: {
            NSPointInRect(locationInScreen, $0.frame)
        })
    }
}
