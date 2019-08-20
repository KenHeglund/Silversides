/*===========================================================================
 OBWColorFilledView.swift
 OBWControls
 Copyright (c) 2019 OrderedBytes. All rights reserved.
 ===========================================================================*/

import AppKit

/// A view class that draws a color.
class OBWColorFilledView: NSView {
    
    /// The view's color.
    var fillColor: NSColor? = nil
    
    /// Overridden to draw the color.
    override func draw(_ dirtyRect: NSRect) {
        
        guard let fillColor = self.fillColor else {
            return
        }
        
        fillColor.set()
        self.bounds.fill()
    }
    
}
