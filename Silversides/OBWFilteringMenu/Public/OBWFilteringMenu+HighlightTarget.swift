/*===========================================================================
OBWFilteringMenu+ItemHighlight.swift
OBWControls
Copyright (c) 2019 Ken Heglund. All rights reserved.
===========================================================================*/

import Foundation

public extension OBWFilteringMenu {
	/// Identifies the item to highlight when opening a filtering menu.
	enum HighlightTarget {
		/// Highlight nothing.
		case none
		/// Highlight the given menu item.
		case item
		/// Highlight the item currently under the cursor.
		case underCursor
	}
}
