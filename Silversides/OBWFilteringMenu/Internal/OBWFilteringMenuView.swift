/*===========================================================================
OBWFilteringMenuView.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit
import Carbon.HIToolbox.Events

/// A view class that is the outermost menu-related view.  It’s primary subviews
/// are the filter field and the menu item scroll view.
class OBWFilteringMenuView: NSView {
	/// Initialization.
	///
	/// - Parameters:
	///   - menu: The menu that the view displays.
	///   - minimumWidth: The minimum width that the menu may occupy.
	init(menu: OBWFilteringMenu, minimumWidth: CGFloat) {
		self.filteringMenu = menu
		
		let initialFrame = NSRect(
			width: OBWFilteringMenuView.filterMargins.width + OBWFilteringMenuItemView.minimumWidth,
			height: 0.0
		)
		
		let menuFont = menu.displayFont
		let filterFieldSize = NSControl.controlSizeForFontSize(menuFont.pointSize)
		let filterFrame: NSRect
		switch NSApp.userInterfaceLayoutDirection {
			case .rightToLeft:
				filterFrame = NSRect(
					x: OBWFilteringMenuView.filterMargins.trailing,
					y: 0.0,
					width: initialFrame.width - OBWFilteringMenuView.filterMargins.width,
					height: filterFieldSize.standardMenuHeight
				)
				
			case .leftToRight:
				fallthrough
			@unknown default:
				filterFrame = NSRect(
					x: OBWFilteringMenuView.filterMargins.leading,
					y: 0.0,
					width: initialFrame.width - OBWFilteringMenuView.filterMargins.width,
					height: filterFieldSize.standardMenuHeight
				)
		}
		
		let filterField = NSSearchField(frame: filterFrame)
		filterField.font = menuFont
		filterField.bezelStyle = .roundedBezel
		filterField.autoresizingMask = [.width, .minYMargin]
		filterField.isHidden = true
		filterField.cell?.controlSize = filterFieldSize
		filterField.cell?.focusRingType = .none
		filterField.cell?.isScrollable = true
		filterField.cell?.setAccessibilityTitle(Localizable.filterFieldAccessibilityTitle.localized)
		filterField.cell?.setAccessibilityHelp(Localizable.filterFieldHelp.localized)
		(filterField.cell as? NSTextFieldCell)?.placeholderString = Localizable.filterPlaceholder.localized
		self.filterField  = filterField
		
		let scrollView = OBWFilteringMenuItemScrollView(menu: menu, minimumWidth: minimumWidth)
		self.scrollView = scrollView
		
		super.init(frame: initialFrame)
		
		self.autoresizingMask = [.minYMargin]
		self.autoresizesSubviews = true
		
		self.addSubview(filterField)
		self.setFrameSize(scrollView.frame.size)
		self.addSubview(scrollView)
		
		NotificationCenter.default.addObserver(self, selector: #selector(OBWFilteringMenuView.textDidChange(_:)), name: NSText.didChangeNotification, object: nil)
	}
	
	// Required initializer.
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	/// Deinitialization.
	deinit {
		NotificationCenter.default.removeObserver(self, name: NSText.didChangeNotification, object: nil)
	}
	
	/// Localizable strings.
	enum Localizable: CaseLocalizable {
		/// The title of the filter field that appears at the top of a menu when
		/// the user begins typing.
		case filterFieldAccessibilityTitle
		/// Help text for the filtering menu’s editable filter field.
		case filterFieldHelp
		/// Text that appears in the background of a menu’s filter field when it
		/// contains no user-entered text.
		case filterPlaceholder
	}
	
	
	// MARK: - NSResponder
	
	/// Set the current cursor image.
	override func cursorUpdate(with event: NSEvent) {
		guard
			self.dispatchingCursorUpdateToFilterField == false,
			let locationInView = event.locationInView(self)
		else {
			return
		}
		
		let filterField = self.filterField
		let filterFieldFrame = filterField.frame
		
		if filterField.isHidden == false && NSPointInRect(locationInView, filterFieldFrame) {
			
			// The search field might call -[super cursorUpdate:], which might eventually reach -[NSResponder cursorUpdate:], which will send the message up the responder chain, which leads back here.  'dispatchingCursorUpdateToFilterField' is used to break that recursion.
			
			self.dispatchingCursorUpdateToFilterField = true
			filterField.cursorUpdate(with: event)
			self.dispatchingCursorUpdateToFilterField = false
		}
		else {
			NSCursor.arrow.set()
		}
	}
	
	
	// MARK: - NSView
	
	/// Draw the view.
	///
	/// - Parameter dirtyRect: The portion of the view that needs display.
	override func draw(_ dirtyRect: NSRect) {
		#if DEBUG_MENU_TINTING
		NSColor.red.withAlphaComponent(0.1).set()
		self.bounds.fill()
		#endif
	}
	
	
	// MARK: - NSAccessibility Implementation
	
	/// Indicates whether the receiver is an accessible element.
	///
	/// - Returns: `true`
	override func isAccessibilityElement() -> Bool {
		return true
	}
	
	/// Returns the accessibility role of the receiver.
	///
	/// - Returns: `NSAccessibility.Role.list`
	override func accessibilityRole() -> NSAccessibility.Role? {
		return NSAccessibility.Role.list
	}
	
	/// Returns a description of the receiver’s accessibility role.
	///
	/// - Returns: The description of an accessible list.
	override func accessibilityRoleDescription() -> String? {
		return NSAccessibility.Role.list.description(with: nil)
	}
	
	/// Returns the accessibile children of the receiver.
	///
	/// - Returns: The accessible children of the menu view.
	override func accessibilityChildren() -> [Any]? {
		guard var children = self.scrollView.accessibilityChildren() else {
			return nil
		}
		
		if self.filterField.isHidden == false {
			children.append(filterField)
		}
		
		return NSAccessibility.unignoredChildren(from: children)
	}
	
	/// Returns whether accessibility is current enabled for the receiver.
	///
	/// - Returns: `true`
	override func isAccessibilityEnabled() -> Bool {
		return true
	}
	
	/// Returns the window.
	override func accessibilityParent() -> Any? {
		guard let window = self.window else {
			return nil
		}
		
		return NSAccessibility.unignoredAncestor(of: window)
	}
	
	/// Returns the currently highlighted menu item view, if any.
	override func accessibilitySelectedChildren() -> [Any]? {
		guard
			let menuItem = self.filteringMenu.highlightedItem,
			let itemView = self.viewForMenuItem(menuItem)
		else {
			return []
		}
		
		return [itemView]
	}
	
	/// Returns the title element.
	override func accessibilityTitleUIElement() -> Any? {
		return self
	}
	
	/// Returns the accessibility visible children.
	override func accessibilityVisibleChildren() -> [Any]? {
		guard let scrollChildren = self.scrollView.accessibilityChildren() else {
			return nil
		}
		
		return NSAccessibility.unignoredChildren(from: scrollChildren)
	}
	
	/// The list is oriented vertically.
	override func accessibilityOrientation() -> NSAccessibilityOrientation {
		return .vertical
	}
	
	/// The window is the top-level element.
	override func accessibilityTopLevelUIElement() -> Any? {
		return self.window
	}
	
	/// Sets the currently selected children.
	///
	/// - Parameter accessibilitySelectedChildren: The children to select.
	override func setAccessibilitySelectedChildren(_ accessibilitySelectedChildren: [Any]?) {
		let selectedView = accessibilitySelectedChildren?.first as? OBWFilteringMenuItemView
		self.filteringMenu.highlightedItem = selectedView?.menuItem
	}
	
	
	// MARK: - NSControl Delegate Implementation
	
	/// Responds to a change in the text in the filter text field.
	///
	/// - Parameter notification: The notification posted when the filter
	/// field’s text changes.
	@objc func textDidChange(_ notification: Notification) {
		let filterField = self.filterField
		
		guard
			let notificationObject = notification.object as? NSText,
			let currentEditor = filterField.currentEditor(),
			notificationObject === currentEditor
		else {
			return
		}
		
		NSAccessibility.post(element: currentEditor, notification: NSAccessibility.Notification.focusedUIElementChanged)
		
		let filterString = filterField.stringValue.trimmingCharacters(in: .whitespaces)
		let menu = self.filteringMenu
		
		let filterEventNumber = self.lastFilterEventNumber + 1
		self.lastFilterEventNumber = filterEventNumber
		
		if filterString.isEmpty {
			self.applyFilterResults(nil)
		}
		else {
			DispatchQueue.global(qos: .userInitiated).async {
				
				let statusArray = OBWFilteringMenuItemFilterStatus.filterStatus(menu, filterString: filterString)
				
				DispatchQueue.main.async {
					guard self.lastFilterEventNumber == filterEventNumber else {
						return
					}
					
					self.applyFilterResults(statusArray)
				}
			}
		}
	}
	
	
	// MARK: - OBWFilteringMenuView Interface
	
	/// Margins around the filter text field.
	static let filterMargins = NSEdgeInsets(top: 4.0, leading: 20.0, bottom: 4.0, trailing: 20.0)
	
	/// Returns the total size of all of the current menu items.
	var totalMenuItemSize: NSSize {
		return self.scrollView.totalMenuItemSize
	}
	
	/// Returns the current menu item bounds.
	var menuItemBounds: NSRect {
		return self.scrollView.menuItemBounds
	}
	
	/// Returns the margins around the menu portion of the view, excluding the
	/// filter field.
	var outerMenuMargins: NSEdgeInsets {
		let filterField = self.filterField
		
		guard filterField.isHidden == false else {
			return .zero
		}
		
		let filterAreaHeight = OBWFilteringMenuView.filterMargins.height + filterField.frame.height
		
		return NSEdgeInsets(top: filterAreaHeight, left: 0.0, bottom: 0.0, right: 0.0)
	}
	
	/// Returns the minimum height to display just the top item in the menu.
	var minimumHeightAtTop: CGFloat {
		let scrollViewMinimumHeight = self.scrollView.minimumHeightAtTop
		
		let filterField = self.filterField
		if filterField.isHidden {
			return scrollViewMinimumHeight
		}
		
		let filterMargins = OBWFilteringMenuView.filterMargins
		let minimumHeight = scrollViewMinimumHeight + filterMargins.height + filterField.frame.height
		
		return minimumHeight
	}
	
	/// Returns the minimum height to display just the bottom item in the menu.
	var minimumHeightAtBottom: CGFloat {
		let scrollViewMinimumHeight = self.scrollView.minimumHeightAtBottom
		
		let filterField = self.filterField
		if filterField.isHidden {
			return scrollViewMinimumHeight
		}
		
		let filterMargins = OBWFilteringMenuView.filterMargins
		let minimumHeight = scrollViewMinimumHeight + filterMargins.height + filterField.frame.height
		
		return minimumHeight
	}
	
	/// Rebuilds the subviews based on the current menu contents.
	func menuContentsDidChange() {
		self.scrollView.menuContentsDidChange()
	}
	
	/// Handle a left mouse button down event.  The event is forwarded to the
	/// filter field if appropriate.  Otherwise, the event remains unhandled.
	func handleLeftMouseButtonDownEvent(_ event: NSEvent) -> OBWFilteringMenu.SessionState {
		let filterField = self.filterField
		
		guard
			filterField.isHidden == false,
			let locationInView = event.locationInView(self),
			NSPointInRect(locationInView, filterField.frame)
		else {
			return .unhandled
		}
		
		filterField.mouseDown(with: event)
		
		return .continue
	}
	
	/// Handle a key-down event.
	func handleKeyDownEvent(_ event: NSEvent) -> OBWFilteringMenu.SessionState {
		let keyCode = Int(event.keyCode)
		
		let scrollView = self.scrollView
		let filterField = self.filterField
		var currentEditor = filterField.currentEditor()
		
		if event.modifierFlags.contains(.command) {
			if currentEditor != nil {
				NSApp.sendEvent(event)
			}
			
			return .continue
		}
		
		if keyCode == kVK_Tab {
			if filterField.isHidden {
				return .continue
			}
			
			self.moveKeyboardFocusToFilterFieldAndSelectAll(true)
			
			return .highlight
		}
		
		let filteringMenu = self.filteringMenu
		let currentHighlightedItem = filteringMenu.highlightedItem
		let currentHighlightedItemView: OBWFilteringMenuItemView?
		
		if let currentHighlightedItem = currentHighlightedItem {
			currentHighlightedItemView = scrollView.viewForMenuItem(currentHighlightedItem)
		}
		else {
			currentHighlightedItemView = nil
		}
		
		var nextHighlightedItemView = currentHighlightedItemView
		
		switch keyCode {
			case kVK_UpArrow, kVK_Home, kVK_PageUp:
				if let currentEditor = currentEditor, currentHighlightedItem == nil {
					currentEditor.keyDown(with: event)
					return .continue
				}
				
				if keyCode == kVK_UpArrow {
					nextHighlightedItemView = scrollView.previousViewBeforeItem(currentHighlightedItem)
				}
				else if keyCode == kVK_Home {
					nextHighlightedItemView = scrollView.nextViewAfterItem(nil)
				}
				else if keyCode == kVK_PageUp {
					nextHighlightedItemView = scrollView.scrollItemsDownOnePage()
				}
				
				if nextHighlightedItemView === currentHighlightedItemView && filterField.isHidden == false {
					self.moveKeyboardFocusToFilterFieldAndSelectAll(true)
					return .highlight
				}
				
				if
					let nextHighlightedItemView = nextHighlightedItemView,
					nextHighlightedItemView !== currentHighlightedItemView
				{
					filteringMenu.highlightedItem = nextHighlightedItemView.menuItem
					scrollView.scrollItemToVisible(nextHighlightedItemView.menuItem)
					return .highlight
				}
				
				return .continue
				
			case kVK_DownArrow, kVK_End, kVK_PageDown:
				if currentEditor != nil {
					self.window?.makeFirstResponder( nil )
					nextHighlightedItemView = scrollView.nextViewAfterItem(currentHighlightedItem)
				}
				else if keyCode == kVK_DownArrow {
					nextHighlightedItemView = scrollView.nextViewAfterItem(currentHighlightedItem)
				}
				else if keyCode == kVK_End {
					nextHighlightedItemView = scrollView.previousViewBeforeItem(nil)
				}
				else if keyCode == kVK_PageDown {
					nextHighlightedItemView = scrollView.scrollItemsUpOnePage()
				}
				
				if
					let nextHighlightedItemView = nextHighlightedItemView,
					nextHighlightedItemView !== currentHighlightedItemView
				{
					filteringMenu.highlightedItem = nextHighlightedItemView.menuItem
					scrollView.scrollItemToVisible(nextHighlightedItemView.menuItem)
					return .highlight
				}
				
				return .continue
				
			case kVK_LeftArrow, kVK_RightArrow, kVK_Space, kVK_Return, kVK_ANSI_KeypadEnter, kVK_Delete, kVK_ForwardDelete:
				if let currentEditor = currentEditor {
					currentEditor.keyDown(with: event)
					return .continue
				}
				else {
					return .unhandled
				}
				
			default:
				break
		}
		
		if filterField.isHidden {
			let filterMargins = OBWFilteringMenuView.filterMargins
			var scrollViewFrame = self.scrollView.frame
			scrollViewFrame.size.height -= (filterMargins.height + filterField.frame.height)
			self.scrollView.setFrameSize(scrollViewFrame.size)
			
			var filterFieldFrame = filterField.frame
			filterFieldFrame.origin.y = scrollViewFrame.maxY + filterMargins.bottom
			filterField.setFrameOrigin(filterFieldFrame.origin)
			filterField.isHidden = false
			
			if let window = self.window as? OBWFilteringMenuWindow {
				window.displayUpdatedTotalMenuItemSize(constrainToAnchor: true)
			}
		}
		
		if currentEditor == nil {
			self.moveKeyboardFocusToFilterFieldAndSelectAll(true)
			currentEditor = filterField.currentEditor()
		}
		
		if let currentEditor = currentEditor {
			currentEditor.keyDown(with: event)
		}
		
		return .changeFilter
	}
	
	/// Handle a change to the currently pressed keyboard modifiers.
	///
	/// - Parameter modifierFlags: The current pressed modifier keys.
	func applyModifierFlags(_ modifierFlags: NSEvent.ModifierFlags) {
		if self.scrollView.applyModifierFlags(modifierFlags) {
			if let window = self.window as? OBWFilteringMenuWindow {
				window.displayUpdatedTotalMenuItemSize(constrainToAnchor: true)
			}
		}
	}
	
	/// Applies filter status results to the menu.
	///
	/// - Parameter statusArray: The status to apply to the menu.
	func applyFilterResults(_ statusArray: [OBWFilteringMenuItemFilterStatus]?) {
		if self.scrollView.applyFilterResults(statusArray) {
			if let window = self.window as? OBWFilteringMenuWindow {
				window.displayUpdatedTotalMenuItemSize(constrainToAnchor: true)
			}
		}
	}
	
	/// Highlight the first menu item.
	func selectFirstMenuItemView() {
		self.filteringMenu.highlightedItem = self.scrollView.nextViewAfterItem(nil)?.menuItem
	}
	
	/// Returns the menu item at the given location.
	///
	/// - parameter locationInView: A location in the receiver’s coordinate
	/// system.
	func menuItemAtLocation(_ locationInView: NSPoint) -> OBWFilteringMenuItem? {
		let scrollView = self.scrollView
		let locationInScrollView = self.convert(locationInView, to: scrollView)
		return scrollView.menuItemAtLocation(locationInScrollView)
	}
	
	/// Returns the menu part at the given location.
	///
	/// - parameter locationInView: A location in the receiver’s coordinate
	/// system.
	func menuPartAtLocation(_ locationInView: NSPoint) -> OBWFilteringMenu.MenuPart {
		let filterField = self.filterField
		if filterField.isHidden == false, NSPointInRect(locationInView, filterField.frame) {
			return .filter
		}
		
		let scrollView = self.scrollView
		let locationInScrollView = self.convert(locationInView, to: scrollView)
		return scrollView.menuPartAtLocation(locationInScrollView)
	}
	
	/// Returns the view for the given menu item.
	///
	/// - Parameter menuItem: The menu item to return the view for.
	///
	/// - Returns: The view displaying `menuItem`.
	func viewForMenuItem(_ menuItem: OBWFilteringMenuItem) -> OBWFilteringMenuItemView? {
		return self.scrollView.viewForMenuItem(menuItem)
	}
	
	/// Scrolls the menu content downward with the given acceleration multiplier.
	///
	/// - parameter acceleration: A factor by which to multiply the scroll
	/// distance.
	///
	/// - Returns: `true` if the the scroll view has reached the upper limit,
	/// `false` if not.
	func scrollItemsDownWithAcceleration(_ acceleration: Double) -> Bool {
		return self.scrollView.scrollItemsDownWithAcceleration(acceleration)
	}
	
	/// Scrolls the menu content upward with the given acceleration multiplier.
	///
	/// - parameter acceleration: A factor by which to multiply the scroll
	/// distance.
	///
	/// - Returns: `true` if the the scroll view has reached the lower limit,
	/// `false` if not.
	func scrollItemsUpWithAcceleration(_ acceleration: Double) -> Bool {
		return self.scrollView.scrollItemsUpWithAcceleration(acceleration)
	}
	
	/// Sets the bounds origin of the menu items.
	///
	/// - Parameter boundsOriginY: The new vertical location of the menu item
	/// bounds origin.
	func setMenuItemBoundsOriginY(_ boundsOriginY: CGFloat) {
		self.scrollView.setMenuItemBoundsOriginY(boundsOriginY)
	}
	
	
	// MARK: - Private
	
	/// The filtering menu.
	unowned private let filteringMenu: OBWFilteringMenu
	
	/// The filter text field.
	unowned private let filterField: NSTextField
	
	/// The menu item scroll view.
	unowned private let scrollView: OBWFilteringMenuItemScrollView
	
	/// A filter event generation counter.
	private var lastFilterEventNumber = 0
	
	/// A boolean to indicate whether a cursorUpdate: is currently being
	/// dispatched to the filter field.
	private var dispatchingCursorUpdateToFilterField = false
	
	/// Move the cursor to the filter field and optionally selects the field’s
	/// contents.
	///
	/// - Parameter selectAll: Indicates whether the contents of the text field
	/// should be selected after it receives focus.
	private func moveKeyboardFocusToFilterFieldAndSelectAll(_ selectAll: Bool) {
		self.filteringMenu.highlightedItem = nil
		
		let filterField = self.filterField
		filterField.selectText(nil)
		
		guard let currentEditor = filterField.currentEditor() else {
			return
		}
		
		if selectAll {
			currentEditor.selectAll(nil)
		}
		else {
			let selectionRange = NSRange(location: currentEditor.string.utf8.count, length: 0)
			currentEditor.selectedRange = selectionRange
		}
	}
}


// MARK: -

private extension NSControl.ControlSize {
	/// Returns the height of menu items for standard control sizes.
	var standardMenuHeight: CGFloat {
		switch self {
			case .mini:
				return 15.0
				
			case .small:
				return 19.0
				
			case .regular,
				 .large:
				fallthrough
				
			@unknown default:
				return 22.0
		}
	}
}
