/*===========================================================================
OBWFilteringMenuArrows.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

/// Generates arrow images that are used at the top and bottom of vertically
/// clipped menus, and in the right side of menu items that have subviews.
class OBWFilteringMenuArrows {
	/// Returns an image containing an arrow pointed up.
	static let upArrow: NSImage = {
		let frame = NSRect(
			width: OBWFilteringMenuArrows.arrowLongSideLength,
			height: OBWFilteringMenuArrows.arrowShortSideLength
		)
		
		let image = NSImage(size: frame.size, flipped: false, drawingHandler: {
			_ in
			
			let flatSideInset = OBWFilteringMenuArrows.longSideInset
			
			let path = NSBezierPath()
			path.move(to: NSPoint(x: frame.width, y: flatSideInset))
			path.line(to: NSPoint(x: frame.width / 2.0, y: frame.height))
			path.line(to: NSPoint(x: 0.0, y: flatSideInset))
			path.close()
			
			NSColor.secondaryLabelColor.set()
			path.fill()
			
			return true
		})
		
		return image
	}()
	
	/// Returns an image containing an arrow pointed down.
	static let downArrow: NSImage = {
		let frame = NSRect(
			width: OBWFilteringMenuArrows.arrowLongSideLength,
			height: OBWFilteringMenuArrows.arrowShortSideLength
		)
		
		let image = NSImage(size: frame.size, flipped: false, drawingHandler: {
			_ in
			
			let flatSideInset = OBWFilteringMenuArrows.longSideInset
			
			let path = NSBezierPath()
			path.move(to: NSPoint(x: 0.0, y: frame.size.height - flatSideInset))
			path.line(to: NSPoint(x: frame.size.width / 2.0, y: 0.0))
			path.line(to: NSPoint(x: frame.size.width, y: frame.size.height - flatSideInset))
			path.close()
			
			NSColor.secondaryLabelColor.set()
			path.fill()
			
			return true
		})
		
		return image
	}()
	
	/// Returns an image containing an arrow pointed in the trailing direction.
	/// Suitable for use in a selected menu item.
	static var selectedTrailingArrow: NSImage {
		switch NSApp.userInterfaceLayoutDirection {
			case .rightToLeft:
				return OBWFilteringMenuArrows.selectedLeftArrow
				
			case .leftToRight:
				fallthrough
			@unknown default:
				return OBWFilteringMenuArrows.selectedRightArrow
		}
	}
	
	/// Returns an image containing an arrow pointed in the trailing direction.
	/// Suitable for use in an unselected menu item.
	static var unselectedTrailingArrow: NSImage {
		switch NSApp.userInterfaceLayoutDirection {
			case .rightToLeft:
				return OBWFilteringMenuArrows.unselectedLeftArrow
				
			case .leftToRight:
				fallthrough
			@unknown default:
				return OBWFilteringMenuArrows.unselectedRightArrow
		}
	}
	
	/// Returns an image containing an arrow pointed to the right, suitable for
	/// use in a selected menu item.
	private static let selectedRightArrow: NSImage = {
		let path = OBWFilteringMenuArrows.rightArrowPath
		let imageSize = NSIntegralRect(path.bounds).size
		
		let image = NSImage(size: imageSize, flipped: false, drawingHandler: {
			_ in
			
			NSColor.selectedMenuItemTextColor.set()
			path.fill()
			
			return true
		})
		
		return image
	}()
	
	/// Returns an image containing an arrow pointed to the right, suitable for
	/// use in an unselected menu item.
	private static let unselectedRightArrow: NSImage = {
		let path = OBWFilteringMenuArrows.rightArrowPath
		let imageSize = NSIntegralRect(path.bounds).size
		
		let image = NSImage(size: imageSize, flipped: false, drawingHandler: {
			_ in
			
			NSColor.labelColor.set()
			path.fill()
			
			return true
		})
		
		return image
	}()
	
	/// Returns an image containing an arrow pointed to the left, suitable for
	/// use in a selected menu item.
	private static let selectedLeftArrow: NSImage = {
		let path = OBWFilteringMenuArrows.leftArrowPath
		let imageSize = NSIntegralRect(path.bounds).size
		
		let image = NSImage(size: imageSize, flipped: false, drawingHandler: {
			_ in
			
			NSColor.selectedMenuItemTextColor.set()
			path.fill()
			
			return true
		})
		
		return image
	}()
	
	/// Returns an image containing an arrow pointed to the left, suitable for
	/// use in an unselected menu item.
	private static let unselectedLeftArrow: NSImage = {
		let path = OBWFilteringMenuArrows.leftArrowPath
		let imageSize = NSIntegralRect(path.bounds).size
		
		let image = NSImage(size: imageSize, flipped: false, drawingHandler: {
			_ in
			
			NSColor.labelColor.set()
			path.fill()
			
			return true
		})
		
		return image
	}()

	
	// MARK: - Private
	
	/// The long side of each triangle is inset by 1.0 point to deliberately
	/// create a partially transparent edge when the image is scaled to the
	/// display size.
	private static let longSideInset: CGFloat = 1.0
	
	/// The length of the “short” side of an arrow’s bounds - the width of
	/// left/right arrows, the height of up/down arrows.
	private static let arrowShortSideLength: CGFloat = 87.0
	
	/// The length of the “long” size of an arrow’s bounds - the height of
	/// left/right arrows, the width of up/down arrows.
	private static let arrowLongSideLength: CGFloat = 100.0
	
	/// Returns a path defining the shape of an arrow pointed to the right.
	private static let rightArrowPath: NSBezierPath = {
		let flatSideInset = OBWFilteringMenuArrows.longSideInset
		
		let frame = NSRect(
			width: OBWFilteringMenuArrows.arrowShortSideLength,
			height: OBWFilteringMenuArrows.arrowLongSideLength
		)
		
		let rightArrowPath = NSBezierPath()
		rightArrowPath.move(to: NSPoint(x: flatSideInset, y: 0.0))
		rightArrowPath.line(to: NSPoint(x: frame.size.width, y: frame.size.height / 2.0))
		rightArrowPath.line(to: NSPoint(x: flatSideInset, y: frame.size.height))
		rightArrowPath.close()
		
		return rightArrowPath
	}()
	
	/// Returns a path defining the shape of an arrow pointed to the left.
	private static let leftArrowPath: NSBezierPath = {
		let flatSideInset = OBWFilteringMenuArrows.longSideInset
		
		let frame = NSRect(
			width: OBWFilteringMenuArrows.arrowShortSideLength,
			height: OBWFilteringMenuArrows.arrowLongSideLength
		)
		
		let leftArrowPath = NSBezierPath()
		leftArrowPath.move(to: NSPoint(x: frame.size.width - flatSideInset, y: 0.0))
		leftArrowPath.line(to: NSPoint(x: 0.0, y: frame.size.height / 2.0))
		leftArrowPath.line(to: NSPoint(x: frame.size.width - flatSideInset, y: frame.size.height))
		leftArrowPath.close()
		
		return leftArrowPath
	}()
}
