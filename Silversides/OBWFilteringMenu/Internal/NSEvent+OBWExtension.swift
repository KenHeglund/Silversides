/*===========================================================================
 NSEvent+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

extension NSEvent {
    
    /*==========================================================================*/
    var screen: NSScreen? {
        
        guard let locationInScreen = self.locationInScreen else {
            return nil
        }
        
        return NSScreen.screens.first(where: {
            NSPointInRect(locationInScreen, $0.frame)
        })
    }
    
    /*==========================================================================*/
    var locationInScreen: NSPoint? {
        
        guard NSEvent.isLocationPropertyValid(self.type) else {
            return nil
        }
        
        guard let window = self.window else {
            return self.locationInWindow
        }
        
        let rectInWindow = NSRect(origin: self.locationInWindow, size: .zero)
        let rectInScreen = window.convertToScreen(rectInWindow)
        
        return rectInScreen.origin
    }
    
    /*==========================================================================*/
    func locationInView(_ view: NSView) -> NSPoint? {
        
        guard NSEvent.isLocationPropertyValid(self.type) else {
            return nil
        }
        
        guard let viewWindow = view.window else {
            return nil
        }
        
        let locationInViewWindow: NSPoint
        
        if let eventWindow = self.window {
            
            if eventWindow == viewWindow {
                locationInViewWindow = self.locationInWindow
            }
            else {
                
                let rectInEventWindow = NSRect(origin: self.locationInWindow, size: .zero)
                let rectInScreen = eventWindow.convertToScreen(rectInEventWindow)
                let rectInViewWindow = viewWindow.convertFromScreen(rectInScreen)
                
                locationInViewWindow = rectInViewWindow.origin;
            }
        }
        else {
            
            let rectInScreen = NSRect(origin: self.locationInWindow, size: .zero)
            let rectInWindow = viewWindow.convertFromScreen(rectInScreen)
            
            locationInViewWindow = rectInWindow.origin
        }
        
        return view.convert(locationInViewWindow, from: nil)
    }
    
    /*==========================================================================*/
    private class func isLocationPropertyValid(_ type: NSEvent.EventType) -> Bool {
        
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
        
        return locationValidMask.contains(type)
    }
}
