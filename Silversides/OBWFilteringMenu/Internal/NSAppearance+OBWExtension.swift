/*===========================================================================
 NSAppearance+OBWExtension.swift
 OBWControls
 Copyright (c) 2018 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit

extension NSAppearance {
    
    /// Executes the given handler while the given appearance is current.
    static func withAppearance(_ appearance: NSAppearance, handler: () -> Void) {
        NSAppearance.current = appearance
        handler()
        NSAppearance.current = nil
    }
}
