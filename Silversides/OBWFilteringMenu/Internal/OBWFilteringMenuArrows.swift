/*===========================================================================
 OBWFilteringMenuArrows.swift
 Silversides
 Copyright (c) 2016, 2021 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit

/// Generates arrow images that are used at the top and bottom of vertically
/// clipped menus, and in the right side of menu items that have subviews.
class OBWFilteringMenuArrows {
	/// Defines variations of arrows provided by this class.
	enum Direction {
		/// An arrow pointed toward the up direction.
		case up
		/// An arrow pointed toward the down direction.
		case down
		/// An arrow pointed toward the leading direction.
		case leading
		/// An arrow pointed toward the trailing direction.
		case trailing
	}
	
	/// Returns an image of an arrow pointing in the given direction.
	///
	/// - Parameter direction: The direction of the arrow to return the image of.
	///
	/// - Returns: An image of an arrow pointing in the direction indicated by
	/// `direction`.
	static func image(for direction: OBWFilteringMenuArrows.Direction) -> NSImage {
		if let existingImage = OBWFilteringMenuArrows.configuredImages[direction] {
			return existingImage
		}
		
		let symbolName = OBWFilteringMenuArrows.symbolName(for: direction)
		guard let baseImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else {
			assertionFailure("Failed to obtain a system symbol for \(direction)")
			return NSImage()
		}
		
		let symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 16.0, weight: .bold)
		guard let arrowImage = baseImage.withSymbolConfiguration(symbolConfiguration) else {
			assertionFailure("Failed to obtain a system symbol for \(direction) with \(symbolConfiguration)")
			return NSImage()
		}
		
		OBWFilteringMenuArrows.configuredImages[direction] = arrowImage
		
		return arrowImage
	}
	
	
	// MARK: - Private
	
	/// Returns the name of the system symbol for an arrow in the given
	/// direction.
	///
	/// - Parameter direction: The direction of the arrow to return the name of.
	///
	/// - Returns: The name of the system symbol containing an arrow pointing in
	/// the direction indicated by `direction`.
	private static func symbolName(for direction: OBWFilteringMenuArrows.Direction) -> String {
		switch direction {
			case .up:
				return "chevron.up"
				
			case .down:
				return "chevron.down"
				
			case .leading:
				switch NSApp.userInterfaceLayoutDirection {
					case .rightToLeft:
						return "chevron.right"
						
					case .leftToRight:
						fallthrough
					@unknown default:
						return "chevron.left"
				}
				
			case .trailing:
				switch NSApp.userInterfaceLayoutDirection {
					case .rightToLeft:
						return "chevron.left"
						
					case .leftToRight:
						fallthrough
					@unknown default:
						return "chevron.right"
				}
		}
	}
	
	/// A cached of system symbols that have been configured for use as arrow
	/// images.
	private static var configuredImages: [OBWFilteringMenuArrows.Direction: NSImage] = [:]
}
