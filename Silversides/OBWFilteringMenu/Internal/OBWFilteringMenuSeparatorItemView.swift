/*===========================================================================
OBWFilteringMenuSeparatorItemView.swift
OBWControls
Copyright (c) 2019 OrderedBytes. All rights reserved.
===========================================================================*/

import AppKit

/// A view that displays a menu separator item.
class OBWFilteringMenuSeparatorItemView: OBWFilteringMenuItemView {
	/// Draw the separator.
	override func draw(_ dirtyRect: NSRect) {
		let itemViewBounds = self.bounds
		let drawRect = NSRect(
			x: itemViewBounds.origin.x + 1.0,
			y: floor(itemViewBounds.midY) - 1.0,
			width: itemViewBounds.size.width - 2.0,
			height: 1.0
		)
		
		let knownAppearanceNames: [NSAppearance.Name] = [.darkAqua, .aqua]
		if NSAppearance.current.bestMatch(from: knownAppearanceNames) == .darkAqua {
			NSColor.secondaryLabelColor.withAlphaComponent(0.5).set()
		}
		else {
			NSColor.secondaryLabelColor.withAlphaComponent(0.25).set()
		}
		
		drawRect.fill()
	}
	
	/// Returns the first baseline offset of the separator.
	override var firstBaselineOffsetFromTop: CGFloat {
		return self.bounds.maxY - (floor(self.bounds.midY) - 1.0)
	}
	
	/// Returns the preferred size for a separator item.
	override var preferredSize: NSSize {
		return NSSize(width: 10.0, height: 12.0)
	}
}
