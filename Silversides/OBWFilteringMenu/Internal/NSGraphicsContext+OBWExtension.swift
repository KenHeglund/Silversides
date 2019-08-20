/*===========================================================================
 NSGraphicsContext+OBWExtension.swift
 OBWControls
 Copyright (c) 2019 OrderedBytes. All rights reserved.
 ===========================================================================*/

import AppKit

extension NSGraphicsContext {
    
    /// Executes the given handler after saving the current graphics state.  The graphics state is restored before returning.
    static func withSavedGraphicsState( _ handler: () -> Void ) {
        NSGraphicsContext.saveGraphicsState()
        handler()
        NSGraphicsContext.restoreGraphicsState()
    }
}
