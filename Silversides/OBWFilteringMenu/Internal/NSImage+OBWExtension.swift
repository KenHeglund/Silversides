/*===========================================================================
 NSImage+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

extension NSImage {
    
    /*==========================================================================*/
    func withLockedFocus(_ handler: () -> Void) {
        self.lockFocus()
        handler()
        self.unlockFocus()
    }
    
    /*==========================================================================*/
    func imageByTrimmingTransparentEdges() -> NSImage? {
        
        let sourceFrame = NSRect(size: self.size)
        
        if self.hitTest(sourceFrame, withDestinationRect: sourceFrame, context: nil, hints: nil, flipped: false) == false {
            return nil
        }
        
        var contentFrame = sourceFrame
        
        // trim bottom
        for bottomOffset in 0 ..< Int(sourceFrame.size.height) {
            
            let testRect = NSRect(
                x: contentFrame.origin.x,
                y: sourceFrame.origin.y + CGFloat(bottomOffset),
                width: contentFrame.size.width,
                height: 1.0
            )
            
            if self.hitTest(testRect, withDestinationRect: sourceFrame, context: nil, hints: nil, flipped: false) {
                break
            }
            
            contentFrame.origin.y = sourceFrame.origin.y + CGFloat(bottomOffset) + 1.0
            contentFrame.size.height = sourceFrame.origin.y + sourceFrame.size.height - contentFrame.origin.y
        }
        
        // trim top
        for topOffset in 1 ..< Int(sourceFrame.size.height) {
            
            let testRect = NSRect(
                x: contentFrame.origin.x,
                y: sourceFrame.origin.y + sourceFrame.size.height - CGFloat(topOffset),
                width: contentFrame.size.width,
                height: 1.0
            )
            
            if self.hitTest(testRect, withDestinationRect: sourceFrame, context: nil, hints: nil, flipped: false) {
                break
            }
            
            contentFrame.size.height = sourceFrame.origin.y + sourceFrame.size.height - CGFloat(topOffset) - contentFrame.origin.y
        }
        
        // trim left
        for leftOffset in 0 ..< Int(sourceFrame.size.width) {
            
            let testRect = NSRect(
                x: sourceFrame.origin.x + CGFloat(leftOffset),
                y: contentFrame.origin.y,
                width: 1.0,
                height: contentFrame.size.height
            )
            
            if self.hitTest(testRect, withDestinationRect: sourceFrame, context: nil, hints: nil, flipped: false) {
                break
            }
            
            contentFrame.origin.x = sourceFrame.origin.x + CGFloat(leftOffset) + 1.0
            contentFrame.size.width = sourceFrame.origin.x + sourceFrame.size.width - contentFrame.origin.x
        }
        
        // trim right
        for rightOffset in 1 ..< Int(sourceFrame.size.width) {
            
            let testRect = NSRect(
                x: sourceFrame.origin.x + sourceFrame.size.width - CGFloat(rightOffset),
                y: contentFrame.origin.y,
                width: 1.0,
                height: contentFrame.size.height
            )
            
            if self.hitTest(testRect, withDestinationRect: sourceFrame, context: nil, hints: nil, flipped: false) {
                break
            }
            
            contentFrame.size.width = sourceFrame.origin.x + sourceFrame.size.width - CGFloat(rightOffset) - contentFrame.origin.x
        }
        
        if NSEqualRects(sourceFrame, contentFrame) {
            return self
        }
        
        
        let trimmedImage = NSImage(size: contentFrame.size)
        trimmedImage.withLockedFocus {
            self.draw(at: .zero, from: contentFrame, operation: .copy, fraction: 1.0)
        }
        
        return trimmedImage
    }
}
