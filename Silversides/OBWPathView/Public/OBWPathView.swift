/*===========================================================================
OBWPathView.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

public class OBWPathView: NSView {
	/// Initialization.
	///
	/// - Parameter frameRect: The frame of the view.
	public override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		self.commonInitialization()
	}
	
	/// Initialization.
	///
	/// - Parameter coder: A coder to decode the view from.
	public required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.commonInitialization()
	}
	
	/// Additional common initialization.
	private func commonInitialization() {
		let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect]
		let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
		self.addTrackingArea(trackingArea)
		
		self.wantsLayer = true
		
		if let layer = self.layer {
			layer.backgroundColor = NSColor.textBackgroundColor.cgColor
			layer.borderColor = NSColor.tertiaryLabelColor.cgColor
			layer.borderWidth = 1.0
		}
		
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self, selector: #selector(OBWPathView.windowBecameOrResignedMain(_:)), name: NSWindow.didBecomeMainNotification, object: self.window)
		notificationCenter.addObserver(self, selector: #selector(OBWPathView.windowBecameOrResignedMain(_:)), name: NSWindow.didResignMainNotification, object: self.window)
	}
	
	/// Deinitialize.
	deinit {
		try? self.removeItemsFromIndex(0)
		NotificationCenter.default.removeObserver(self)
	}
	
	/// Localizable strings
	enum Localizable: CaseLocalizable {
		/// PathView accessibility role description format.
		case roleDescriptionFormat
		/// Default accessibility description.
		case emptyPathDescription
	}
	
	
	// MARK: - NSResponder overrides
	
	/// The cursor entered the Path View.
	///
	/// - Parameter theEvent: The current event.
	override public func mouseEntered(with theEvent: NSEvent) {
		self.mouseMoved(with: theEvent)
	}
	
	/// The cursor departed the Path View.
	///
	/// - Parameter theEvent: The current event.
	override public func mouseExited(with theEvent: NSEvent) {
		guard self.pathItemUpdateDepth == 0 else {
			return
		}
		
		var updateItemWidths = false
		
		for itemView in self.itemViews {
			
			if itemView.preferredWidthRequired {
				itemView.preferredWidthRequired = false
				updateItemWidths = true
			}
		}
		
		if updateItemWidths {
			self.updateCurrentItemViewWidths()
			self.adjustItemViewFrames(withAnimation: true)
		}
	}
	
	/// The cursor moved within the Path View.
	///
	/// - Parameter theEvent: The current event.
	override public func mouseMoved(with theEvent: NSEvent) {
		guard self.pathItemUpdateDepth == 0 else {
			return
		}
		
		let locationInView = self.convert(theEvent.locationInWindow, from: nil)
		
		if self.updatePreferredWidthRequirementsForCursorLocation(locationInView) == false {
			return
		}
		
		self.updateCurrentItemViewWidths()
		self.adjustItemViewFrames(withAnimation: true)
	}
	
	
	// MARK: - NSView overrides
	
	/// Resize the receiver’s subviews.
	///
	/// - Parameter oldSize: The old size of the receiver.
	override public func resizeSubviews(withOldSize oldSize: NSSize) {
		self.updateCurrentItemViewWidths()
		self.adjustItemViewFrames(withAnimation: false)
	}
	
	/// The view moved to a new window.
	override public func viewDidMoveToWindow() {
		super.viewDidMoveToWindow()
		self.active = self.window?.isMainWindow ?? false
	}
	
	
	// MARK: - NSAccessibility implementation
	
	/// Indicates whether the receiver is an accessible element.
	///
	/// - Returns: `true`
	override public func isAccessibilityElement() -> Bool {
		return true
	}
	
	/// Returns the accessibility role of the receiver.
	///
	/// - Returns: `NSAccessibility.Role.list`
	override public func accessibilityRole() -> NSAccessibility.Role? {
		return NSAccessibility.Role.list
	}
	
	/// Returns a description of the receiver’s accessibility role.
	///
	/// - Returns: The description of an accessible list.
	override public func accessibilityRoleDescription() -> String? {
		guard let standardDescription = NSAccessibility.Role.list.description(with: nil) else {
			return nil
		}
		
		let descriptionFormat = Localizable.roleDescriptionFormat.localized
		return String.localizedStringWithFormat(descriptionFormat, standardDescription)
	}
	
	/// Returns a description of the receiver’s accessibility value.
	///
	/// - Returns: The Path View’s accessibility value.
	override public func accessibilityValueDescription() -> String? {
		return self.delegate?.pathViewAccessibilityDescription(self) ?? Localizable.emptyPathDescription.localized
	}
	
	/// Returns the accessibile children of the receiver.
	///
	/// - Returns: The accessible children of the Path View.
	override public func accessibilityChildren() -> [Any]? {
		return NSAccessibility.unignoredChildren(from: self.itemViews)
	}
	
	/// Returns whether accessibility is current enabled for the receiver.
	///
	/// - Returns: `true` if accessibility is enable for the view, `false` if
	/// not.
	override public func isAccessibilityEnabled() -> Bool {
		return self.enabled
	}
	
	/// Returns the general orientation of the list.
	///
	/// - Returns: `.horizontal`
	override public func accessibilityOrientation() -> NSAccessibilityOrientation {
		return .horizontal
	}
	
	/// Returns accessibility help text for the receiver.
	///
	/// - Returns: A description of how to use the Path View.
	override public func accessibilityHelp() -> String? {
		return self.delegate?.pathViewAccessibilityHelp(self)
	}
	
	
	// MARK: - OBWPathView public
	
	/// The Path View’s delegate, if any.
	public weak var delegate: OBWPathViewDelegate?
	
	/// Indicates whether the Path View is currently enabled.  Key-Value
	/// observable.
	@objc public dynamic var enabled = true {
		didSet {
			for itemView in self.itemViews {
				itemView.pathViewAppearanceChanged()
			}
		}
	}
	
	/// Returns the number of items currently in the Path View.
	public var numberOfItems: Int {
		return self.itemViews.count
	}
	
	/// Replaces the Path View’s current items with the given items.
	///
	/// - parameter pathItems: The new Path View’s new items.
	public func setItems(_ pathItems: [OBWPathItem]) {
		self.pathItemUpdate {
			for itemIndex in pathItems.indices {
				try? self.setItem(pathItems[itemIndex], atIndex: itemIndex)
			}
			
			try? self.removeItemsFromIndex(pathItems.endIndex)
		}
	}
	
	/// Returns the item at the given index.
	///
	/// - Parameter index: The index of the desired item.
	///
	/// - Throws: `ErrorType.invalidIndex` if the index is out of range.
	///
	/// - Returns: The item at the given index.
	public func item(atIndex index: Int) throws -> OBWPathItem {
		guard self.itemViews.indices.contains(index) else {
			throw ErrorType.invalidIndex(index: index, endIndex: self.itemViews.endIndex)
		}
		
		guard let pathItem = self.itemViews[index].pathItem else {
			throw ErrorType.internalConsistency("Valid item view does not have a path item")
		}
		
		return pathItem
	}
	
	/// Replaces the item at the given index with a new item.  If the index is
	/// equal to the number of items currently in the Path View, the new item is
	/// appended to the end of the current list of items.
	///
	/// - Parameters:
	///   - item: The Path Item to add.
	///   - index: The index at which to add the Path Item, replacing any item
	///   that may exist at that index.
	///
	/// - Throws: `ErrorType.invalidIndex` if the index is out of range.
	public func setItem(_ item: OBWPathItem, atIndex index: Int) throws {
		guard (self.itemViews.startIndex...self.itemViews.endIndex).contains(index) else {
			throw ErrorType.invalidIndex(index: index, endIndex: self.itemViews.endIndex)
		}
		
		self.pathItemUpdate {
			
			if index == self.itemViews.endIndex {
				
				let pathViewBounds = self.bounds
				
				var newItemViewFrame: NSRect
				switch NSApp.userInterfaceLayoutDirection {
					case .rightToLeft:
						let lastFrameLeading = self.itemViews.last?.frame.minX ?? pathViewBounds.maxX
						newItemViewFrame = NSRect(
							x: min(pathViewBounds.minX, lastFrameLeading) - 50.0,
							y: pathViewBounds.minY,
							width: 50.0,
							height: pathViewBounds.height
						)
						
					case .leftToRight:
						fallthrough
					@unknown default:
						let lastFrameTrailing = self.itemViews.last?.frame.maxX ?? pathViewBounds.minX
						newItemViewFrame = NSRect(
							x: max(pathViewBounds.maxX, lastFrameTrailing),
							y: pathViewBounds.minY,
							width: 50.0,
							height: pathViewBounds.height
						)
				}
				
				let itemView = OBWPathItemView(frame: newItemViewFrame)
				itemView.alphaValue = 0.0
				itemView.pathItem = item
				self.addSubview(itemView)
				self.itemViews.append(itemView)
				
				if NSApp.userInterfaceLayoutDirection == .rightToLeft {
					newItemViewFrame.origin.x = newItemViewFrame.maxX - itemView.preferredWidth
				}
				newItemViewFrame.size.width = itemView.preferredWidth
				
				itemView.currentWidth = newItemViewFrame.width
				itemView.idleWidth = newItemViewFrame.width
				itemView.frame = newItemViewFrame
			}
			else {
				self.itemViews[index].pathItem = item
			}
		}
	}
	
	/// Removes the Path Item at the given index.
	///
	/// - Parameter index: The index of the Path Item to remove.
	///
	/// - Throws: `ErrorType.invalidIndex` if the index is out of range.
	public func removeItemsFromIndex(_ index: Int) throws {
		// Note that `endIndex` *is* a valid index.
		guard (self.itemViews.startIndex...self.itemViews.endIndex).contains(index) else {
			throw ErrorType.invalidIndex(index: index, endIndex: self.itemViews.endIndex)
		}
		
		// An index equal to count is tolerated for symmetry with setItem(_:atIndex:).
		if index == self.itemViews.endIndex {
			return
		}
		
		self.pathItemUpdate {
			self.terminatedViews = Array(self.itemViews.suffix(from: index))
			self.itemViews = Array(self.itemViews.prefix(upTo: index))
		}
	}
	
	/// Begin a batch update of path items.  Must be balanced by a call to
	/// `endPathItemUpdate()`.
	///
	/// - Note: Multiple calls to `beginPathItemUpdate()` may be made provided
	/// each is balanced by a call to `endPathItemUpdate()`.  Path Item updates
	/// will not occur until the last call to `beginPathItemUpdate()` is
	/// balanced by a call to `endPathItemUpdate()`.
	public func beginPathItemUpdate() {
		self.pathItemUpdateDepth += 1
	}
	
	/// Ends a batch update of path items.  Balances a previous call to
	/// `beginPathItemUpdate()`.
	///
	/// - Throws: `ErrorType.imbalancedEndPathItemUpdate` if a call to
	/// `endPathItemUpdate()` does not balance a previous call to
	/// `beginPathItemUpdate()`.
	public func endPathItemUpdate() throws {
		if self.pathItemUpdateDepth <= 0 {
			throw ErrorType.imbalancedEndPathItemUpdate
		}
		
		self.pathItemUpdateDepth -= 1
		
		guard self.pathItemUpdateDepth == 0 else { return }
		
		self.updateItemDividerVisibility()
		_ = self.updatePreferredWidthRequirements()
		self.updateCurrentItemViewWidths()
		self.adjustItemViewFrames(withAnimation: true)
	}
	
	/// Executes the given closure within a single path item update context.
	///
	/// - Parameter handler: The closure to call.
	public func pathItemUpdate(withHandler handler: () -> Void) {
		self.beginPathItemUpdate()
		handler()
		try! self.endPathItemUpdate()
	}
	
	
	// MARK: - Private
	
	/// Indicates whether the Path View is currently active.
	private(set) var active = false {
		didSet {
			guard self.enabled else {
				return
			}
			
			for itemView in self.itemViews {
				itemView.pathViewAppearanceChanged()
			}
		}
	}
	
	/// The current views displaying Path Items.
	private var itemViews: [OBWPathItemView] = []
	
	/// The current depth of `beginPathItemUpdate()` / `endPathItemUpdate()`
	/// calls.
	private var pathItemUpdateDepth = 0
	
	/// Views that are being removed from the Path View.
	private var terminatedViews: [OBWPathItemView]?
	
	/// The Path View’s window changed “Main” status.
	@objc private func windowBecameOrResignedMain(_ notification: Notification) {
		self.needsDisplay = true
		self.active = (notification.name == NSWindow.didBecomeMainNotification)
	}
	
	/// Updates the visibility of each of the divider images within the
	/// Path View.
	private func updateItemDividerVisibility() {
		guard let lastItemView = self.itemViews.last else {
			return
		}
		
		for itemView in self.itemViews {
			itemView.dividerHidden = (itemView === lastItemView)
		}
	}
	
	/// Updates each of the Path Item’s current preferred widths.
	///
	/// - Returns: `true` if any item’s preferred width changed, `false` if all
	/// did not change.
	private func updatePreferredWidthRequirements() -> Bool {
		guard let window = self.window else {
			return false
		}
		
		let locationInScreen = NSRect(origin: NSEvent.mouseLocation, size: .zero)
		let locationInWindow = window.convertFromScreen(locationInScreen)
		let locationInView = self.convert(locationInWindow.origin, from: nil)
		
		return self.updatePreferredWidthRequirementsForCursorLocation(locationInView)
	}
	
	
	/// Updates each of the Path Item’s current preferred widths based on the
	/// given cursor location.
	///
	/// - Parameter locationInView: The location of the cursor in the
	/// Path View’s coordinate system.
	///
	/// - Returns: `true` if any item’s preferred width changed, `false` if all
	/// did not change.
	private func updatePreferredWidthRequirementsForCursorLocation(_ locationInView: NSPoint) -> Bool {
		let cursorIsInParent = NSPointInRect(locationInView, self.bounds)
		
		var itemLeadingEdge: CGFloat
		switch NSApp.userInterfaceLayoutDirection {
			case .rightToLeft:
				itemLeadingEdge = self.bounds.maxX
				
			case .leftToRight:
				fallthrough
			@unknown default:
				itemLeadingEdge = self.bounds.minX
		}
		
		var anItemHasBeenCollapsed = false
		var anItemHasBeenExpanded = false
		
		for itemView in self.itemViews {
			if anItemHasBeenExpanded {
				itemView.preferredWidthRequired = false
				continue
			}
			
			let itemWidthToTest = (anItemHasBeenCollapsed ? itemView.preferredWidth : itemView.currentWidth)
			
			let itemTrailingEdge: CGFloat
			let cursorIsInItem: Bool
			switch NSApp.userInterfaceLayoutDirection {
				case .rightToLeft:
					itemTrailingEdge = itemLeadingEdge - itemWidthToTest
					cursorIsInItem = (locationInView.x >= itemTrailingEdge && locationInView.x < itemLeadingEdge)
					
				case .leftToRight:
					fallthrough
				@unknown default:
					itemTrailingEdge = itemLeadingEdge + itemWidthToTest
					cursorIsInItem = (locationInView.x >= itemLeadingEdge && locationInView.x < itemTrailingEdge)
			}
			
			let preferredWidthIsRequired = (cursorIsInParent && cursorIsInItem)
			
			if itemView.preferredWidthRequired == preferredWidthIsRequired {
				switch NSApp.userInterfaceLayoutDirection {
					case .rightToLeft:
						itemLeadingEdge -= itemWidthToTest
						
					case .leftToRight:
						fallthrough
					@unknown default:
						itemLeadingEdge += itemWidthToTest
				}
				continue
			}
			
			itemView.preferredWidthRequired = preferredWidthIsRequired
			
			if preferredWidthIsRequired {
				anItemHasBeenExpanded = true
				switch NSApp.userInterfaceLayoutDirection {
					case .rightToLeft:
						itemLeadingEdge -= itemWidthToTest
						
					case .leftToRight:
						fallthrough
					@unknown default:
						itemLeadingEdge += itemWidthToTest
				}
			}
			else {
				anItemHasBeenCollapsed = true
				switch NSApp.userInterfaceLayoutDirection {
					case .rightToLeft:
						itemLeadingEdge -= itemView.idleWidth
						
					case .leftToRight:
						fallthrough
					@unknown default:
						itemLeadingEdge += itemView.idleWidth
				}
			}
		}
		
		return (anItemHasBeenCollapsed || anItemHasBeenExpanded)
	}
	
	/// Updates the current width of all Path Items based on the preferred width
	/// of each and the amount of horizontal space available to display items.
	private func updateCurrentItemViewWidths() {
		var itemViews = self.itemViews
		
		if itemViews.isEmpty {
			return
		}
		
		var totalPreferredWidth: CGFloat = 0.0
		
		for itemView in itemViews {
			let preferredWidth = itemView.preferredWidth
			itemView.currentWidth = preferredWidth
			itemView.idleWidth = preferredWidth
			totalPreferredWidth += preferredWidth
		}
		
		let parentWidth = self.bounds.width
		
		if parentWidth >= totalPreferredWidth {
			return
		}
		
		let tailItemView = itemViews.removeLast()
		let penultimateItemView: OBWPathItemView? = itemViews.popLast()
		let headItemView: OBWPathItemView? = (itemViews.count > 0 ? itemViews.removeFirst() : nil)
		let interiorItemViews = itemViews
		
		let tailPreferredWidth = tailItemView.preferredWidth
		let penultimateMinimumWidth = penultimateItemView?.minimumWidth ?? 0.0
		let penultimatePreferredWidth = penultimateItemView?.preferredWidth ?? 0.0
		let headMinimumWidth = headItemView?.minimumWidth ?? 0.0
		let headPreferredWidth = headItemView?.preferredWidth ?? 0.0
		
		var interiorMinimumWidth: CGFloat = 0.0
		for itemView in interiorItemViews {
			interiorMinimumWidth += itemView.minimumWidth
		}
		
		var compression = CompressionPriority.interior
		var widthToCompress = totalPreferredWidth - parentWidth
		
		if parentWidth < headMinimumWidth + interiorMinimumWidth + penultimateMinimumWidth + tailPreferredWidth {
			compression = .tail
		}
		else if parentWidth < headMinimumWidth + interiorMinimumWidth + penultimatePreferredWidth + tailPreferredWidth {
			compression = .penultimate
		}
		else if parentWidth < headPreferredWidth + interiorMinimumWidth + penultimatePreferredWidth + tailPreferredWidth {
			compression = .head
		}
		
		if compression >= .interior && interiorItemViews.isEmpty == false {
			widthToCompress -= self.compress(itemViews: interiorItemViews, by: widthToCompress)
		}
		
		if let headItemView = headItemView {
			if compression >= .head {
				widthToCompress -= self.compress(itemViews: [headItemView], by: widthToCompress)
			}
		}
		
		if let penultimateItemView = penultimateItemView {
			if compression >= .penultimate {
				widthToCompress -= self.compress(itemViews: [penultimateItemView], by: widthToCompress)
			}
		}
		
		if compression == .tail {
			let tailMinimumWidth = tailItemView.minimumWidth
			let tailCurrentWidth = (tailPreferredWidth - widthToCompress < tailMinimumWidth ? tailMinimumWidth : tailPreferredWidth - widthToCompress)
			tailItemView.currentWidth = tailCurrentWidth
			tailItemView.idleWidth = tailCurrentWidth
		}
		
		for itemView in self.itemViews {
			if itemView.preferredWidthRequired && itemView.currentWidth < itemView.preferredWidth {
				itemView.currentWidth = itemView.preferredWidth
			}
		}
	}
	
	/// Compress the given views proportionally by the given distance.
	///
	/// - Parameters:
	///   - itemViews: The view to compress.
	///   - compression: The number of combined points that `itemViews` should
	///   be compressed by.
	///
	/// - Returns: The number of combined points by which `itemViews` were
	/// actually compressed.  May be less than `compression` if all `itemViews`
	/// are compressed to their minimum widths.
	private func compress(itemViews: [OBWPathItemView], by compression: CGFloat) -> CGFloat {
		var compressibleItemViews: [OBWPathItemView] = []
		var totalWidthItemsCanCompress: CGFloat = 0.0
		
		for itemView in itemViews {
			let widthItemCanCompress = itemView.preferredWidth - itemView.minimumWidth
			
			if widthItemCanCompress > 0.0 {
				totalWidthItemsCanCompress += widthItemCanCompress
				compressibleItemViews.append(itemView)
			}
		}
		
		guard
			let lastCompressibleView = compressibleItemViews.last,
			totalWidthItemsCanCompress > 0.0
		else {
			return 0.0
		}
		
		let widthToCompress = compression
		
		if totalWidthItemsCanCompress < widthToCompress {
			for itemView in compressibleItemViews {
				let minimumWidth = itemView.minimumWidth
				itemView.currentWidth = minimumWidth
				itemView.idleWidth = minimumWidth
			}
			
			return totalWidthItemsCanCompress
		}
		
		var widthRemainingToCompress = widthToCompress
		
		for itemView in compressibleItemViews {
			let preferredWidth = itemView.preferredWidth
			var widthToCompressItem = widthRemainingToCompress
			
			if itemView !== lastCompressibleView {
				
				let widthItemCanCompress = preferredWidth - itemView.minimumWidth
				let compressionFraction = widthItemCanCompress / totalWidthItemsCanCompress
				widthToCompressItem = round(widthToCompress * compressionFraction)
			}
			
			let itemWidth = preferredWidth - widthToCompressItem
			itemView.currentWidth = itemWidth
			itemView.idleWidth = itemWidth
			widthRemainingToCompress -= widthToCompressItem
		}
		
		return widthToCompress
	}
	
	/// Repositions all item views based on their current sizes.
	///
	/// - Parameter animate: If `true`, the views will animate to their new
	/// locations.
	private func adjustItemViewFrames(withAnimation animate: Bool) {
		let shiftKey = NSEvent.modifierFlags.contains(.shift)
		let animationDuration = (animate ? (shiftKey ? 2.5 : 0.1) : 0.0)
		
		NSAnimationContext.runAnimationGroup({
			(context: NSAnimationContext) in
			
			context.duration = animationDuration
			
			var itemOriginX: CGFloat
			switch NSApp.userInterfaceLayoutDirection {
				case .rightToLeft:
					itemOriginX = self.bounds.maxX
					
				case .leftToRight:
					fallthrough
				@unknown default:
					itemOriginX = self.bounds.minX
			}
			
			for itemView in self.itemViews {
				var itemFrame = itemView.frame
				switch NSApp.userInterfaceLayoutDirection {
					case .rightToLeft:
						itemFrame.origin.x = itemOriginX - itemView.currentWidth
						
					case .leftToRight:
						fallthrough
					@unknown default:
						itemFrame.origin.x = itemOriginX
				}
				itemFrame.size.width = itemView.currentWidth
				
				let targetView = (animate ? itemView.animator() : itemView)
				targetView.frame = itemFrame
				targetView.alphaValue = 1.0
				
				itemView.needsDisplay = true
				
				switch NSApp.userInterfaceLayoutDirection {
					case .rightToLeft:
						itemOriginX -= itemFrame.width
						
					case .leftToRight:
						fallthrough
					@unknown default:
						itemOriginX += itemFrame.width
				}
			}
			
		}, completionHandler: nil)
		
		guard let terminatedViews = self.terminatedViews else {
			return
		}
		
		self.terminatedViews = nil
		
		NSAnimationContext.runAnimationGroup({
			(context: NSAnimationContext) in
			
			context.duration = animationDuration
			context.timingFunction = CAMediaTimingFunction(name: .easeIn)
			
			var itemOriginX: CGFloat
			switch NSApp.userInterfaceLayoutDirection {
				case .rightToLeft:
					itemOriginX = self.bounds.minX
					
				case .leftToRight:
					fallthrough
				@unknown default:
					itemOriginX = self.bounds.maxX
			}
			
			for itemView in terminatedViews {
				var itemFrame = itemView.frame
				switch NSApp.userInterfaceLayoutDirection {
					case .rightToLeft:
						itemFrame.origin.x = itemOriginX - itemFrame.width
						
					case .leftToRight:
						fallthrough
					@unknown default:
						itemFrame.origin.x = itemOriginX
				}
				
				let targetView = (animate ? itemView.animator() : itemView)
				targetView.frame = itemFrame
				targetView.alphaValue = 0.0
				
				itemView.needsDisplay = true
				
				switch NSApp.userInterfaceLayoutDirection {
					case .rightToLeft:
						itemOriginX -= itemFrame.width
						
					case .leftToRight:
						fallthrough
					@unknown default:
						itemOriginX += itemFrame.width
				}
			}
			
		}, completionHandler: {
			
			for itemView in terminatedViews {
				itemView.pathItem = nil
				itemView.removeFromSuperview()
			}
		})
	}
}
