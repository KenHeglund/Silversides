/*===========================================================================
OBWFilteringMenuEventSource.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

/// Coordinates the generation of application-specific events.
class OBWFilteringMenuEventSource: NSObject {
	/// The shared `OBWFilteringMenuEventSource` instance.
	static let shared: OBWFilteringMenuEventSource = {
		return OBWFilteringMenuEventSource()
	}()
	
	/// Clean up resources.
	deinit {
		// Assigning an empty set of active events properly cleans up KVO observations.
		self.activeEvents = []
		self.eventTimer?.invalidate()
	}
	
	
	// MARK: - NSKeyValueObserving
	
	/// Observe a changed value.
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		
		guard
			context == &OBWFilteringMenuEventSource.kvoContext,
			keyPath == "active"
		else {
			return
		}
		
		guard
			let isActive = change?[NSKeyValueChangeKey.newKey] as? Bool,
			let wasActive = change?[NSKeyValueChangeKey.oldKey] as? Bool
		else {
			return
		}
		
		if isActive == wasActive {
			return
		}
		
		if isActive && self.activeEvents.contains(.applicationDidBecomeActive) {
			OBWFilteringMenuEventSubtype.applicationDidBecomeActive.post(atStart: false)
		}
		else if isActive == false && self.activeEvents.contains(.applicationDidResignActive) {
			OBWFilteringMenuEventSubtype.applicationDidResignActive.post(atStart: false)
		}
	}
	
	
	// MARK: - OBWFilteringMenuEventSource
	
	/// Indicates whether `.applicationDidBecomeActive` events should be posted.
	var isApplicationDidBecomeActiveEventEnabled = false {
		didSet {
			if self.isApplicationDidBecomeActiveEventEnabled {
				self.activeEvents.insert(.applicationDidBecomeActive)
			}
			else {
				self.activeEvents.remove(.applicationDidBecomeActive)
			}
		}
	}
	
	/// Indicates whether `.applicationDidResignActive` events should be posted.
	var isApplicationDidResignActiveEventEnabled = false {
		didSet {
			if self.isApplicationDidResignActiveEventEnabled {
				self.activeEvents.insert(.applicationDidResignActive)
			}
			else {
				self.activeEvents.remove(.applicationDidResignActive)
			}
		}
	}
	
	/// Start periodic application events.  If periodic events are already being
	/// posted, the new period replaces the old.
	///
	/// - Parameters:
	///   - delayInSeconds: The delay before the first event is posted.
	///   - periodInSeconds: The interval between succesive events.
	func startPeriodicApplicationEvents(afterDelay delayInSeconds: TimeInterval, withPeriod periodInSeconds: TimeInterval) {
		if self.activeEvents.contains(.periodic) {
			self.stopPeriodicApplicationEvents()
		}
		
		let timer = Timer(
			timeInterval: periodInSeconds,
			target: self,
			selector: #selector(OBWFilteringMenuEventSource.periodicApplicationEventTimerDidFire(_:)),
			userInfo: nil,
			repeats: true
		)
		
		timer.fireDate = Date(timeIntervalSinceNow: delayInSeconds)
		RunLoop.current.add(timer, forMode: .common)
		
		self.eventTimer = timer
		self.activeEvents.insert(.periodic)
	}
	
	/// Stop periodic application events.
	func stopPeriodicApplicationEvents() {
		self.activeEvents.remove(.periodic)
		self.eventTimer?.invalidate()
		self.eventTimer = nil
		
		NSApplication.shared.discardEvents(matching: .applicationDefined, before: nil)
	}
	
	
	// MARK: - Private
	
	/// An `NSRunningApplication` instance representing the current application.
	/// This is stored in a property to retain the instance, it is not a
	/// persistent singleton.
	lazy private var currentApplication = NSRunningApplication.current
	
	/// The current periodic event timer, if any.
	weak private var eventTimer: Timer?
	
	/// A unique context object for KVO observations.
	private static var kvoContext = "OBWApplicationObservingContext"
	
	/// The currently active events.
	private var activeEvents: Set<OBWFilteringMenuEventSubtype> = [] {
		willSet {
			self.removeApplicationActiveObservation(for: self.activeEvents)
		}
		didSet {
			self.addApplicationActiveObservation(for: self.activeEvents)
		}
	}
	
	/// The periodic event timer fired.
	///
	/// - Parameter timer: The timer that fired.
	@objc private func periodicApplicationEventTimerDidFire(_ timer: Timer) {
		guard self.activeEvents.contains(.periodic) else {
			return
		}
		
		OBWFilteringMenuEventSubtype.periodic.post(atStart: false)
	}
	
	/// Add an observation of `NSRunningApplication.active` if the given event
	/// subtypes require it.
	///
	/// - Parameter activeEventSubtypes: The subtypes to consider to determine
	/// whether adding an observation of `NSRunningApplication.active` is
	/// necessary.
	private func addApplicationActiveObservation(for activeEventSubtypes: Set<OBWFilteringMenuEventSubtype>) {
		let becomeActive = activeEventSubtypes.contains(.applicationDidBecomeActive)
		let resignActive = activeEventSubtypes.contains(.applicationDidResignActive)
		
		if becomeActive || resignActive {
			self.currentApplication.addObserver(self, forKeyPath: "active", options: [.new, .old], context: &OBWFilteringMenuEventSource.kvoContext)
		}
	}
	
	/// Remove an observation of `NSRunningApplication.active` if the given
	/// event subtypes required it.
	///
	/// - Parameter activeEventSubtypes: The subtypes to consider to determine
	/// whether removing an observation of `NSRunningApplication.active` is
	/// necessary.
	private func removeApplicationActiveObservation(for activeEventSubtypes: Set<OBWFilteringMenuEventSubtype>) {
		let becomeActive = activeEventSubtypes.contains(.applicationDidBecomeActive)
		let resignActive = activeEventSubtypes.contains(.applicationDidResignActive)
		
		if becomeActive || resignActive {
			self.currentApplication.removeObserver(self, forKeyPath: "active", context: &OBWFilteringMenuEventSource.kvoContext)
		}
	}
}
