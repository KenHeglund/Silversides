/*===========================================================================
NSRect+OBWExtension.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

/// Returns a rectangle formed by adding the given edge insets to the given
/// rectangle.  Positive insets will result in a smaller rectangle.  This will
/// not return a rectangle with a negative width or height.
///
/// - Parameters:
///   - lhs: The rectangle to add insets to.
///   - rhs: Insets to add to the rectangle.
///
/// - Returns: A rectangle formed by adding insets `rhs` to rectangle `lhs`.
func +(lhs: NSRect, rhs: NSEdgeInsets) -> NSRect {
	var rect = lhs
	let insets = rhs
	
	if rect.size.width > insets.width {
		rect.origin.x += insets.left
		rect.size.width -= insets.width
	}
	else {
		rect.origin.x += floor(rect.size.width * insets.left / insets.width)
		rect.size.width = 0.0
	}
	
	if rect.size.height > insets.height {
		rect.origin.y += insets.bottom
		rect.size.height -= insets.height
	}
	else {
		rect.origin.y += floor(rect.size.height * insets.bottom / insets.height)
		rect.size.height = 0.0
	}
	
	return rect
}

/// Returns a rectangle formed by subtracting the given edge insets from the
/// given rectangle.  Positive insets will result in a larger rectangle.
///
/// - Parameters:
///   - lhs: The rectangle to subtract insets from.
///   - rhs: Insets to subtract from the rectangle.
///
/// - Returns: Returns a rectangle formed by subtracting insets `rhs` from
/// rectangle `lhs`.
func -(lhs: NSRect, rhs: NSEdgeInsets) -> NSRect {
	var rect = lhs
	let insets = rhs
	
	rect.origin.x -= insets.left
	rect.origin.y -= insets.bottom
	rect.size.width += insets.width
	rect.size.height += insets.height
	
	return rect
}


// MARK: -

extension NSRect {
	/// Initialize an `NSRect` with a `.zero` origin and the given size.
	///
	/// - Parameter size: The size of the `NSRect` to initialize.
	init(size: NSSize) {
		self.init(origin: .zero, size: size)
	}
	
	/// Initialize an `NSRect` with a `.zero` origin and the given width and
	/// height.
	///
	/// - Parameters:
	///   - width: The width of the `NSRect` to initialize.
	///   - height: The height of the `NSRect` to initialize.
	init(width: CGFloat, height: CGFloat) {
		self.init(x: 0.0, y: 0.0, width: width, height: height)
	}
	
	/// Initialize an `NSRect` with the given origin, width, and height.
	///
	/// - Parameters:
	///   - origin: The origin of the `NSRect` to initialize.
	///   - width: The width of the `NSRect` to initialize.
	///   - height: The height of the `NSRect` to initialize.
	init(origin: NSPoint, width: CGFloat, height: CGFloat) {
		self.init(x: origin.x, y: origin.y, width: width, height: height)
	}
	
	/// Initialize an `NSRect` with the given `x` location, `y` location, and
	/// size.
	///
	/// - Parameters:
	///   - x: The `x` location of the `NSRect` to initialize.
	///   - y: The `y` location of the `NSRect` to initialize.
	///   - size: The size of the `NSRect` to initialize.
	init(x: CGFloat, y: CGFloat, size: NSSize) {
		self.init(x: x, y: y, width: size.width, height: size.height)
	}
	
	/// The horizontal location of the leading edge.
	var leadingX: CGFloat {
		switch NSApp.userInterfaceLayoutDirection {
			case .rightToLeft:
				return self.maxX
				
			case .leftToRight:
				fallthrough
			@unknown default:
				return self.minX
		}
	}
	
	/// The horizontal location of the trailing edge.
	var trailingX: CGFloat {
		switch NSApp.userInterfaceLayoutDirection {
			case .rightToLeft:
				return self.minX
				
			case .leftToRight:
				fallthrough
			@unknown default:
				return self.maxX
		}
	}
}
