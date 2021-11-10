/*===========================================================================
 OBWFilteringMenuItemScrollView.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit
import OSLog

/// A private error that is used to terminate a loop early.
private enum OBWFilteringMenuItemScrollViewError: Error {
	case terminateEarly
}

/// A view that acts as a parent to all of the menu-specific content in a menu window.  The up arrow, the down arrow, and the scrollable menu item area.
class OBWFilteringMenuItemScrollView: NSView {
	/// Initialization
	/// - Parameters:
	///   - menu: The menu containing the items to be displayed in the scroll
	///   view.
	///   - minimumWidth: The minimum allowable menu width.
	init(menu: OBWFilteringMenu, minimumWidth: CGFloat) {
		self.filteringMenu = menu
		self.minimumItemWidth = minimumWidth
		
		let itemParentView = OBWColorFilledView(frame: .zero)
#if DEBUG_MENU_TINTING
		itemParentView.fillColor = NSColor.black.withAlphaComponent(0.1)
#endif
		itemParentView.autoresizesSubviews = true
		self.itemParentView = itemParentView
		
		let itemClipView = NSClipView()
		self.itemClipView = itemClipView
		
		let upArrowView = NSImageView()
		self.upArrowView = upArrowView
		
		let downArrowView = NSImageView()
		self.downArrowView = downArrowView
		
		super.init(frame: .zero)
		
		self.menuContentsDidChange()
		
		let itemParentViewFrame = itemParentView.frame
		
		itemClipView.frame = itemParentViewFrame
		
		let upArrowFrame = NSRect(
			x: itemParentViewFrame.origin.x + floor((itemParentViewFrame.size.width - OBWFilteringMenuItemScrollView.arrowSize.width) / 2.0),
			y: itemParentViewFrame.maxY - OBWFilteringMenuItemScrollView.arrowSize.height,
			size: OBWFilteringMenuItemScrollView.arrowSize
		)
		
		upArrowView.frame = upArrowFrame
		upArrowView.imageScaling = .scaleProportionallyDown
		upArrowView.imageAlignment = .alignCenter
		upArrowView.autoresizingMask = [.minYMargin, .minXMargin, .maxXMargin]
		upArrowView.image = OBWFilteringMenuArrows.image(for: .up)
		upArrowView.contentTintColor = .labelColor
		upArrowView.isHidden = true
		
		let downArrowFrame = NSRect(
			x: itemParentViewFrame.origin.x + floor((itemParentViewFrame.size.width - OBWFilteringMenuItemScrollView.arrowSize.width) / 2.0),
			y: 0.0,
			size: OBWFilteringMenuItemScrollView.arrowSize
		)
		
		downArrowView.frame = downArrowFrame
		downArrowView.imageScaling = .scaleProportionallyDown
		downArrowView.imageAlignment = .alignCenter
		downArrowView.autoresizingMask = [.maxYMargin, .minXMargin, .maxXMargin]
		downArrowView.image = OBWFilteringMenuArrows.image(for: .down)
		downArrowView.contentTintColor = .labelColor
		downArrowView.isHidden = true
		
		itemClipView.drawsBackground = false
		itemClipView.autoresizingMask = [.width, .height]
		itemClipView.addSubview(itemParentView)
		
		self.setFrameSize(itemParentViewFrame.size)
		self.addSubview(itemClipView)
		self.addSubview(upArrowView)
		self.addSubview(downArrowView)
		
		self.autoresizingMask = [.width, .height]
		self.autoresizesSubviews = true
	}
	
	// Required initializer.
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	
	// MARK: - NSView overrides
	
	/// Resize subviews.  Adjusts the bounds of the menu item area to keep the
	/// content at the same location on the screen.
	///
	/// - Parameter oldSize: The previous size of the view.
	override func resizeSubviews(withOldSize oldSize: NSSize) {
		super.resizeSubviews(withOldSize: oldSize)
		
		let changeInHeight = self.frame.height - oldSize.height
		let itemClipView = self.itemClipView
		
		let newClipBoundsOrigin = NSPoint(
			x: 0.0,
			y: itemClipView.bounds.minY - changeInHeight
		)
		
		itemClipView.setBoundsOrigin(newClipBoundsOrigin)
	}
	
	
	// MARK: -  NSAccessibility Implementation
	
	/// Returns the accessibile children of the receiver.
	///
	/// - Returns: The accessible children of the menu view.
	override func accessibilityChildren() -> [Any]? {
		guard let parentViewChildren = self.itemParentView.accessibilityChildren() else {
			return nil
		}
		
		return NSAccessibility.unignoredChildren(from: parentViewChildren)
	}
	
	
	// MARK: - OBWFilteringMenuItemScrollView Implementation
	
	/// The minimum height at the top of the menu is the minimum height of the
	/// first item.
	var minimumHeightAtTop: CGFloat {
		guard let itemView = allItemViews.first else {
			return 0.0
		}
		
		return self.minimumHeightForView(itemView)
	}
	
	/// The minimum height at the bottom of the menu is the minimum height of
	/// the last item.
	var minimumHeightAtBottom: CGFloat {
		guard let itemView = allItemViews.last else {
			return 0.0
		}
		
		return self.minimumHeightForView(itemView)
	}
	
	/// Returns the size of the area occupied by all of the menu items.
	var totalMenuItemSize: NSSize {
		return self.itemParentView.frame.size
	}
	
	/// Returns the bounds of the visible menu items.
	var menuItemBounds: NSRect {
		return self.convert(self.bounds, to: self.itemClipView)
	}
	
	/// Rebuilds the subviews based on the current menu contents.
	func menuContentsDidChange() {
		self.buildItemViews()
		self.repositionItemViews()
	}
	
	/// Returns the menu item at the given point.
	///
	/// - parameter locationInView: The point in the receiver’s coordinate
	/// system.
	///
	/// - returns: A menu item, if any.
	func menuItemAtLocation(_ locationInView: NSPoint) -> OBWFilteringMenuItem? {
		let itemClipView = self.itemClipView
		let locationInClipView = itemClipView.convert(locationInView, from: self)
		
		guard NSPointInRect(locationInClipView, itemClipView.bounds) else {
			return nil
		}
		
		let itemParentView = self.itemParentView
		let locationInParentView = itemParentView.convert(locationInView, from: self)
		
		for subview in itemParentView.subviews {
			
			guard
				let itemView = subview as? OBWFilteringMenuItemView,
				itemView.isHidden == false,
				NSPointInRect(locationInParentView, itemView.frame)
			else {
				continue
			}
			
			let menuItem = itemView.menuItem
			
			if menuItem.enabled && menuItem.canHighlight {
				return menuItem
			}
			else {
				return nil
			}
		}
		
		return nil
	}
	
	/// Returns the menu part at the given location.
	///
	/// - parameter locationInView: The point in the receiver’s coordinate
	/// system.
	///
	/// - returns: A menu part.
	func menuPartAtLocation(_ locationInView: NSPoint) -> OBWFilteringMenu.MenuPart {
		let itemClipFrame = self.itemClipView.frame
		
		if locationInView.x < itemClipFrame.origin.x || locationInView.x >= itemClipFrame.maxX {
			return .none
		}
		else if locationInView.y < itemClipFrame.origin.y {
			return self.downArrowView.isHidden ? .none : .down
		}
		else if locationInView.y >= itemClipFrame.maxY {
			return self.upArrowView.isHidden ? .none : .up
		}
		
		return .item
	}
	
	/// Returns the item view for the given menu item.
	///
	/// - parameter menuItem: The menu item.
	///
	/// - returns: An item view.  Returns `nil` if the menu item is a separator
	/// or is not in the menu.
	func viewForMenuItem(_ menuItem: OBWFilteringMenuItem) -> OBWFilteringMenuItemView? {
		guard menuItem.isSeparatorItem == false else {
			return nil
		}
		
		return self.allItemViews.first(where: { $0.menuItem === menuItem })
	}
	
	/// Returns the item view for the menu item following the given menu item.
	///
	/// - parameter menuItem: The menu item.
	///
	/// - returns: An item view, if a menu item follows the given menu item.
	func nextViewAfterItem(_ menuItem: OBWFilteringMenuItem?) -> OBWFilteringMenuItemView? {
		return self.nextViewAfterItem(menuItem, inViews: self.allItemViews)
	}
	
	/// Returns the item view for the menu item preceeding the given menu item.
	///
	/// - parameter menuItem: The menu item.
	///
	/// - returns: An item view, if a menu item preceeds the given menu item.
	func previousViewBeforeItem(_ menuItem: OBWFilteringMenuItem?) -> OBWFilteringMenuItemView? {
		return self.nextViewAfterItem(menuItem, inViews: self.allItemViews.reversed())
	}
	
	/// Scrolls the given menu item into view.
	///
	/// - parameter menuItem: The menu item to become visible.
	func scrollItemToVisible(_ menuItem: OBWFilteringMenuItem) {
		guard let itemView = self.viewForMenuItem(menuItem) else {
			return
		}
		
		self.scrollItemViewIntoFrame(itemView)
	}
	
	/// Scroll menu items downward with the given acceleration multiplier.
	///
	/// - parameter acceleration: A factor by which to multiply the scroll
	/// distance.
	///
	/// - Returns: `true` if the the scroll view has reached the upper limit,
	/// `false` if not.
	func scrollItemsDownWithAcceleration(_ acceleration: Double) -> Bool {
		let itemClipView = self.itemClipView
		let itemClipViewBounds = itemClipView.bounds
		
		let itemParentView = self.itemParentView
		let itemParentFrame = itemParentView.frame
		let averageItemHeight = itemParentFrame.height / CGFloat(itemParentView.subviews.count)
		let scrollDelta = floor(averageItemHeight * CGFloat(acceleration))
		
		let hitPoint = NSPoint(
			x: itemClipViewBounds.origin.x,
			y: min(itemClipViewBounds.maxY + scrollDelta, itemParentFrame.height)
		)
		
		guard let itemView = self.menuItemViewAtLocation(hitPoint) ?? self.nextViewAfterItem(nil) else {
			return self.upArrowView.isHidden
		}
		
		self.scrollItemViewIntoFrame(itemView)
		
		return self.upArrowView.isHidden
	}
	
	/// Scroll menu items upward with the given acceleration multiplier.
	///
	/// - parameter acceleration: A factor by which to multiply the scroll
	/// distance.
	///
	/// - Returns: `true` if the the scroll view has reached the lower limit,
	/// `false` if not.
	func scrollItemsUpWithAcceleration(_ acceleration: Double) -> Bool {
		let itemClipView = self.itemClipView
		let itemClipViewBounds = itemClipView.bounds
		
		let itemParentView = self.itemParentView
		let averageItemHeight = itemParentView.frame.size.height / CGFloat(itemParentView.subviews.count)
		let scrollDelta = floor(averageItemHeight * CGFloat(acceleration))
		
		let hitPoint = NSPoint(
			x: itemClipViewBounds.origin.x,
			y: max(itemClipViewBounds.origin.y - scrollDelta, 0.0)
		)
		
		guard let itemView = self.menuItemViewAtLocation(hitPoint) ?? self.previousViewBeforeItem(nil) else {
			return self.downArrowView.isHidden
		}
		
		self.scrollItemViewIntoFrame(itemView)
		
		return self.downArrowView.isHidden
	}
	
	/// Scroll menu items downward by the height of the currently visible menu
	/// items.
	///
	/// - returns: The topmost newly visible menu item.
	func scrollItemsDownOnePage() -> OBWFilteringMenuItemView? {
		let itemClipView = self.itemClipView
		let itemClipViewBounds = itemClipView.bounds
		
		guard let topItemView = self.firstFullyVisibleMenuItemView() else {
			return nil
		}
		
		let hitPoint = NSPoint(
			x: itemClipViewBounds.minX,
			y: topItemView.frame.maxY + (itemClipViewBounds.height - 1.0)
		)
		
		guard let itemView = self.menuItemViewAtLocation(hitPoint) ?? self.nextViewAfterItem(nil) else {
			return nil
		}
		
		self.scrollItemViewIntoFrame(itemView)
		
		return itemView
	}
	
	/// Scroll menu items upward by the height of the currently visible menu
	/// items.
	///
	/// - returns: The bottommost newly visible menu item.
	func scrollItemsUpOnePage() -> OBWFilteringMenuItemView? {
		let itemClipView = self.itemClipView
		let itemClipViewBounds = itemClipView.bounds
		
		guard let bottomItemView = self.lastFullyVisibleMenuItemView() else {
			return nil
		}
		
		let hitPoint = NSPoint(
			x: itemClipViewBounds.minX,
			y: bottomItemView.frame.minY - (itemClipViewBounds.size.height - 1.0)
		)
		
		guard let itemView = self.menuItemViewAtLocation(hitPoint) ?? self.previousViewBeforeItem(nil) else {
			return nil
		}
		
		self.scrollItemViewIntoFrame(itemView)
		
		return itemView
	}
	
	/// Set the vertical location of the menu item bounds origin.
	///
	/// - Parameter boundsOriginY: The new vertical location of the menu item
	/// bounds origin.
	func setMenuItemBoundsOriginY(_ boundsOriginY: CGFloat) {
		let arrowAreaHeight = OBWFilteringMenuItemScrollView.arrowEdgeMargin + OBWFilteringMenuItemScrollView.arrowContentMargin + OBWFilteringMenuItemScrollView.arrowSize.height
		
		let itemParentView = self.itemParentView
		let itemParentFrame = itemParentView.frame
		
		let scrollViewBounds = self.bounds
		var itemClipFrame = scrollViewBounds
		
		var itemClipBounds = NSRect(
			x: 0.0,
			y: boundsOriginY,
			width: itemClipFrame.size.width,
			height: itemClipFrame.size.height
		)
		
		if boundsOriginY > 0.0 {
			
			itemClipFrame.origin.y += arrowAreaHeight
			itemClipFrame.size.height -= arrowAreaHeight
			
			itemClipBounds.origin.y += arrowAreaHeight
			itemClipBounds.size.height -= arrowAreaHeight
			
			self.downArrowView.isHidden = false
		}
		else {
			self.downArrowView.isHidden = true
		}
		
		if itemParentFrame.size.height > itemClipBounds.maxY {
			
			itemClipFrame.size.height -= arrowAreaHeight
			itemClipBounds.size.height -= arrowAreaHeight
			
			self.upArrowView.isHidden = false
		}
		else {
			self.upArrowView.isHidden = true
		}
		
		let itemClipView = self.itemClipView
		itemClipView.frame = itemClipFrame
		itemClipView.scroll(to: itemClipBounds.origin)
	}
	
	/// Applies the given filter results to the current menu items.
	///
	/// - parameter filterResults: The filter result array.
	///
	/// - returns: Returns `true` if the overall size of the menu changed.
	func applyFilterResults(_ filterResults: [OBWFilteringMenuItemFilterStatus]?, stop: (() -> Bool)? = nil) -> Bool {
		let itemViewArray = self.primaryItemViews
		
		os_signpost(.begin, log: .filteringMenuLogger, name: "Apply.ApplyToItems", signpostID: .filteringSignpostID, "")
		if let filterResults = filterResults, filterResults.count == itemViewArray.count {
			try? zip(filterResults, itemViewArray).lazy.forEach({ (status, itemView) in
				guard stop?() != true else {
					throw OBWFilteringMenuItemScrollViewError.terminateEarly
				}
				assert(status.menuItem === itemView.menuItem)
				
				itemView.applyFilterStatus(status)
			})
		}
		else {
			itemViewArray.forEach({ $0.applyFilterStatus(nil) })
		}
		os_signpost(.end, log: .filteringMenuLogger, name: "Apply.ApplyToItems", signpostID: .filteringSignpostID, "")
		
		guard stop?() != true else {
			return false
		}
		
		os_signpost(.begin, log: .filteringMenuLogger, name: "Apply.RepositionItems", signpostID: .filteringSignpostID, "")
		let result = self.repositionItemViews(modifierFlags: self.currentModifierFlags, stop: stop)
		os_signpost(.end, log: .filteringMenuLogger, name: "Apply.RepositionItems", signpostID: .filteringSignpostID, "")
		return result
	}
	
	/// Applies keyboard modifier flags to the menu.
	///
	/// - parameter modifierFlags: The modifier flags to apply.
	///
	/// - returns: Returns `true` if the overall size of the menu changed.
	func applyModifierFlags(_ modifierFlags: NSEvent.ModifierFlags) -> Bool {
		if modifierFlags == self.currentModifierFlags {
			return false
		}
		
		self.currentModifierFlags = modifierFlags
		
		return self.repositionItemViews(modifierFlags: modifierFlags, stop: { false })
	}
	
	
	// MARK: - Private
	
	/// Margin between an arrow and the edge of the scroll view.
	private static let arrowEdgeMargin: CGFloat = 0.0
	
	/// Margin between an arrow and the menu item content.
	private static let arrowContentMargin: CGFloat = 5.0
	
	/// Size of the arrow images.
	private static let arrowSize = NSSize(width: 10.0, height: 9.0)
	
	/// The menu being displayed.
	unowned private let filteringMenu: OBWFilteringMenu
	
	/// Returns the current window.
	private var filteringMenuWindow: OBWFilteringMenuWindow? {
		return self.window as? OBWFilteringMenuWindow
	}
	
	/// The view that is the immediate superview of menu item views.
	unowned private let itemParentView: NSView
	
	/// The clip view that is the superview of the item parent view.
	unowned private let itemClipView: NSClipView
	
	/// A view to display the up arrow at the top of the menu when truncated.
	unowned private let upArrowView: NSImageView
	
	/// A view to display the down arrow at the bottom of the menu when
	/// truncated.
	unowned private let downArrowView: NSImageView
	
	/// The menu item views that are shown when no filter is applied to the
	/// menu.
	private var primaryItemViews: [OBWFilteringMenuItemView] = []
	
	/// The modifier flags that are currently applied to the menu.
	private var currentModifierFlags: NSEvent.ModifierFlags = []
	
	/// The minimum width of the menu.
	private let minimumItemWidth: CGFloat
	
	/// Build item views for the current menu’s items.
	private func buildItemViews() {
		let itemParentView = self.itemParentView
		itemParentView.subviews.forEach({ $0.removeFromSuperview() })
		
		var primaryItemViews: [OBWFilteringMenuItemView] = []
		
		for menuItem in self.filteringMenu.itemArray {
			
			let itemView = OBWFilteringMenuItemView.makeViewWithMenuItem(menuItem)
			primaryItemViews.append(itemView)
			itemParentView.addSubview(itemView)
			
			for (_,alternateItemView) in itemView.alternateViews {
				itemParentView.addSubview(alternateItemView)
			}
		}
		
		self.primaryItemViews = primaryItemViews
	}
	
	/// Positions the menu item views that are visible after applying the given
	/// keyboard modifier flags.
	///
	/// - parameter modifierFlags: The keyboard modifier flags.
	///
	/// - returns: Returns `true` if the overall size of the menu changed.
	@discardableResult
	private func repositionItemViews(modifierFlags: NSEvent.ModifierFlags = [], stop: (() -> Bool)? = nil) -> Bool {
		let itemParentView = self.itemParentView
		let itemParentBounds = itemParentView.bounds
		
		var itemViewOrigin = NSPoint(x: self.bounds.origin.x, y: 0.0)
		var parentViewWidth = max(self.minimumItemWidth, itemParentBounds.size.width)
		
		for primaryItemView in self.primaryItemViews.reversed() {
			guard stop?() != true else {
				return false
			}
			
			let primaryMenuItem = primaryItemView.menuItem
			let primaryFilterStatus = primaryItemView.filterStatus
			
			let primaryViewVisible: Bool
			if primaryFilterStatus?.isMatching == false {
				primaryViewVisible = false
			}
			else if primaryMenuItem.visibleItemForModifierFlags(modifierFlags) !== primaryMenuItem {
				primaryViewVisible = false
			}
			else {
				primaryViewVisible = true
			}
			
			let primaryItemPreferredSize = primaryItemView.preferredSize
			
			let itemViewFrame = NSRect(
				origin: itemViewOrigin,
				width: itemParentBounds.size.width,
				height: primaryItemPreferredSize.height
			)
			
			if primaryItemView.frame != itemViewFrame {
				
				primaryItemView.frame = itemViewFrame
				
				if primaryViewVisible {
					NSAccessibility.post(element: primaryItemView, notification: NSAccessibility.Notification.moved)
				}
			}
			
			if primaryViewVisible && primaryItemView.isHidden {
				primaryItemView.isHidden = false
				NSAccessibility.post(element: primaryItemView, notification: NSAccessibility.Notification.created)
			}
			else if primaryViewVisible == false && primaryItemView.isHidden == false {
				primaryItemView.isHidden = true
				NSAccessibility.post(element: primaryItemView, notification: NSAccessibility.Notification.uiElementDestroyed)
			}
			
			var visibleItemView: OBWFilteringMenuItemView? = (primaryViewVisible ? primaryItemView : nil)
			
			for (_, alternateItemView) in primaryItemView.alternateViews {
				
				let alternateMenuItem = alternateItemView.menuItem
				let alternateFilterStatus = alternateItemView.filterStatus
				
				let alternateViewVisible: Bool
				if alternateFilterStatus?.isMatching == false {
					alternateViewVisible = false
				}
				else if alternateMenuItem.visibleItemForModifierFlags(modifierFlags) !== alternateMenuItem {
					alternateViewVisible = false
				}
				else {
					alternateViewVisible = true
				}
				
				let alternateItemViewFrame = NSRect(
					origin: itemViewOrigin,
					width: itemParentBounds.size.width,
					height: alternateItemView.preferredSize.height
				)
				
				if alternateItemView.frame != alternateItemViewFrame {
					alternateItemView.frame = alternateItemViewFrame
					
					if alternateViewVisible {
						NSAccessibility.post(element: alternateItemView, notification: NSAccessibility.Notification.moved)
					}
				}
				
				if alternateViewVisible && alternateItemView.isHidden {
					alternateItemView.isHidden = false
					NSAccessibility.post(element: alternateItemView, notification: NSAccessibility.Notification.created)
				}
				else if alternateViewVisible == false && alternateItemView.isHidden == false {
					alternateItemView.isHidden = true
					NSAccessibility.post(element: alternateItemView, notification: NSAccessibility.Notification.uiElementDestroyed)
				}
				
				if alternateViewVisible {
					visibleItemView = alternateItemView
				}
			}
			
			if let visibleItemView = visibleItemView {
				itemViewOrigin.y += visibleItemView.frame.size.height
				
				let itemSize: NSSize
				if visibleItemView == primaryItemView {
					itemSize = primaryItemPreferredSize
				}
				else {
					itemSize = visibleItemView.preferredSize
				}
				
				parentViewWidth = max(parentViewWidth, itemSize.width)
			}
		}
		
		let totalMenuItemSizeChanged = (itemParentView.frame.size.height != itemViewOrigin.y)
		
		if totalMenuItemSizeChanged {
			let parentViewSize = NSSize(width: parentViewWidth, height: itemViewOrigin.y)
			itemParentView.setFrameSize(parentViewSize)
		}
		
		guard let highlightedItem = self.filteringMenu.highlightedItem else {
			return totalMenuItemSizeChanged
		}
		
		if self.viewForMenuItem(highlightedItem)?.isHidden == true {
			self.filteringMenu.highlightedItem = nil
		}
		
		return totalMenuItemSizeChanged
	}
	
	/// Returns the currently visible menu item views.
	private var allItemViews: [OBWFilteringMenuItemView] {
		return self.itemParentView.subviews as? [OBWFilteringMenuItemView] ?? []
	}
	
	/// Returns the minimum height necessary to display the given item view.
	private func minimumHeightForView(_ itemView: NSView) -> CGFloat {
		let minimumHeight = itemView.frame.height
		
		if self.allItemViews.count == 1 {
			return minimumHeight
		}
		
		return minimumHeight + OBWFilteringMenuItemScrollView.arrowEdgeMargin + OBWFilteringMenuItemScrollView.arrowContentMargin + OBWFilteringMenuItemScrollView.arrowSize.height
	}
	
	/// Returns the item view following the given menu item from the given array
	/// of views.
	///
	/// - Parameters:
	///   - menuItem: The menu item.
	///   - itemViewArray: The array of views to search.
	///
	/// - Returns: The item view following the given menu item, if any.
	private func nextViewAfterItem(_ menuItem: OBWFilteringMenuItem?, inViews itemViewArray: [OBWFilteringMenuItemView]) -> OBWFilteringMenuItemView? {
		
		let accessibilityActive = self.filteringMenuWindow?.accessibilityActive ?? false
		
		var currentMenuItemView: OBWFilteringMenuItemView? = nil
		var useNextAvailable = (menuItem == nil)
		
		for itemView in itemViewArray {
			
			let item = itemView.menuItem
			
			if item === menuItem {
				currentMenuItemView = itemView
				useNextAvailable = true
				continue
			}
			
			if
				useNextAvailable,
				itemView.isHidden == false,
				item.enabled || accessibilityActive,
				item.canHighlight
			{
				return itemView
			}
		}
		
		return currentMenuItemView
	}
	
	/// Returns the menu item view at the given location.
	///
	/// - parameter locationInItemClipView: The location in item clip view
	/// coordinates.
	private func menuItemViewAtLocation(_ locationInItemClipView: NSPoint) -> OBWFilteringMenuItemView? {
		return self.allItemViews.first(where: {
			$0.isHidden == false && NSPointInRect(locationInItemClipView, $0.frame)
		})
	}
	
	/// Returns the topmost item view that is not clipped.
	private func firstFullyVisibleMenuItemView() -> OBWFilteringMenuItemView? {
		let itemClipViewBounds = self.itemClipView.bounds
		
		let topLeft = NSPoint(
			x: itemClipViewBounds.minX,
			y: itemClipViewBounds.maxY
		)
		
		guard let topMenuView = self.menuItemViewAtLocation(topLeft) else {
			return nil
		}
		
		if topMenuView.frame.maxY <= itemClipViewBounds.maxY {
			return topMenuView
		}
		
		let testPoint = NSPoint(
			x: itemClipViewBounds.minX,
			y: itemClipViewBounds.maxY - topMenuView.frame.size.height
		)
		
		return self.menuItemViewAtLocation(testPoint)
	}
	
	/// Returns the bottommost item view that is not clipped.
	private func lastFullyVisibleMenuItemView() -> OBWFilteringMenuItemView? {
		let itemClipViewBounds = self.itemClipView.bounds
		
		guard let bottomMenuView = self.menuItemViewAtLocation(itemClipViewBounds.origin) else {
			return nil
		}
		
		if bottomMenuView.frame.minY >= itemClipViewBounds.minY {
			return bottomMenuView
		}
		
		let testPoint = NSPoint(
			x: itemClipViewBounds.minX,
			y: itemClipViewBounds.minY + bottomMenuView.frame.size.height
		)
		
		return self.menuItemViewAtLocation(testPoint)
	}
	
	/// Scrolls the item clip view the minimum amount to make the given item
	/// view visible.
	private func scrollItemViewIntoFrame(_ itemView: OBWFilteringMenuItemView) {
		let itemViewFrame = itemView.frame
		let scrollViewBounds = self.bounds
		
		var itemTopLeftInScrollView = NSZeroPoint
		
		let itemClipView = self.itemClipView
		let itemClipBounds = itemClipView.bounds
		let itemClipFrame = itemClipView.frame
		
		let itemParentFrame = self.itemParentView.frame
		
		if itemViewFrame.origin.y < itemClipBounds.origin.y {
			
			// scroll items up
			
			let minimumY = itemClipFrame.origin.y + itemViewFrame.size.height
			let maximumY = scrollViewBounds.origin.y + itemViewFrame.maxY
			
			itemTopLeftInScrollView.y = max(scrollViewBounds.origin.y, minimumY)
			itemTopLeftInScrollView.y = min(itemTopLeftInScrollView.y, maximumY)
			itemTopLeftInScrollView.x = scrollViewBounds.origin.x
		}
		else if itemViewFrame.maxY > itemClipBounds.maxY {
			
			// scroll items down
			
			let maximumY = itemClipFrame.maxY
			let minimumY = scrollViewBounds.maxY - (itemParentFrame.size.height - itemViewFrame.maxY)
			
			itemTopLeftInScrollView.y = min(scrollViewBounds.maxY, maximumY)
			itemTopLeftInScrollView.y = max(itemTopLeftInScrollView.y, minimumY)
			itemTopLeftInScrollView.x = scrollViewBounds.origin.x
		}
		else {
			return
		}
		
		let locationInScreen = self.convertPointToScreen(itemTopLeftInScrollView)
		
		let menuLocation = NSPoint(
			x: itemViewFrame.minX,
			y: itemViewFrame.maxY
		)
		
		self.filteringMenuWindow?.displayMenuLocation(menuLocation, atScreenLocation: locationInScreen, allowWindowToGrowUpward: false, resetScrollTracking: false)
	}
}
