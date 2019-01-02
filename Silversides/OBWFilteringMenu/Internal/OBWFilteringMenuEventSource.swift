/*===========================================================================
 OBWFilteringMenuEventSource.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

struct OBWApplicationEventSubtype: OptionSet {
    
    init(rawValue: Int16) {
        self.rawValue = rawValue
    }
    
    var rawValue: Int16
    
    static let applicationDidBecomeActive   = OBWApplicationEventSubtype(rawValue: 1 << 0)
    static let applicationDidResignActive   = OBWApplicationEventSubtype(rawValue: 1 << 1)
    static let periodic                     = OBWApplicationEventSubtype(rawValue: 1 << 2)
    static let accessibleItemSelection      = OBWApplicationEventSubtype(rawValue: 1 << 3)
}

/*==========================================================================*/
// MARK: -

class OBWFilteringMenuEventSource: NSObject {
    
    /*==========================================================================*/
    deinit {
        
        let previousMask = self.eventMask
        self.eventMask = []
        self.updateObservation(fromPrevious: previousMask)
        
        self.eventTimer?.invalidate()
    }
    
    /*==========================================================================*/
    var eventMask: OBWApplicationEventSubtype = [] {
        
        didSet (oldMask) {
            self.updateObservation(fromPrevious: oldMask)
        }
    }
    
    /*==========================================================================*/
    private func updateObservation(fromPrevious previousMask: OBWApplicationEventSubtype) {
        
        let activeMask: OBWApplicationEventSubtype = [.applicationDidBecomeActive, .applicationDidResignActive]
        let wasObservingActive = previousMask.intersection(activeMask).isEmpty == false
        let shouldObserveActive = self.eventMask.intersection(activeMask).isEmpty == false
        
        if shouldObserveActive == wasObservingActive {
            return
        }
        
        if shouldObserveActive {
            
            self.currentApplication.addObserver(self, forKeyPath: "active", options: [.new, .old], context: &OBWFilteringMenuEventSource.kvoContext)
        }
        else {
            
            self.currentApplication.removeObserver(self, forKeyPath: "active", context: &OBWFilteringMenuEventSource.kvoContext)
        }
    }
    
    /*==========================================================================*/
    // MARK: - NSKeyValueObserving implementation
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard context == &OBWFilteringMenuEventSource.kvoContext else {
            return
        }
        
        guard keyPath == "active" else {
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
        
        let cocoaEvent: NSEvent?
        
        if isActive && self.eventMask.contains(.applicationDidBecomeActive) {
            
            cocoaEvent = NSEvent.otherEvent(
                with: .applicationDefined,
                location: .zero,
                modifierFlags: [],
                timestamp: ProcessInfo().systemUptime,
                windowNumber: 0,
                context: nil,
                subtype: OBWApplicationEventSubtype.applicationDidBecomeActive.rawValue,
                data1: 0,
                data2: 0
            )
        }
        else if isActive == false && self.eventMask.contains(.applicationDidResignActive) {
            
            cocoaEvent = NSEvent.otherEvent(
                with: .applicationDefined,
                location: .zero,
                modifierFlags: [],
                timestamp: ProcessInfo().systemUptime,
                windowNumber: 0,
                context: nil,
                subtype: OBWApplicationEventSubtype.applicationDidResignActive.rawValue,
                data1: 0,
                data2: 0
            )
        }
        else {
            return
        }
        
        if let event = cocoaEvent {
            NSApp.postEvent(event, atStart: false)
        }
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuEventSource implementation
    
    func startPeriodicApplicationEventsAfterDelay(_ delayInSeconds: TimeInterval, withPeriod periodInSeconds: TimeInterval) {
        
        if let _ = self.eventTimer {
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
        self.eventMask.insert(.periodic)
    }
    
    /*==========================================================================*/
    func stopPeriodicApplicationEvents() {
        
        self.eventMask.remove(.periodic)
        
        self.eventTimer?.invalidate()
        self.eventTimer = nil
        
        NSApplication.shared.discardEvents(matching: .applicationDefined, before: nil)
    }
    
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuEventSource private
    
    lazy private var currentApplication = NSRunningApplication.current
    weak private var eventTimer: Timer? = nil
    
    private static var kvoContext = "OBWApplicationObservingContext"
    
    /*==========================================================================*/
    @objc private func periodicApplicationEventTimerDidFire(_ timer: Timer) {
        
        guard self.eventMask.contains(.periodic) else {
            return
        }
        
        guard let cocoaEvent = NSEvent.otherEvent(
            with: .applicationDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: ProcessInfo().systemUptime,
            windowNumber: 0,
            context: nil,
            subtype: OBWApplicationEventSubtype.periodic.rawValue,
            data1: 0,
            data2: 0
            )
        else {
            return
        }
        
        NSApp.postEvent(cocoaEvent, atStart: false)
    }
}
