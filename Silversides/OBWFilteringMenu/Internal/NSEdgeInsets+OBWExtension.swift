/*===========================================================================
NSEdgeInsets+OBWExtension.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

extension NSEdgeInsets {
	/// Initialization with leading and trailing dimensions.
	///
	/// - Parameters:
	///   - top: The inset of the top edge.
	///   - leading: The inset of the leading edge.
	///   - bottom: The inset of the bottom edge.
	///   - trailing: The inset of the trailing edge.
	init(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat) {
		switch NSApp.userInterfaceLayoutDirection {
			case .rightToLeft:
				self.init(top: top, left: trailing, bottom: bottom, right: leading)
				
			case .leftToRight:
				fallthrough
			@unknown default:
				self.init(top: top, left: leading, bottom: bottom, right: trailing)
		}
	}
	
	/// The sum of the left and right inset distances.
	var width: CGFloat {
		self.left + self.right
	}
	
	/// The sum of the top and bottom inset distances.
	var height: CGFloat {
		self.top + self.bottom
	}
	
	/// The leading inset.
	var leading: CGFloat {
		get {
			switch NSApp.userInterfaceLayoutDirection {
				case .rightToLeft:
					return self.right
					
				case .leftToRight:
					fallthrough
				@unknown default:
					return self.left
			}
		}
		set {
			switch NSApp.userInterfaceLayoutDirection {
				case .rightToLeft:
					self.right = newValue
					
				case .leftToRight:
					fallthrough
				@unknown default:
					self.left = newValue
			}
		}
	}
	
	// The trailing inset.
	var trailing: CGFloat {
		get {
			switch NSApp.userInterfaceLayoutDirection {
				case .rightToLeft:
					return self.left
					
				case .leftToRight:
					fallthrough
				@unknown default:
					return self.right
			}
		}
		set {
			switch NSApp.userInterfaceLayoutDirection {
				case .rightToLeft:
					self.left = newValue
					
				case .leftToRight:
					fallthrough
				@unknown default:
					self.right = newValue
			}
		}
	}
	
	/// Returns `true` if all insets are zero.
	var isEmpty: Bool {
		self.top == 0.0 && self.left == 0.0 && self.bottom == 0.0 && self.right == 0.0
	}
}
