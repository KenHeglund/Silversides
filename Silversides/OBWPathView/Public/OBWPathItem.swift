/*===========================================================================
 OBWPathItem.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

public struct OBWPathItemStyle: OptionSet {
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue & 0x7
    }
    
    public let rawValue: UInt
    
    public static let `default`     = OBWPathItemStyle(rawValue: 0)
    public static let italic        = OBWPathItemStyle(rawValue: 1 << 0)
    public static let bold          = OBWPathItemStyle(rawValue: 1 << 1)
    public static let noTextShadow  = OBWPathItemStyle(rawValue: 1 << 2)
}

/*==========================================================================*/
// MARK: -

public struct OBWPathItem {
    
    public var title: String
    public var image: NSImage?
    public var representedObject: AnyObject?
    public var style: OBWPathItemStyle
    public var textColor: NSColor?
    public var accessible: Bool
    
    public init(title: String, image: NSImage?, representedObject: AnyObject?, style: OBWPathItemStyle, textColor: NSColor?, accessible: Bool = true) {
        
        self.title = title
        self.image = image
        self.representedObject = representedObject
        self.style = style
        self.textColor = textColor
        self.accessible = accessible
    }
}
