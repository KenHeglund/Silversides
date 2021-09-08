/*===========================================================================
OBWFilteringMenuCorners.swift
OBWControls
Copyright (c) 2019 OrderedBytes. All rights reserved.
===========================================================================*/

import AppKit

/// Identifies the corners of a menu window.
struct OBWFilteringMenuCorners: OptionSet, Hashable {
	init(rawValue: UInt) {
		self.rawValue = rawValue & 0xF
	}
	
	let rawValue: UInt
}

extension OBWFilteringMenuCorners {
	/// Identifies the upper left corner.
	static let topLeft = OBWFilteringMenuCorners(rawValue: 1 << 0)
	/// Identifies the upper right corner.
	static let topRight = OBWFilteringMenuCorners(rawValue: 1 << 1)
	/// Identifies the lower left corner.
	static let bottomLeft = OBWFilteringMenuCorners(rawValue: 1 << 2)
	/// Identifies the lower right corner.
	static let bottomRight = OBWFilteringMenuCorners(rawValue: 1 << 3)
	
	/// Identifies the upper leading corner.
	static var topLeading: OBWFilteringMenuCorners {
		switch NSApp.userInterfaceLayoutDirection {
			case .rightToLeft:
				return OBWFilteringMenuCorners.topRight
				
			case .leftToRight:
				fallthrough
			@unknown default:
				return OBWFilteringMenuCorners.topLeft
		}
	}
	
	/// Identifies the upper trailing corner.
	static var topTrailing: OBWFilteringMenuCorners {
		switch NSApp.userInterfaceLayoutDirection {
			case .rightToLeft:
				return OBWFilteringMenuCorners.topLeft
				
			case .leftToRight:
				fallthrough
			@unknown default:
				return OBWFilteringMenuCorners.topRight
		}
	}
	
	/// Identifies the lower leading corner.
	static var bottomLeading: OBWFilteringMenuCorners {
		switch NSApp.userInterfaceLayoutDirection {
			case .rightToLeft:
				return OBWFilteringMenuCorners.bottomRight
				
			case .leftToRight:
				fallthrough
			@unknown default:
				return OBWFilteringMenuCorners.bottomLeft
		}
	}
	
	/// Identifies the lower trailing corner.
	static var bottomTrailing: OBWFilteringMenuCorners {
		switch NSApp.userInterfaceLayoutDirection {
			case .rightToLeft:
				return OBWFilteringMenuCorners.bottomLeft
				
			case .leftToRight:
				fallthrough
			@unknown default:
				return OBWFilteringMenuCorners.bottomRight
		}
	}
	
	/// Identifies all four corners.
	static let all: OBWFilteringMenuCorners = [topLeft, topRight, bottomLeft, bottomRight]
}
