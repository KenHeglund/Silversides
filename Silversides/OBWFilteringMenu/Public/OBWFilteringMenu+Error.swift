/*===========================================================================
OBWFilteringMenu+Error.swift
OBWControls
Copyright (c) 2019 Ken Heglund. All rights reserved.
===========================================================================*/

import Foundation

/// Errors that `OBWFilteringMenu` may throw.
public enum OBWFilteringMenuError: Error {
	/// An attempt to add an alternate menu item failed.
	case invalidAlternateItem(message: String)
}
