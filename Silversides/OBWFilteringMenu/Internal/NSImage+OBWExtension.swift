/*===========================================================================
NSImage+OBWExtension.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

extension NSImage {
	/// Executes a closure while focus is locked on the receiver.  Focus is
	/// unlocked before returning.
	///
	/// - Parameter handler: The closure to execute while focus is locked on the
	/// receiver.
	func withLockedFocus(_ handler: () -> Void) {
		self.lockFocus()
		handler()
		self.unlockFocus()
	}
	
	/// Returns an image formed by trimming transparent edges from the receiver.
	///
	/// - Returns: Returns the receiver if none of its edges are fully
	/// transparent, `nil` if the receiver is entirely transparent, or a new
	/// image formed by trimming the transparent edges from the receiver.
	func imageByTrimmingTransparentEdges() -> NSImage? {
		let sourceFrame = NSRect(size: self.size)
		
		if self.hitTest(sourceFrame, withDestinationRect: sourceFrame, context: nil, hints: nil, flipped: false) == false {
			return nil
		}
		
		let queue = DispatchQueue.global()
		let group = DispatchGroup()
		var edgeInsets = NSEdgeInsetsZero
		
		// Find top inset
		queue.async(group: group, execute: DispatchWorkItem(block: {
			var testRect = NSRect(x: sourceFrame.minX, y: sourceFrame.maxY - 1.0, width: sourceFrame.width, height: 1.0)
			while edgeInsets.top < sourceFrame.height {
				if self.hitTest(testRect, withDestinationRect: sourceFrame, context: nil, hints: nil, flipped: false) {
					return
				}
				edgeInsets.top += 1.0
				testRect.origin.y -= 1.0
			}
		}))
		
		// Find left inset
		queue.async(group: group, execute: DispatchWorkItem(block: {
			var testRect = NSRect(origin: sourceFrame.origin, width: 1.0, height: sourceFrame.height)
			while edgeInsets.left < sourceFrame.width {
				if self.hitTest(testRect, withDestinationRect: sourceFrame, context: nil, hints: nil, flipped: false) {
					return
				}
				edgeInsets.left += 1.0
				testRect.origin.x += 1.0
			}
		}))
		
		if group.wait(timeout: .now() + .milliseconds(200)) == .timedOut {
			return self
		}
		
		// Find bottom inset
		queue.async(group: group, execute: DispatchWorkItem(block: {
			var testRect = NSRect(x: sourceFrame.minX + edgeInsets.left, y: sourceFrame.minY, width: sourceFrame.width - edgeInsets.left, height: 1.0)
			while edgeInsets.height < sourceFrame.height {
				if self.hitTest(testRect, withDestinationRect: sourceFrame, context: nil, hints: nil, flipped: false) {
					return
				}
				edgeInsets.bottom += 1.0
				testRect.origin.y += 1.0
			}
		}))
		
		// Find right inset
		queue.async(group: group, execute: DispatchWorkItem(block: {
			var testRect = NSRect(x: sourceFrame.maxX - 1.0, y: sourceFrame.minY, width: 1.0, height: sourceFrame.height - edgeInsets.top)
			while edgeInsets.width < sourceFrame.width {
				if self.hitTest(testRect, withDestinationRect: sourceFrame, context: nil, hints: nil, flipped: false) {
					return
				}
				edgeInsets.right += 1.0
				testRect.origin.x -= 1.0
			}
		}))
		
		if group.wait(timeout: .now() + .milliseconds(200)) == .timedOut {
			return self
		}
		
		let contentFrame = sourceFrame + edgeInsets
		if contentFrame == sourceFrame {
			return self
		}
		
		let trimmedImage = NSImage(size: contentFrame.size)
		trimmedImage.withLockedFocus {
			self.draw(at: .zero, from: contentFrame, operation: .copy, fraction: 1.0)
		}
		
		return trimmedImage
	}
}
