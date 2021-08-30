/*===========================================================================
NSEvent+OBWExtension.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

extension NSEvent {
	/// The screen containing the receiver’s location, if any.
	var screen: NSScreen? {
		guard let locationInScreen = self.locationInScreen else {
			return nil
		}
		
		return NSScreen.screens.first(where: {
			NSPointInRect(locationInScreen, $0.frame)
		})
	}
	
	/// The receiver’s location in screen coordinates.
	var locationInScreen: NSPoint? {
		guard NSEvent.isLocationPropertyValid(self.type) else {
			return nil
		}
		
		guard let window = self.window else {
			return self.locationInWindow
		}
		
		let rectInWindow = NSRect(origin: self.locationInWindow, size: .zero)
		let rectInScreen = window.convertToScreen(rectInWindow)
		return rectInScreen.origin
	}
	
	/// Returns the location of the receiver in the given view’s coordinate
	/// system.  Returns `nil` if the view is not in a window or if the event
	/// does not have a valid location.
	///
	/// - Parameter view: The view whose coordinate system to convert the
	/// receiver’s location to.
	///
	/// - Returns: The location of the receiver in `view`’s coordinate system.
	func locationInView(_ view: NSView) -> NSPoint? {
		guard NSEvent.isLocationPropertyValid(self.type) else {
			return nil
		}
		guard let viewWindow = view.window else {
			return nil
		}
		
		let locationInViewWindow: NSPoint
		
		if let eventWindow = self.window {
			if eventWindow == viewWindow {
				locationInViewWindow = self.locationInWindow
			}
			else {
				let rectInEventWindow = NSRect(origin: self.locationInWindow, size: .zero)
				let rectInScreen = eventWindow.convertToScreen(rectInEventWindow)
				let rectInViewWindow = viewWindow.convertFromScreen(rectInScreen)
				
				locationInViewWindow = rectInViewWindow.origin;
			}
		}
		else {
			let rectInScreen = NSRect(origin: self.locationInWindow, size: .zero)
			let rectInWindow = viewWindow.convertFromScreen(rectInScreen)
			
			locationInViewWindow = rectInWindow.origin
		}
		
		return view.convert(locationInViewWindow, from: nil)
	}
	
	/// Returns `true` if the VoiceOver key combination (Control-Option) is
	/// pressed.
	var voiceOverModifiersPressed: Bool {
		let modifierKeyMask: ModifierFlags = [.shift, .control, .option, .command]
		let voiceOverKeyMask: ModifierFlags = [.control, .option]
		let eventModifierFlags = self.modifierFlags
		return (eventModifierFlags.intersection(modifierKeyMask) == voiceOverKeyMask)
	}
	
	/// Indicates whether the `locationInWindow` property is valid for the given
	/// event type.
	///
	/// - Parameter type: An `NSEvent` type.
	///
	/// - Returns: Returns `true` if the `locationInWindow` property is valid
	/// for an event of type `type`.
	private class func isLocationPropertyValid(_ type: NSEvent.EventType) -> Bool {
		switch type {
			case .leftMouseDown,
				 .leftMouseUp,
				 .rightMouseDown,
				 .rightMouseUp,
				 .mouseMoved,
				 .leftMouseDragged,
				 .rightMouseDragged,
				 .scrollWheel,
				 .otherMouseDown,
				 .otherMouseUp,
				 .otherMouseDragged,
				 .cursorUpdate:
				return true
				
			case .mouseEntered,
				 .mouseExited,
				 .keyDown,
				 .keyUp,
				 .flagsChanged,
				 .appKitDefined,
				 .systemDefined,
				 .applicationDefined,
				 .periodic,
				 .tabletPoint,
				 .tabletProximity,
				 .gesture,
				 .magnify,
				 .swipe,
				 .rotate,
				 .beginGesture,
				 .endGesture,
				 .smartMagnify,
				 .quickLook,
				 .pressure,
				 .directTouch,
				 .changeMode:
				return false
				
			@unknown default:
				return false
		}
	}
}
