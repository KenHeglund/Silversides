/*===========================================================================
 OBWFilteringMenuCorners.swift
 OBWControls
 Copyright (c) 2019 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Foundation

/// Identifies the corners of a menu window.
struct OBWFilteringMenuCorners: OptionSet, Hashable {
    
    init(rawValue: UInt) {
        self.rawValue = rawValue & 0xF
    }
    
    let rawValue: UInt
    
    static let topLeft      = OBWFilteringMenuCorners(rawValue: 1 << 0)
    static let topRight     = OBWFilteringMenuCorners(rawValue: 1 << 1)
    static let bottomLeft   = OBWFilteringMenuCorners(rawValue: 1 << 2)
    static let bottomRight  = OBWFilteringMenuCorners(rawValue: 1 << 3)
    
    static let all: OBWFilteringMenuCorners = [topLeft, topRight, bottomLeft, bottomRight]
    
}
