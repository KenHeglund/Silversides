/*===========================================================================
 NSView+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

extension NSView {
    
    /*==========================================================================*/
    var obw_boundsLowerLeftPoint: NSPoint {
        
        let viewBounds = self.bounds
        var lowerLeftCorner = viewBounds.origin
        
        if self.flipped {
            lowerLeftCorner.y += viewBounds.size.height
        }
        
        return lowerLeftCorner
    }
    
    /*==========================================================================*/
    var obw_boundsInScreen: NSRect {
        
        let boundsInWindow = self.convertRect( self.bounds, toView: nil )
        guard let window = self.window else { return self.bounds }
        return window.convertRectToScreen( boundsInWindow )
    }
    
    /*==========================================================================*/
    func obw_convertPointToScreen( locationInView: NSPoint ) -> NSPoint {
        
        guard let window = self.window else { return locationInView }
        let locationInWindow = self.convertPoint( locationInView, toView: nil )
        
        let rectInWindow = NSRect( origin: locationInWindow, size: NSZeroSize )
        let rectInScreen = window.convertRectToScreen( rectInWindow )
        
        return rectInScreen.origin
    }
}
