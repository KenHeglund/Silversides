/*===========================================================================
OBWPathItemView.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

/// A view class that displays a Path Item.
class OBWPathItemView: NSView {
	/// Initialization.
	///
	/// - Parameter frameRect: The frame of the view.
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		self.commonInitialization()
	}
	
	/// Initialization.
	///
	/// - Parameter coder: A coder to decode the view from.
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.commonInitialization()
	}
	
	/// Additional common initialization
	private func commonInitialization() {
		self.currentWidth = self.bounds.width
		self.idleWidth = self.currentWidth
		self.preferredWidth = self.currentWidth
		
		self.addSubview(self.imageView)
		self.addSubview(self.titleField)
		self.addSubview(self.dividerView)
		
		self.autoresizingMask = []
		self.layerContentsRedrawPolicy = .duringViewResize
	}
	
	enum Localizable: CaseLocalizable {
		/// PathItemView accessibility role description.
		case roleDescriptionFormat
	}
	
	
	// MARK: - NSResponder overrides
	
	/// Responds to a `mouseDown` event in the view.
	///
	/// - Parameter theEvent: The current event.
	override func mouseDown(with theEvent: NSEvent) {
		guard
			let pathView = self.superview as? OBWPathView,
			pathView.enabled
		else {
			return
		}
		
		self.displayItemMenu(.gui(theEvent))
	}
	
	
	// MARK: - NSView overrides
	
	/// The view moved to a new window.  Update the title field.
	override func viewDidMoveToWindow() {
		super.viewDidMoveToWindow()
		
		self.updateTitleFieldContents()
		
		self.needsDisplay = true
		
		if self.recalculateWidths() {
			self.needsLayout = true
		}
	}
	
	/// Returns the distance from the top of the item view to the title field’s
	/// baseline.
	override var firstBaselineOffsetFromTop: CGFloat {
		return self.titleField.firstBaselineOffsetFromTop + (self.bounds.maxY - self.titleField.frame.maxY)
	}
	
	/// Resize the receiver’s subviews.
	///
	/// - Parameter oldSize: The old size of the receiver.
	override func resizeSubviews(withOldSize oldSize: NSSize) {
		let itemViewBounds = self.bounds
		var titleMargins = OBWPathItemView.titleMargins
		let imageMargins = OBWPathItemView.imageMargins
		let dividerMargins = OBWPathItemView.dividerMargins
		
		let imageView = self.imageView
		
		let imageHeight = itemViewBounds.size.height - imageMargins.height
		
		let imageFrame: NSRect
		switch NSApp.userInterfaceLayoutDirection {
			case .rightToLeft:
				imageFrame = NSRect(
					x: itemViewBounds.maxX - imageMargins.leading - imageHeight,
					y: itemViewBounds.minY + imageMargins.bottom,
					width: imageHeight,
					height: imageHeight
				)
				
			case .leftToRight:
				fallthrough
			@unknown default:
				imageFrame = NSRect(
					x: itemViewBounds.minX + imageMargins.leading,
					y: itemViewBounds.minY + imageMargins.bottom,
					width: imageHeight,
					height: imageHeight
				)
		}
		
		imageView.frame = imageFrame
		
		if imageView.isHidden == false {
			titleMargins.leading = imageMargins.leading + imageFrame.width + max(imageMargins.trailing, titleMargins.leading)
		}
		
		let dividerView = self.dividerView
		let dividerImageSize = dividerView.image?.size ?? NSSize.zero
		
		var dividerFrame: NSRect
		switch NSApp.userInterfaceLayoutDirection {
			case .rightToLeft:
				dividerFrame = NSRect(
					x: itemViewBounds.minX + dividerMargins.trailing,
					y: ((itemViewBounds.height - dividerImageSize.height) / 2.0).rounded(.down),
					width: dividerImageSize.width,
					height: dividerImageSize.height
				)
				
			case .leftToRight:
				fallthrough
			@unknown default:
				dividerFrame = NSRect(
					x: itemViewBounds.maxX - dividerMargins.trailing - dividerImageSize.width,
					y: ((itemViewBounds.height - dividerImageSize.height) / 2.0).rounded(.down),
					width: dividerImageSize.width,
					height: dividerImageSize.height
				)
		}
		
		let leadingDividerOriginX: CGFloat
		switch NSApp.userInterfaceLayoutDirection {
			case .rightToLeft:
				leadingDividerOriginX = itemViewBounds.maxX - self.minimumWidth + dividerMargins.trailing
				dividerFrame.origin.x = min(dividerFrame.minX, leadingDividerOriginX)
				
			case .leftToRight:
				fallthrough
			@unknown default:
				leadingDividerOriginX = itemViewBounds.minX + self.minimumWidth - (dividerMargins.trailing + dividerImageSize.width)
				dividerFrame.origin.x = max(dividerFrame.minX, leadingDividerOriginX)
		}
		
		dividerView.frame = dividerFrame
		
		if dividerView.isHidden == false {
			titleMargins.trailing = dividerMargins.trailing + dividerFrame.width + min(dividerMargins.leading, titleMargins.trailing)
		}
		
		let titleField = self.titleField
		
		// This is the distance from the top of the ESCPathItemView to the desired text baseline.
		let desiredDistanceFromTopOfViewToTitleBaseline: CGFloat = 16.0
		
		var titleFrame = NSRect(
			x: itemViewBounds.minX + titleMargins.left,
			y: itemViewBounds.minY,
			width: itemViewBounds.width - titleMargins.width,
			height: itemViewBounds.height - desiredDistanceFromTopOfViewToTitleBaseline + self.titleField.firstBaselineOffsetFromTop
		)
		
		OBWPathItemView.offscreenTextField.attributedStringValue = titleField.attributedStringValue
		OBWPathItemView.offscreenTextField.sizeToFit()
		let fieldHeight = OBWPathItemView.offscreenTextField.frame.height
		titleFrame.origin.y = titleFrame.height - fieldHeight
		titleFrame.size.height = fieldHeight
		
		titleField.frame = titleFrame
	}
	
	
	// MARK: - NSAccessibility implementation
	
	/// Indicates whether the receiver is an accessible element.
	///
	/// - Returns: `true` if the view is accessible, `false` if not.
	override func isAccessibilityElement() -> Bool {
		return self.pathItem?.accessible ?? false
	}
	
	/// Returns the accessibility role of the receiver.
	///
	/// - Returns: `NSAccessibility.Role.popUpButton`
	override func accessibilityRole() -> NSAccessibility.Role? {
		return NSAccessibility.Role.popUpButton
	}
	
	/// Returns a description of the receiver’s accessibility role.
	///
	/// - Returns: The description of pop-up button.
	override func accessibilityRoleDescription() -> String? {
		guard let standardDescription = NSAccessibility.Role.popUpButton.description(with: nil) else {
			return nil
		}
		
		let descriptionFormat = Localizable.roleDescriptionFormat.localized
		return String.localizedStringWithFormat(descriptionFormat, standardDescription)
	}
	
	/// Returns the accessibile children of the receiver.
	///
	/// - Returns: `nil`
	override func accessibilityChildren() -> [Any]? {
		return nil
	}
	
	/// Returns whether accessibility is current enabled for the receiver.
	///
	/// - Returns: `true` if the Path View is enabled, `false` if not.
	override func isAccessibilityEnabled() -> Bool {
		guard let pathView = self.superview as? OBWPathView else {
			return false
		}
		
		return pathView.enabled
	}
	
	/// Returns the accessibility value of the receiver.
	///
	/// - Returns: The title of the view.
	override func accessibilityValue() -> Any? {
		return self.pathItem?.title
	}
	
	/// Returns accessibility help text for the receiver.
	///
	/// - Returns: A description of how to use the path item.
	override func accessibilityHelp() -> String? {
		guard
			let pathView = self.superview as? OBWPathView,
			let pathItem = self.pathItem
		else {
			return nil
		}
		
		return pathView.delegate?.pathView(pathView, accessibilityHelpForItem: pathItem)
	}
	
	/// Responds to the user activating the view via accessibility.
	override func accessibilityPerformPress() -> Bool {
		self.displayItemMenu(.accessibility)
		return true
	}
	
	/// Responds to the user showing the view’s menu via accessibility.
	override func accessibilityPerformShowMenu() -> Bool {
		self.displayItemMenu(.accessibility)
		return true
	}
	
	
	// MARK: - OBWPathItemView implementation
	
	/// When `true`, the item view is required to be at its preferred width.
	var preferredWidthRequired = false
	
	/// The current width of the item view.
	var currentWidth: CGFloat = 0.0
	
	/// The width the item view will be when it is not under the cursor.
	var idleWidth: CGFloat = 0.0
	
	
	// MARK: - Private
	
	/// The preferred width of the item view is wide enough to show the entire
	/// title without compressing the font.
	private(set) var preferredWidth: CGFloat = 0.0
	
	/// The minimum width the item view is allowed to be.
	private(set) var minimumWidth: CGFloat = 20.0
	
	/// The Path Item that the view is displaying.
	var pathItem: OBWPathItem? = nil {
		didSet {
			self.updateTitleFieldContents()
			
			self.imageView.image = self.pathItem?.image ?? nil
			self.imageView.isHidden = (self.imageView.image == nil)
			
			self.needsDisplay = true
			
			if self.recalculateWidths() {
				self.needsLayout = true
			}
		}
	}
	
	/// Indicates whether the inter-item separator is currently hidden.
	var dividerHidden: Bool {
		get {
			return self.dividerView.isHidden
		}
		set {
			if self.dividerView.isHidden == newValue {
				return
			}
			
			self.dividerView.isHidden = newValue
			
			if self.recalculateWidths() {
				self.needsLayout = true
			}
		}
	}
	
	/// Display the item’s menu.
	///
	/// - Parameter interaction: The type of interaction that the user will have
	/// with the menu.
	func displayItemMenu(_ interaction: OBWPathItem.InteractionType) {
		guard
			let pathView = self.superview as? OBWPathView,
			let hitPathItem = self.pathItem,
			let delegate = pathView.delegate
		else {
			return
		}
		
		// OBWFilteringMenu
		if let filteringMenu = delegate.pathView(pathView, filteringMenuForItem: hitPathItem, interaction: interaction) {
			let menuItem: OBWFilteringMenuItem?
			let alignment: OBWFilteringMenuItem.Alignment
			let itemLocation: NSPoint
			
			if let hitItem = filteringMenu.itemWithTitle(hitPathItem.title) {
				menuItem = hitItem
				alignment = .baseline
				itemLocation = NSPoint(
					x: self.bounds.leadingX ->> self.imageView.frame.width ->> OBWPathItemView.imageMargins.trailing,
					y: self.bounds.maxY - self.firstBaselineOffsetFromTop
				)
			}
			else {
				menuItem = nil
				alignment = .topLeft
				itemLocation = NSPoint(x: self.bounds.leadingX, y: self.bounds.maxY)
			}
			
			let event: NSEvent?
			let highlightTarget: OBWFilteringMenu.HighlightTarget
			
			switch interaction {
				case .gui(let triggerEvent):
					event = triggerEvent
					highlightTarget = .underCursor
					
				case .accessibility:
					event = nil
					highlightTarget = .none
			}
			
			filteringMenu.popUpMenuPositioningItem(menuItem, aligning: alignment, atPoint: itemLocation, inView: self, matchingWidth: false, withEvent: event, highlighting: highlightTarget)
		}
		
		// NSMenu
		else if let menu = delegate.pathView(pathView, menuForItem: hitPathItem, interaction: interaction) {
			let menuItem = menu.item(withTitle: hitPathItem.title)
			
			let minorVersion = ProcessInfo().operatingSystemVersion.minorVersion
			let menuItemLocationOffsets: NSSize
			
			if minorVersion <= 10 {
				// These offsets are based on the geometry of a standard NSMenu and were determined experimentally on Mac OS X 10.10
				menuItemLocationOffsets = NSSize(width: -17.0, height: 1.0)
			}
			else {
				// These offsets are based on the geometry of a standard NSMenu and were determined experimentally on Mac OS X 10.11
				menuItemLocationOffsets = NSSize(width: -16.0, height: 2.0)
			}
			
			let itemLocation = NSPoint(
				x: self.bounds.minX + menuItemLocationOffsets.width,
				y: self.bounds.minY + self.bounds.height - menuItemLocationOffsets.height
			)
			
			menu.popUp(positioning: menuItem, at: itemLocation, in: self)
		}
	}
	
	/// Updates the view’s visual state based on a state change in the Path View.
	func pathViewAppearanceChanged() {
		guard let pathView = self.superview as? OBWPathView else {
			return
		}
		
		let activeAppearance = (pathView.enabled && pathView.active)
		let imageAlpha = (activeAppearance ? 1.0 : OBWPathItemView.disabledViewAlpha)
		
		self.imageView.alphaValue = imageAlpha
		self.dividerView.alphaValue = imageAlpha
		self.updateTitleFieldContents()
		self.needsDisplay = true
	}
	
	
	// MARK: - OBWPathItemView internal
	
	/// An offscreen text field used to measure text.
	private static let offscreenTextField = NSTextField(frame: .zero)
	
	/// View to display the item’s image.
	private let imageView: NSImageView = {
		let itemImageView = NSImageView(frame: .zero)
		itemImageView.autoresizingMask = []
		itemImageView.isHidden = true
		itemImageView.cell?.setAccessibilityElement(false)
		
		return itemImageView
	}()
	
	/// View to display the item’s title.
	private let titleField: NSTextField = {
		let titleField = NSTextField(frame: .zero)
		titleField.cell?.setAccessibilityElement(false)
		titleField.cell?.lineBreakMode = .byTruncatingTail
		titleField.autoresizingMask = []
		titleField.isEditable = false
		titleField.isSelectable = false
		titleField.isBezeled = false
		titleField.drawsBackground = false
		
		return titleField
	}()
	
	/// View to display a divider between this item and the item to its right.
	private let dividerView: NSImageView = {
		let dividerImage = OBWPathItemView.dividerImage
		
		let frame = NSRect(size: dividerImage.size)
		
		let dividerImageView = NSImageView(frame: frame)
		dividerImageView.cell?.setAccessibilityElement(false)
		dividerImageView.image = dividerImage
		dividerImageView.autoresizingMask = .maxXMargin
		dividerImageView.isHidden = true
		
		return dividerImageView
	}()
	
	/// The base font size used to draw path item titles.
	private static var titleFontSize: CGFloat {
		NSFont.systemFontSize(for: .small)
	}
	
	/// Alpha used to give view contents a “disabled” look.
	private static let disabledViewAlpha: CGFloat = 0.5
	
	/// Margins around the image view.
	private static var imageMargins = NSEdgeInsets(top: 5.0, leading: 4.0, bottom: 4.0, trailing: 2.0)
	
	/// Margins around the title text field.
	private static var titleMargins = NSEdgeInsets(top: 4.0, leading: 2.0, bottom: 4.0, trailing: 2.0)
	
	/// Margins around the divider view.
	private static var dividerMargins = NSEdgeInsets(top: 0.0, leading: 3.0, bottom: 0.0, trailing: 2.0)
	
	/// Minimum width of the title view.
	private static let minimumTitleWidthWithoutImage: CGFloat = 20.0
	
	/// The image to be used as a horizontal divider between adjacent path items.
	private static var dividerImage: NSImage = {
		// All scalar values were determined experimentally.
		let attributes: [NSAttributedString.Key: Any] = [
			.paragraphStyle : NSParagraphStyle.default,
			.font : NSFont.controlContentFont(ofSize: OBWPathItemView.titleFontSize + 6.0),
			.foregroundColor : NSColor(white: 0.55, alpha: 1.0),
		]
		
		let string = "⟩" as NSString // \xE2\x9F\xA9 - This character reverses in an RTL layout direction.
		let stringBounds = string.boundingRect(with: .zero, options: [], attributes: attributes)
		
		let sourceFrame = NSRect(
			width: stringBounds.width.rounded(.up),
			height: stringBounds.height.rounded(.up)
		)
		
		let sourceImage = NSImage(size: sourceFrame.size)
		sourceImage.withLockedFocus {
			string.draw(at: .zero, withAttributes: attributes)
		}
		
		return sourceImage.imageByTrimmingTransparentEdges() ?? sourceImage
	}()
	
	/// Builds the font to be used to draw the item’s title.
	///
	/// - Parameter style: An `OBWPathItemStyle` containing the item’s title
	/// style.
	///
	/// - Returns: A newly created `NSFont`.
	private class func titleFontForPathItemStyle(_ style: OBWPathItemStyle) -> NSFont {
		var displayFont = NSFont.controlContentFont(ofSize: OBWPathItemView.titleFontSize)
		
		if style.contains(.italic) {
			displayFont = NSFontManager.shared.convert(displayFont, toHaveTrait: .italicFontMask)
		}
		if style.contains(.bold) {
			displayFont = NSFontManager.shared.convert(displayFont, toHaveTrait: .boldFontMask)
		}
		
		return displayFont
	}
	
	/// Update the title field’s contents based on the current title string and
	/// Path View state.
	private func updateTitleFieldContents() {
		guard let title = self.pathItem?.title else {
			self.titleField.stringValue = ""
			return
		}
		
		guard
			let pathItem = self.pathItem,
			let pathView = self.superview as? OBWPathView
		else {
			return
		}
		
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.setParagraphStyle(.default)
		paragraphStyle.lineBreakMode = .byTruncatingTail
		
		let displayFont = OBWPathItemView.titleFontForPathItemStyle(pathItem.style)
		
		let displayInActiveState = (pathView.active && pathView.enabled)
		let titleColor: NSColor
		
		if let styleTitleColor = pathItem.textColor {
			
			if displayInActiveState {
				titleColor = styleTitleColor
			}
			else {
				titleColor = styleTitleColor.withAlphaComponent(styleTitleColor.alphaComponent * OBWPathItemView.disabledViewAlpha)
			}
		}
		else if displayInActiveState {
			titleColor = .controlTextColor
		}
		else {
			titleColor = .disabledControlTextColor
		}
		
		let attributes: [NSAttributedString.Key: Any] = [
			.paragraphStyle : paragraphStyle,
			.font : displayFont,
			.foregroundColor : titleColor,
		]
		
		self.titleField.attributedStringValue = NSAttributedString(string: title, attributes: attributes)
	}
	
	/// Recalculates the minimum and preferred widths of the item view.
	/// 
	/// - Returns: `true` if the preferred width or minimum width changed,
	/// otherwise `false`.
	private func recalculateWidths() -> Bool {
		var titleMargins = OBWPathItemView.titleMargins
		var titleMinimumWidth = OBWPathItemView.minimumTitleWidthWithoutImage
		
		let imageView = self.imageView
		
		if imageView.isHidden == false {
			let imageFrameWidth = self.bounds.height - OBWPathItemView.imageMargins.height
			titleMargins.leading = OBWPathItemView.imageMargins.leading + imageFrameWidth + max(OBWPathItemView.imageMargins.trailing, OBWPathItemView.titleMargins.leading)
			titleMinimumWidth = 0.0
		}
		
		let dividerView = self.dividerView
		
		if dividerView.isHidden == false {
			guard let dividerImage = dividerView.image else {
				assertionFailure()
				return false
			}
			
			let dividerImageSize = dividerImage.size
			
			titleMargins.trailing = OBWPathItemView.dividerMargins.trailing + dividerImageSize.width + min(OBWPathItemView.dividerMargins.leading, OBWPathItemView.titleMargins.trailing)
		}
		
		let currentMinimumWidth = self.minimumWidth
		let newMinimumWidth = titleMargins.width + titleMinimumWidth
		
		let currentPreferredWidth = self.preferredWidth
		var newPreferredWidth = newMinimumWidth
		
		if let cell = self.titleField.cell, let pathItem = self.pathItem {
			if pathItem.title.isEmpty == false {
				let titlePreferredWidth = ceil(cell.cellSize.width)
				newPreferredWidth = (titleMargins.left + max(titlePreferredWidth, titleMinimumWidth) + titleMargins.right)
			}
		}
		
		self.preferredWidth = newPreferredWidth
		self.minimumWidth = newMinimumWidth
		
		return (currentPreferredWidth != newPreferredWidth || currentMinimumWidth != newMinimumWidth)
	}
}
