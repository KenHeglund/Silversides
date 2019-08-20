/*===========================================================================
 NSWindow+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit

extension NSWindow {
    
    /// Convert the given point from window coordinates to screen coordinates.
    func convertToScreen(_ locationInWindow: NSPoint) -> NSPoint {
        
        let rectInWindow = NSRect(origin: locationInWindow, size: .zero)
        let rectInScreen = self.convertToScreen(rectInWindow)
        return rectInScreen.origin
    }
    
    /// Convert the given point from screen coordinates to window coordinates.
    func convertFromScreen(_ locationInScreen: NSPoint) -> NSPoint {
        
        let rectInScreen = NSRect(origin: locationInScreen, size: .zero)
        let rectInWindow = self.convertFromScreen(rectInScreen)
        return rectInWindow.origin
    }
    
}
