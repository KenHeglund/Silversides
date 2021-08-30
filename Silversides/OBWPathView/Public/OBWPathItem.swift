/*===========================================================================
OBWPathItem.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

/// An `OptionSet` that defines various visual traits that a Path Item’s title
/// may use.
public struct OBWPathItemStyle: OptionSet, RawRepresentable {
	/// Initialization
	public init(rawValue: UInt) {
		self.rawValue = rawValue & 0x7
	}
	
	public let rawValue: UInt
	
	/// The default appearance, no options.
	public static let `default`: OBWPathItemStyle = []
	/// The title is drawn with an italic font.
	public static let italic = OBWPathItemStyle(rawValue: 1 << 0)
	/// The title is drawn with a bold font.
	public static let bold = OBWPathItemStyle(rawValue: 1 << 1)
	/// The title is not drawn with a shadow.
	public static let noTextShadow = OBWPathItemStyle(rawValue: 1 << 2)
}


// MARK: -

/// A struct that defines an item in a Path View.
public struct OBWPathItem {
	/// The title of the Path Item.
	public var title: String
	
	/// An optional icon image for the Path Item.
	public var image: NSImage?
	
	/// An optional arbitrary object associated with the Path Item.
	public var representedObject: AnyObject?
	
	/// An option set defining the visual appearance of the title of the Path
	/// Item.
	public var style: OBWPathItemStyle
	
	/// An optional custom color for the title of the Path Item.
	public var textColor: NSColor?
	
	/// Indicates whether the Path Item should be an accessible element.
	public var accessible: Bool
	
	/// Public memberwise initializer.
	public init(title: String, image: NSImage?, representedObject: AnyObject?, style: OBWPathItemStyle, textColor: NSColor?, accessible: Bool = true) {
		
		self.title = title
		self.image = image
		self.representedObject = representedObject
		self.style = style
		self.textColor = textColor
		self.accessible = accessible
	}
}
