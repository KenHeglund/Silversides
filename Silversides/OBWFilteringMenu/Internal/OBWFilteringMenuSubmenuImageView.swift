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
		self.arrowImageView = NSImageView(frame: frame)
		self.spinner = NSProgressIndicator(frame: frame)
		
		super.init(frame: frame)
		
		self.arrowImageView.imageFrameStyle = .none
		self.arrowImageView.isEditable = false
		
		self.spinner.usesThreadedAnimation = true
		self.spinner.isDisplayedWhenStopped = false
		self.spinner.style = .spinning
		
		// This removes the background from the `NSProgressIndicator` ... no idea why or how.
		self.spinner.appearance = NSAppearance(named: .aqua)
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
		if let _ = self.menuItem.submenu, self.displayMode == .arrow {
			if self.menuItem.isHighlighted {
				self.arrowImageView.image = OBWFilteringMenuArrows.selectedRightArrow
			}
			else {
				self.arrowImageView.image = OBWFilteringMenuArrows.unselectedRightArrow
			}
			
			if self.arrowImageView.superview == nil {
				self.addSubview(self.arrowImageView)
			}
		}
		else {
			self.arrowImageView.removeFromSuperview()
		}
	}
	
	/// Start or stop the spinner based on the presence of a submenu and the
	/// current display mode.
	private func startOrStopSpinner() {
		if let _ = self.menuItem.submenu, self.displayMode == .spinner {
			
			if self.spinner.superview == nil {
				self.addSubview(self.spinner)
			}
			
			self.spinner.startAnimation(nil)
		}
		else {
			self.spinner.stopAnimation(nil)
			self.spinner.removeFromSuperview()
		}
	}
}
