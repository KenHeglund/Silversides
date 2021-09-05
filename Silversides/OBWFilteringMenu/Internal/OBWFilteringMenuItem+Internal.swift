/*===========================================================================
OBWFilteringMenuItem+Internal.swift
OBWControls
Copyright (c) 2021 OrderedBytes. All rights reserved.
===========================================================================*/

import AppKit

extension OBWFilteringMenuItem {
	/// The effective control size used by the menu item.
	var controlSize: NSControl.ControlSize {
		NSControl.controlSizeForFontSize(self.font.pointSize)
	}
}
