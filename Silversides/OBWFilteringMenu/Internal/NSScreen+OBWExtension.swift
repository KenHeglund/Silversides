/*===========================================================================
 NSScreen+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

extension NSScreen {
    
    class func screenContainingLocation( _ locationInScreen: NSPoint ) -> NSScreen? {
        
        for screen in self.screens {
            
            if NSPointInRect( locationInScreen, screen.frame ) {
                return screen
            }
        }
        
        return nil
    }
}
