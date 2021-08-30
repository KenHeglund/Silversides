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
	
	/// Identifies all four corners.
	static let all: OBWFilteringMenuCorners = [topLeft, topRight, bottomLeft, bottomRight]
}
