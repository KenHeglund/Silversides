/*===========================================================================
 NSScreen+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

extension NSScreen {
    
    class func screenContainingLocation( locationInScreen: NSPoint ) -> NSScreen? {
        
        guard let screenList = self.screens() else { return nil }
        
        for screen in screenList {
            
            if NSPointInRect( locationInScreen, screen.frame ) {
                return screen
            }
        }
        
        return nil
    }
}
