/*===========================================================================
 NSEvent+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

extension NSEvent {
    
    /*==========================================================================*/
    var obw_screen: NSScreen? {
        
        guard let locationInScreen = self.obw_locationInScreen else { return nil }
        
        for screen in NSScreen.screens {
            
            if NSPointInRect( locationInScreen, screen.frame ) {
                return screen
            }
        }
        
        return nil
    }
    
    /*==========================================================================*/
    var obw_locationInScreen: NSPoint? {
        
        guard NSEvent.obw_isLocationPropertyValid( self.type ) else { return nil }
        guard let window = self.window else { return self.locationInWindow }
        
        let rectInWindow = NSRect( origin: self.locationInWindow, size: NSZeroSize )
        let rectInScreen = window.convertToScreen( rectInWindow )
        
        return rectInScreen.origin
    }
    
    /*==========================================================================*/
    func obw_locationInView( _ view: NSView ) -> NSPoint? {
        
        guard NSEvent.obw_isLocationPropertyValid( self.type ) else { return nil }
        guard let viewWindow = view.window else { return nil }
        
        let locationInViewWindow: NSPoint
        
        if let eventWindow = self.window {
            
            if eventWindow == viewWindow {
                
                locationInViewWindow = self.locationInWindow
            }
            else {
                
                let rectInEventWindow = NSRect( origin: self.locationInWindow, size: NSZeroSize )
                let rectInScreen = eventWindow.convertToScreen( rectInEventWindow )
                let rectInViewWindow = viewWindow.convertFromScreen( rectInScreen )
                
                locationInViewWindow = rectInViewWindow.origin;
            }
        }
        else {
            
            let rectInScreen = NSRect( origin: self.locationInWindow, size: NSZeroSize )
            let rectInWindow = viewWindow.convertFromScreen( rectInScreen )
            
            locationInViewWindow = rectInWindow.origin
        }
        
        return view.convert( locationInViewWindow, from: nil )
    }
    
    /*==========================================================================*/
    fileprivate class func obw_isLocationPropertyValid( _ type: NSEvent.EventType ) -> Bool {
        
        let locationValidMask: [NSEvent.EventType] = [
            .leftMouseDown,
            .leftMouseUp,
            .rightMouseDown,
            .rightMouseUp,
            .mouseMoved,
            .leftMouseDragged,
            .rightMouseDragged,
            .scrollWheel,
            .otherMouseDown,
            .otherMouseUp,
            .otherMouseDragged,
            .cursorUpdate
        ]
        
        return locationValidMask.contains( type )
    }
}
