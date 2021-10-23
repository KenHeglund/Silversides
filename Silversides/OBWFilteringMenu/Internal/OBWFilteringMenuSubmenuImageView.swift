/*===========================================================================
 OBWFilteringMenuSubmenuImageView.swift
 OBWControls
 Copyright (c) 2019 OrderedBytes. All rights reserved.
 ===========================================================================*/

import AppKit

/// A view that displays an image that indicates whether a menu item has a
/// submenu.
class OBWFilteringMenuSubmenuImageView: NSView {
	/// Controls what the image view displays.
	enum DisplayMode {
		/// The view displays an arrow if the menu item has a submenu.
		case arrow
		/// The view displays a spinner if the menu has a submenu.
		case spinner
	}
	
	/// Initialization.
	///
	/// - Parameter filteringMenuItem: The menu item to display a submenu image
	/// for.
	init(_ filteringMenuItem: OBWFilteringMenuItem) {
		let frame = NSRect(size: OBWFilteringMenuSubmenuImageView.size)
		
		self.menuItem = filteringMenuItem
		
		let arrowImageView = NSImageView(frame: frame)
		arrowImageView.image = OBWFilteringMenuArrows.image(for: .trailing)
		arrowImageView.imageFrameStyle = .none
		arrowImageView.isEditable = false
		arrowImageView.isHidden = true
		self.arrowImageView = arrowImageView
		
		let spinner = NSProgressIndicator(frame: frame)
		spinner.usesThreadedAnimation = true
		spinner.isDisplayedWhenStopped = false
		spinner.style = .spinning
		spinner.isHidden = true
		// The appearance of the spinner is always `.darkAqua` because it is only ever visible on a selected menu item.  When a menu item is selected, the submenu arrow is always light/white in color.  The `.darkAqua` appearance will match that color.
		spinner.appearance = NSAppearance(named: .darkAqua)
		self.spinner = spinner
		
		super.init(frame: frame)
		
		self.addSubview(self.arrowImageView)
		self.addSubview(self.spinner)
	}
	
	// Required initializer.
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	/// The view will be drawn.
	override func viewWillDraw() {
		self.updateImage()
		super.viewWillDraw()
	}
	
	
	// MARK: - OBWFilteringMenuSubmenuImageView implementation
	
	/// The default size of the arrow view.
	static let size = NSSize(width: 9.0, height: 10.0)
	
	/// The current display mode.
	var displayMode = DisplayMode.arrow {
		didSet {
			self.startOrStopSpinner()
			self.needsDisplay = true
		}
	}
	
	
	// MARK: - Private
	
	/// The menu item that the submenu image is being displayed for.
	private let menuItem: OBWFilteringMenuItem
	/// An image view that displays an arrow.
	private let arrowImageView: NSImageView
	/// A progress indicator that can be shown to indicate the submenu is being
	/// generated.
	private let spinner: NSProgressIndicator
	
	/// Set up the current image.
	private func updateImage() {
		if self.menuItem.submenu != nil, self.displayMode == .arrow {
			let tintColor: NSColor
			if self.menuItem.isHighlighted {
				tintColor = .selectedMenuItemTextColor
			}
			else {
				tintColor = .labelColor
			}
			self.arrowImageView.contentTintColor = tintColor
			
			if self.arrowImageView.isHidden {
				self.arrowImageView.isHidden = false
			}
		}
		else {
			self.arrowImageView.isHidden = true
		}
	}
	
	/// Start or stop the spinner based on the presence of a submenu and the
	/// current display mode.
	private func startOrStopSpinner() {
		if self.menuItem.submenu != nil, self.displayMode == .spinner {
			if self.spinner.isHidden {
				self.spinner.isHidden = false
			}
			
			self.spinner.startAnimation(nil)
		}
		else {
			self.spinner.stopAnimation(nil)
			self.spinner.isHidden = true
		}
	}
}
