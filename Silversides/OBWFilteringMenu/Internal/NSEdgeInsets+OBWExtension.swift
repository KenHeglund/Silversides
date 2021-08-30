/*===========================================================================
NSEdgeInsets+OBWExtension.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

extension NSEdgeInsets {
	/// The sum of the left and right inset distances.
	var width: CGFloat {
		self.left + self.right
	}
	
	/// The sum of the top and bottom inset distances.
	var height: CGFloat {
		self.top + self.bottom
	}
	
	/// Returns `true` if all insets are zero.
	var isEmpty: Bool {
		self.top == 0.0 && self.left == 0.0 && self.bottom == 0.0 && self.right == 0.0
	}
}
