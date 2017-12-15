/*===========================================================================
 NSWindow+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

extension NSWindow {
    
    /*==========================================================================*/
    func obw_convertToScreen( _ locationInWindow: NSPoint ) -> NSPoint {
        
        let rectInWindow = NSRect( origin: locationInWindow, size: NSZeroSize )
        let rectInScreen = self.convertToScreen( rectInWindow )
        return rectInScreen.origin
    }
    
    /*==========================================================================*/
    func obw_convertFromScreen( _ locationInScreen: NSPoint ) -> NSPoint {
        
        let rectInScreen = NSRect( origin: locationInScreen, size: NSZeroSize )
        let rectInWindow = self.convertFromScreen( rectInScreen )
        return rectInWindow.origin
    }
}
