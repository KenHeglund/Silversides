/*===========================================================================
 NSView+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit

extension NSView {
    
    /// The bounds of the receiver in screen coordinates.  If the view is not on-screen, then this will be equal to the view's bounds.
    var boundsInScreen: NSRect {
        
        guard let window = self.window else {
            return self.bounds
        }
        
        let boundsInWindow = self.convert(self.bounds, to: nil)
        return window.convertToScreen(boundsInWindow)
    }
    
    /// Converts the given point in the view's coordinate system into screen coordinates.
    func convertPointToScreen(_ locationInView: NSPoint) -> NSPoint {
        
        guard let window = self.window else {
            return locationInView
        }
        
        let locationInWindow = self.convert(locationInView, to: nil)
        
        let rectInWindow = NSRect(origin: locationInWindow, size: .zero)
        let rectInScreen = window.convertToScreen(rectInWindow)
        
        return rectInScreen.origin
    }
    
}
