/*===========================================================================
 NSWindow+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

extension NSWindow {
    
    /*==========================================================================*/
    func convertToScreen(_ locationInWindow: NSPoint) -> NSPoint {
        
        let rectInWindow = NSRect(origin: locationInWindow, size: .zero)
        let rectInScreen = self.convertToScreen(rectInWindow)
        return rectInScreen.origin
    }
    
    /*==========================================================================*/
    func convertFromScreen(_ locationInScreen: NSPoint) -> NSPoint {
        
        let rectInScreen = NSRect(origin: locationInScreen, size: .zero)
        let rectInWindow = self.convertFromScreen(rectInScreen)
        return rectInWindow.origin
    }
}
