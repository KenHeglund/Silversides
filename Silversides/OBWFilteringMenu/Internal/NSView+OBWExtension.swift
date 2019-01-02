/*===========================================================================
 NSView+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

extension NSView {
    
    /*==========================================================================*/
    var boundsLowerLeftPoint: NSPoint {
        
        let viewBounds = self.bounds
        var lowerLeftCorner = viewBounds.origin
        
        if self.isFlipped {
            lowerLeftCorner.y += viewBounds.size.height
        }
        
        return lowerLeftCorner
    }
    
    /*==========================================================================*/
    var boundsInScreen: NSRect {
        
        let boundsInWindow = self.convert(self.bounds, to: nil)
        
        if let window = self.window {
            return window.convertToScreen(boundsInWindow)
        }
        else {
            return self.bounds
        }
    }
    
    /*==========================================================================*/
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
