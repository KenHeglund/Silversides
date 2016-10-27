/*===========================================================================
 OBWPathItem.swift
 Silversides
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

public struct OBWPathItemStyle: OptionSetType {
    
    public init( rawValue: UInt ) {
        self.rawValue = rawValue & 0x7
    }
    
    public var rawValue: UInt
    
    public static let Default       = OBWPathItemStyle( rawValue: 0 )
    public static let Italic        = OBWPathItemStyle( rawValue: 1 << 0 )
    public static let Bold          = OBWPathItemStyle( rawValue: 1 << 1 )
    public static let NoTextShadow  = OBWPathItemStyle( rawValue: 1 << 2 )
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
    
    public init( title: String, image: NSImage?, representedObject: AnyObject?, style: OBWPathItemStyle, textColor: NSColor?, accessible: Bool = true ) {
        
        self.title = title
        self.image = image
        self.representedObject = representedObject
        self.style = style
        self.textColor = textColor
        self.accessible = accessible
    }
}
