/*===========================================================================
 NSEvent+OBWExtension.swift
 Silversides
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

extension NSEvent {
    
    /*==========================================================================*/
    var obw_screen: NSScreen? {
        
        guard let screenList = NSScreen.screens() else { return nil }
        guard let locationInScreen = self.obw_locationInScreen else { return nil }
        
        for screen in screenList {
            
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
        let rectInScreen = window.convertRectToScreen( rectInWindow )
        
        return rectInScreen.origin
    }
    
    /*==========================================================================*/
    func obw_locationInView( view: NSView ) -> NSPoint? {
        
        guard NSEvent.obw_isLocationPropertyValid( self.type ) else { return nil }
        guard let viewWindow = view.window else { return nil }
        
        let locationInViewWindow: NSPoint
        
        if let eventWindow = self.window {
            
            if eventWindow == viewWindow {
                
                locationInViewWindow = self.locationInWindow
            }
            else {
                
                let rectInEventWindow = NSRect( origin: self.locationInWindow, size: NSZeroSize )
                let rectInScreen = eventWindow.convertRectToScreen( rectInEventWindow )
                let rectInViewWindow = viewWindow.convertRectFromScreen( rectInScreen )
                
                locationInViewWindow = rectInViewWindow.origin;
            }
        }
        else {
            
            let rectInScreen = NSRect( origin: self.locationInWindow, size: NSZeroSize )
            let rectInWindow = viewWindow.convertRectFromScreen( rectInScreen )
            
            locationInViewWindow = rectInWindow.origin
        }
        
        return view.convertPoint( locationInViewWindow, fromView: nil )
    }
    
    /*==========================================================================*/
    private class func obw_isLocationPropertyValid( type: NSEventType ) -> Bool {
        
        let locationValidMask: NSEventMask = [
            .LeftMouseDown,
            .LeftMouseUp,
            .RightMouseDown,
            .RightMouseUp,
            .MouseMoved,
            .LeftMouseDragged,
            .RightMouseDragged,
            .ScrollWheel,
            .OtherMouseDown,
            .OtherMouseUp,
            .OtherMouseDragged,
            .CursorUpdate
        ]
        
        return locationValidMask.contains( NSEventMaskFromType( type ) )
    }
}
