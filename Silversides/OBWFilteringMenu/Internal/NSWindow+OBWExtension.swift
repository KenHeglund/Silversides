/*===========================================================================
 NSWindow+OBWExtension.swift
 Silversides
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

extension NSWindow {
    
    /*==========================================================================*/
    func obw_convertToScreen( locationInWindow: NSPoint ) -> NSPoint {
        
        let rectInWindow = NSRect( origin: locationInWindow, size: NSZeroSize )
        let rectInScreen = self.convertRectToScreen( rectInWindow )
        return rectInScreen.origin
    }
    
    /*==========================================================================*/
    func obw_convertFromScreen( locationInScreen: NSPoint ) -> NSPoint {
        
        let rectInScreen = NSRect( origin: locationInScreen, size: NSZeroSize )
        let rectInWindow = self.convertRectFromScreen( rectInScreen )
        return rectInWindow.origin
    }
}
