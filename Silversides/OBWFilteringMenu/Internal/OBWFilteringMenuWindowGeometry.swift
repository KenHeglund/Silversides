/*===========================================================================
OBWFilteringMenuWindowGeometry.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

/// A class that calculates window geometries.
class OBWFilteringMenuWindowGeometry {
	/// Initialization.
	///
	/// - Parameter window: The menu window for which geometry will be
	/// calculated.
	init(window: OBWFilteringMenuWindow) {
		let screenFrame = window.screen?.frame ?? NSZeroRect
		
		let menuView = window.menuView
		
		self.window = window
		self.frame = window.frame
		self.initialBounds = menuView.menuItemBounds
		
		let totalMenuItemSize = menuView.totalMenuItemSize
		self.totalMenuItemSize = totalMenuItemSize
		
		let windowScreenLimits = screenFrame + OBWFilteringMenuWindowGeometry.screenMargins
		let interiorScreenLimits = windowScreenLimits + OBWFilteringMenuWindow.interiorMargins
		let menuItemScreenLimits = interiorScreenLimits + menuView.outerMenuMargins
		
		let finalSize = NSSize(
			width: min(totalMenuItemSize.width, menuItemScreenLimits.size.width),
			height: min(totalMenuItemSize.height, menuItemScreenLimits.size.height)
		)
		
		self.finalBounds = NSRect(size: finalSize)
		
		self.constrainGeometryToScreen(allowWindowToGrowUpward: true)
	}
	
	/// Updates the geometry to display the given menu location at a particular
	/// screen location.
	///
	/// - Parameters:
	///   - locationInMenu: Defines a location within the menu.
	///   - locationInScreen: Defines a location on the screen to which
	///   `locationInMenu` should be aligned.
	///   - allowWindowToGrowUpward: If `true`, the top of the window may be
	///   adjusted upward to allow the entire menu to be visible on the screen.
	///   If `false`, the menu window may be clipped at the bottom.
	///
	/// - Returns: `true` if a geometry was calculated for the window, `false`
	/// if not.
	@discardableResult
	func updateGeometryToDisplayMenuLocation(_ locationInMenu: NSPoint, atScreenLocation locationInScreen: NSPoint, allowWindowToGrowUpward: Bool = true) -> Bool {
		
		guard NSScreen.screenContainingLocation(locationInScreen) != nil else {
			return false
		}
		
		let menuView = self.window.menuView
		let totalMenuItemSize = menuView.totalMenuItemSize
		self.totalMenuItemSize = totalMenuItemSize
		
		let menuFrameInScreen = NSRect(
			x: locationInScreen.x - locationInMenu.x,
			y: locationInScreen.y - locationInMenu.y,
			size: totalMenuItemSize
		)
		
		let interiorFrameInScreen = menuFrameInScreen - menuView.outerMenuMargins
		
		var windowFrameInScreen = interiorFrameInScreen - OBWFilteringMenuWindow.interiorMargins
		windowFrameInScreen.size = max(windowFrameInScreen.size, OBWFilteringMenuWindow.minimumFrameSize)
		
		self.frame = windowFrameInScreen
		
		let menuItemBounds = NSRect(size: totalMenuItemSize)
		self.initialBounds = menuItemBounds
		self.finalBounds = menuItemBounds
		
		self.constrainGeometryToScreen(allowWindowToGrowUpward: allowWindowToGrowUpward)
		
		return true
	}
	
	/// Updates the geometry to display the given menu location adjacent to a
	/// given area with a preferred alignment.
	///
	/// - Parameters:
	///   - locationInMenu: Defines a location within the menu.
	///   - areaInScreen: An area that the menu item should appear adjacent to.
	///   - preferredAlignment: The preferred side where the menu item should be
	///   located.
	///
	/// - Returns: The alignment of the window relative to `areaInScreen`.
	@discardableResult
	func updateGeometryToDisplayMenuLocation(_ locationInMenu: NSPoint, adjacentToScreenArea areaInScreen: NSRect, preferredAlignment: OBWFilteringMenu.SubmenuAlignment) -> OBWFilteringMenu.SubmenuAlignment {
		
		let rightAlignmentLocation = NSPoint(
			x: areaInScreen.maxX + 1.0,
			y: (areaInScreen.height < self.frame.height ? areaInScreen.maxY : areaInScreen.midY)
		)
		
		let rightGeometry = OBWFilteringMenuWindowGeometry(window: window, displayingMenuLocation: locationInMenu, atScreenLocation: rightAlignmentLocation)
		
		let leftAlignmentLocation = NSPoint(
			x: areaInScreen.minX - self.frame.width - 1.0,
			y: rightAlignmentLocation.y
		)
		
		let leftGeometry = OBWFilteringMenuWindowGeometry(window: window, displayingMenuLocation: locationInMenu, atScreenLocation: leftAlignmentLocation)
		
		let leadingGeometry: OBWFilteringMenuWindowGeometry?
		let trailingGeometry: OBWFilteringMenuWindowGeometry?
		switch NSApp.userInterfaceLayoutDirection {
			case .rightToLeft:
				leadingGeometry = rightGeometry
				trailingGeometry = leftGeometry
				
			case .leftToRight:
				fallthrough
			@unknown default:
				leadingGeometry = leftGeometry
				trailingGeometry = rightGeometry
		}
		
		let finalGeometry: OBWFilteringMenuWindowGeometry
		let finalAlignment: OBWFilteringMenu.SubmenuAlignment
		
		switch (leadingGeometry, trailingGeometry, preferredAlignment) {
			
			case (nil, nil, _):
				return preferredAlignment
				
			case (nil, let geometry?, _):
				finalGeometry = geometry
				finalAlignment = .trailing
				
			case (let geometry?, nil, _):
				finalGeometry = geometry
				finalAlignment = .leading
				
			case (let leadingGeometry?, _, .leading):
				finalGeometry = leadingGeometry
				finalAlignment = .leading
				
			case (_, let trailingGeometry?, .trailing):
				finalGeometry = trailingGeometry
				finalAlignment = .trailing
		}
		
		self.frame = finalGeometry.frame
		self.totalMenuItemSize = finalGeometry.totalMenuItemSize
		self.initialBounds = finalGeometry.initialBounds
		self.finalBounds = finalGeometry.finalBounds
		
		return finalAlignment
	}
	
	/// Update the geometry to accommodate a resized menu.
	///
	/// - Parameter constrainToAnchor: Indicates whether the window frame must
	/// remain adjacent to its anchor.
	func updateGeometryWithResizedMenu(constrainToAnchor: Bool) {
		let menuView = self.window.menuView
		let totalMenuItemSize = menuView.totalMenuItemSize
		self.totalMenuItemSize = totalMenuItemSize
		
		var windowFrameInScreen = self.frame
		var interiorFrameInScreen = windowFrameInScreen + OBWFilteringMenuWindow.interiorMargins
		var menuFrameInScreen = interiorFrameInScreen + menuView.outerMenuMargins
		
		menuFrameInScreen.origin.y = menuFrameInScreen.maxY - totalMenuItemSize.height
		menuFrameInScreen.size.height = totalMenuItemSize.height
		menuFrameInScreen.size.width = max(menuFrameInScreen.size.width, totalMenuItemSize.width)
		
		interiorFrameInScreen = menuFrameInScreen - menuView.outerMenuMargins
		
		if constrainToAnchor, let screenAnchor = self.window.screenAnchor {
			
			interiorFrameInScreen = OBWFilteringMenuWindowGeometry.constrainFrame(interiorFrameInScreen, toAnchorRect: screenAnchor)
			
			if totalMenuItemSize.height == 0.0 {
				interiorFrameInScreen.origin.y = screenAnchor.maxY - interiorFrameInScreen.height
			}
		}
		
		windowFrameInScreen = interiorFrameInScreen - OBWFilteringMenuWindow.interiorMargins
		windowFrameInScreen.size = max(windowFrameInScreen.size, OBWFilteringMenuWindow.minimumFrameSize)
		self.frame = windowFrameInScreen
		
		self.initialBounds = NSRect(size: totalMenuItemSize)
		self.finalBounds = NSRect(size: totalMenuItemSize)
		
		self.constrainGeometryToScreen(allowWindowToGrowUpward: constrainToAnchor == false)
	}
	
	/// Updates the window geometry to display the given area of the menu.  This
	/// is called when a menu’s content scrolls.
	///
	/// - Parameter requestedBounds: The preferred visible bounds.
	///
	/// - Returns: Returns `true` if the geometry changes, `false` if not.
	@discardableResult
	func updateGeometryToDisplayMenuItemBounds(_ requestedBounds: NSRect) -> Bool {
		let window = self.window
		
		guard window.screen != nil else {
			return false
		}
		
		let menuView = window.menuView
		
		var initialBounds = self.initialBounds
		
		var windowFrameInScreen = self.frame
		var interiorFrameInScreen = windowFrameInScreen + OBWFilteringMenuWindow.interiorMargins
		var menuFrameInScreen = interiorFrameInScreen + menuView.outerMenuMargins
		
		if menuFrameInScreen.height == requestedBounds.height {
			// The menu size will not change (it is likely at the maximum allowable height).  Just update the bounds origin.
			initialBounds.origin.y = requestedBounds.origin.y
			self.initialBounds = initialBounds
			return true
		}
		
		menuFrameInScreen.origin.y -= (requestedBounds.height - menuFrameInScreen.height)
		menuFrameInScreen.size.height = requestedBounds.height
		
		interiorFrameInScreen = menuFrameInScreen - menuView.outerMenuMargins
		windowFrameInScreen = interiorFrameInScreen - OBWFilteringMenuWindow.interiorMargins
		windowFrameInScreen.size = max(windowFrameInScreen.size, OBWFilteringMenuWindow.minimumFrameSize)
		self.frame = windowFrameInScreen
		
		self.initialBounds = requestedBounds
		self.finalBounds = NSRect(size: menuView.totalMenuItemSize)
		
		self.constrainGeometryToScreen(allowWindowToGrowUpward: true)
		
		return true
	}
	
	
	// MARK: - Private
	
	/// The menu window that the geometry will be applied to.
	unowned private let window: OBWFilteringMenuWindow
	
	/// The current menu window frame rect (i.e. its location in screen
	/// coordinates)
	var frame: NSRect
	
	/// The maximum size of all of the menu’s items.
	var totalMenuItemSize: NSSize
	
	/// The initial bounds rect of the menu items.
	var initialBounds: NSRect
	
	/// The maximum possible bounds rect of the menu items.
	var finalBounds: NSRect
	
	/// The minimum distances from the edge of a menu window to the edge of its
	/// screen.
	static let screenMargins = NSEdgeInsets(top: 6.0, left: 6.0, bottom: 6.0, right: 6.0)
	
	/// Conditionally initializes an instance given a menu window and a menu
	/// location that should be displayed at a given screen location.  Returns
	/// `nil` if the menu location cannot be displayed at the screen location.
	///
	/// - Parameters:
	///   - window: The menu window.
	///   - locationInMenu: Defines a location within the menu.
	///   - locationInScreen: Defines a location on the screen to which
	///   `locationInMenu` should be aligned.
	private convenience init?(window: OBWFilteringMenuWindow, displayingMenuLocation locationInMenu: NSPoint, atScreenLocation locationInScreen: NSPoint) {
		
		self.init(window: window)
		
		guard self.updateGeometryToDisplayMenuLocation(locationInMenu, atScreenLocation: locationInScreen) else {
			return nil
		}
		
		guard self.frame.minX == locationInScreen.x else {
			return nil
		}
	}
	
	/// Constrains the geometry to the menu’s screen.
	///
	/// - Parameter allowWindowToGrowUpward: If `true`, the window frame may
	/// move upward to avoid clipping at the bottom.
	private func constrainGeometryToScreen(allowWindowToGrowUpward: Bool) {
		guard let screen = self.window.screen else {
			return
		}
		
		let menuView = window.menuView
		
		var windowFrame = self.frame
		let screenLimits = screen.frame + OBWFilteringMenuWindowGeometry.screenMargins
		
		if windowFrame.width >= screenLimits.width {
			windowFrame.origin.x = screenLimits.minX
			windowFrame.size.width = screenLimits.width
		}
		else if windowFrame.origin.x < screenLimits.minX {
			windowFrame.origin.x = screenLimits.minX
		}
		else if windowFrame.maxX > screenLimits.maxX {
			windowFrame.origin.x = screenLimits.maxX - windowFrame.width
		}
		
		let outerMenuMargins = menuView.outerMenuMargins
		let interiorMargins = OBWFilteringMenuWindow.interiorMargins
		
		let minimumWindowHeightAtBottomOfScreen = min(menuView.minimumHeightAtTop + interiorMargins.height + outerMenuMargins.height, screenLimits.height)
		let minimumWindowHeightAtTopOfScreen = min(menuView.minimumHeightAtBottom + interiorMargins.height + outerMenuMargins.height, screenLimits.height)
		
		if windowFrame.origin.y > screenLimits.maxY - minimumWindowHeightAtTopOfScreen {
			windowFrame.origin.y = screenLimits.maxY - minimumWindowHeightAtTopOfScreen
		}
		if windowFrame.maxY < screenLimits.minY + minimumWindowHeightAtBottomOfScreen {
			windowFrame.origin.y = screenLimits.minY + minimumWindowHeightAtBottomOfScreen - windowFrame.height
		}
		
		if windowFrame.minY < screenLimits.minY, allowWindowToGrowUpward {
			
			let distanceFreeAtTopOfScreen = screenLimits.maxY - windowFrame.maxY
			
			if distanceFreeAtTopOfScreen > 0.0 {
				windowFrame.origin.y += min(screenLimits.origin.y - windowFrame.origin.y, distanceFreeAtTopOfScreen)
			}
		}
		
		let distanceToTrimFromBottomOfMenu: CGFloat
		if windowFrame.minY < screenLimits.minY {
			
			distanceToTrimFromBottomOfMenu = screenLimits.minY - windowFrame.minY
			windowFrame.size.height -= distanceToTrimFromBottomOfMenu
			windowFrame.origin.y = screenLimits.minY
		}
		else {
			distanceToTrimFromBottomOfMenu = 0.0
		}
		
		let distanceToTrimFromTopOfMenu: CGFloat
		if windowFrame.maxY > screenLimits.maxY {
			
			distanceToTrimFromTopOfMenu = windowFrame.maxY - screenLimits.maxY
			windowFrame.size.height -= distanceToTrimFromTopOfMenu
		}
		else {
			distanceToTrimFromTopOfMenu = 0.0
		}
		
		self.frame = windowFrame
		
		if distanceToTrimFromBottomOfMenu > 0.0 || distanceToTrimFromTopOfMenu > 0.0 {
			
			var initialBounds = self.initialBounds
			initialBounds.origin.y += distanceToTrimFromBottomOfMenu
			initialBounds.origin.y = max(initialBounds.minY, 0.0)
			initialBounds.size.height -= (distanceToTrimFromBottomOfMenu + distanceToTrimFromTopOfMenu)
			self.initialBounds = initialBounds
		}
		
		let interiorScreenLimits = screenLimits + interiorMargins
		let menuScreenLimits = interiorScreenLimits + outerMenuMargins
		
		var finalBounds = self.finalBounds
		finalBounds.size.width = min(finalBounds.width, menuScreenLimits.width)
		finalBounds.size.height = min(finalBounds.height, menuScreenLimits.height)
		self.finalBounds = finalBounds
	}
	
	/// Vertically constrains a given frame to an anchor rect such that its top
	/// is never lower than the anchor’s top, and its bottom is never higher
	/// than the anchor’s bottom (unless it is smaller vertically than the
	/// anchor’s height).
	///
	/// - Parameters:
	///   - frame: The frame to be constrained.
	///   - anchor: The rect that constrains the coordinates of `frame`.
	///
	/// - Returns: `frame` constrained to the vertical location of `anchor`.
	private class func constrainFrame(_ frame: NSRect, toAnchorRect anchor: NSRect) -> NSRect {
		if frame.minY <= anchor.minY, frame.maxY >= anchor.maxY {
			return frame
		}
		
		var constrainedFrame = frame
		
		if constrainedFrame.minY > anchor.minY {
			constrainedFrame.origin.y = anchor.minY
		}
		
		if constrainedFrame.maxY < anchor.maxY {
			constrainedFrame.origin.y = anchor.maxY - constrainedFrame.size.height
		}
		
		return constrainedFrame
	}
}
