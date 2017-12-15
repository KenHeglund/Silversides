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
        
        if self.isFlipped {
            lowerLeftCorner.y += viewBounds.size.height
        }
        
        return lowerLeftCorner
    }
    
    /*==========================================================================*/
    var obw_boundsInScreen: NSRect {
        
        let boundsInWindow = self.convert( self.bounds, to: nil )
        guard let window = self.window else { return self.bounds }
        return window.convertToScreen( boundsInWindow )
    }
    
    /*==========================================================================*/
    func obw_convertPointToScreen( _ locationInView: NSPoint ) -> NSPoint {
        
        guard let window = self.window else { return locationInView }
        let locationInWindow = self.convert( locationInView, to: nil )
        
        let rectInWindow = NSRect( origin: locationInWindow, size: NSZeroSize )
        let rectInScreen = window.convertToScreen( rectInWindow )
        
        return rectInScreen.origin
    }
}
