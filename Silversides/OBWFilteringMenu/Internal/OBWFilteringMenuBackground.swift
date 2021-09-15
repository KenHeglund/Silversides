/*===========================================================================
OBWFilteringMenuBackground.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

/// The background view of a menu window.  Its mask defines the outer shape of
/// the window.
class OBWFilteringMenuBackground: NSVisualEffectView {
	/// The preferred initializer.
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		
		self.autoresizingMask = [.width, .height]
		self.autoresizesSubviews = true
		
		self.material = .windowBackground
		self.state = .active
		
		self.updateMaskImage()
	}
	
	// Required initializer.
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	
	// MARK: - OBWFilteringMenuBackground Interface
	
	/// Identifies the corner of the view that have a rounded appearance.
	var roundedCorners = OBWFilteringMenuCorners.all {
		didSet {
			self.updateMaskImage()
		}
	}
	
	
	// MARK: - Private
	
	/// The radius of corners that are rounded.
	static let roundedCornerRadius: CGFloat = 6.0
	
	/// The radius of corners that are not rounded.
	static let squareCornerRadius: CGFloat = 0.0
	
	/// A cache of images containing various combinations of rounded corners.
	private static var maskImageCache: [OBWFilteringMenuCorners: NSImage] = [:]
	
	/// Update the current mask image.
	private func updateMaskImage() {
		if let existingImage = OBWFilteringMenuBackground.maskImageCache[self.roundedCorners] {
			self.maskImage = existingImage
		}
		else {
			self.maskImage = OBWFilteringMenuBackground.makeMaskImage(rounding: self.roundedCorners)
			OBWFilteringMenuBackground.maskImageCache[self.roundedCorners] = self.maskImage
		}
	}
	
	/// Constructs a resizeable image with the given corners rounded.
	///
	/// - Parameter corners: Indicates which corners are rounded and which are
	/// square.
	///
	/// - Returns: An image suitable for use as a window mask.
	private static func makeMaskImage(rounding corners: OBWFilteringMenuCorners) -> NSImage {
		let roundedCornerRadius = OBWFilteringMenuBackground.roundedCornerRadius
		let squareCornerRadius = OBWFilteringMenuBackground.squareCornerRadius
		
		let topLeftRadius = corners.contains(.topLeft) ? roundedCornerRadius : squareCornerRadius
		let bottomLeftRadius = corners.contains(.bottomLeft) ? roundedCornerRadius : squareCornerRadius
		let bottomRightRadius = corners.contains(.bottomRight) ? roundedCornerRadius : squareCornerRadius
		let topRightRadius = corners.contains(.topRight) ? roundedCornerRadius : squareCornerRadius
		
		let bounds = NSRect(
			width: roundedCornerRadius * 3.0,
			height: roundedCornerRadius * 3.0
		)
		
		let topLeftPoint = NSPoint(x: bounds.origin.x + topLeftRadius, y: bounds.maxY - topLeftRadius)
		let bottomLeftPoint = NSPoint(x: bounds.origin.x + bottomLeftRadius, y: bounds.origin.y + bottomLeftRadius)
		let bottomRightPoint = NSPoint(x: bounds.maxX - bottomRightRadius, y: bounds.origin.y + bottomRightRadius)
		let topRightPoint = NSPoint(x: bounds.maxX - topRightRadius, y: bounds.maxY - topRightRadius)
		
		let path = NSBezierPath()
		path.appendArc(withCenter: bottomLeftPoint, radius: bottomLeftRadius, startAngle: -180.0, endAngle: -90.0)
		path.appendArc(withCenter: bottomRightPoint, radius: bottomRightRadius, startAngle: -90.0, endAngle: 0.0)
		path.appendArc(withCenter: topRightPoint, radius: topRightRadius, startAngle: 0.0, endAngle: 90.0)
		path.appendArc(withCenter: topLeftPoint, radius: topLeftRadius, startAngle: 90.0, endAngle: 180.0)
		path.close()
		
		let maskImage = NSImage(size: bounds.size)
		maskImage.withLockedFocus {
			path.fill()
		}
		
		maskImage.resizingMode = .stretch
		maskImage.capInsets = NSEdgeInsets(distance: roundedCornerRadius + 1.0)
		
		return maskImage
	}
}
