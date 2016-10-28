/*===========================================================================
 OBWFilteringMenuEventSource.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

struct OBWApplicationEventSubtype: OptionSetType {
    
    init( rawValue: Int16 ) {
        self.rawValue = rawValue
    }
    
    var rawValue: Int16
    
    static let ApplicationDidBecomeActive   = OBWApplicationEventSubtype( rawValue: 1 << 0 )
    static let ApplicationDidResignActive   = OBWApplicationEventSubtype( rawValue: 1 << 1 )
    static let Periodic                     = OBWApplicationEventSubtype( rawValue: 1 << 2 )
    static let AccessibleItemSelection      = OBWApplicationEventSubtype( rawValue: 1 << 3 )
}

/*==========================================================================*/
// MARK: -

class OBWFilteringMenuEventSource: NSObject {
    
    /*==========================================================================*/
    deinit {
        
        let previousMask = self.eventMask
        self.eventMask = []
        self.updateObservation( previousMask )
        
        self.eventTimer?.invalidate()
    }
    
    /*==========================================================================*/
    var eventMask: OBWApplicationEventSubtype = [] {
        
        didSet ( oldMask ) {
            self.updateObservation( oldMask )
        }
    }
    
    /*==========================================================================*/
    private func updateObservation( previousMask: OBWApplicationEventSubtype ) {
        
        let activeMask: OBWApplicationEventSubtype = [ .ApplicationDidBecomeActive, .ApplicationDidResignActive ]
        let wasObservingActive = !previousMask.intersect( activeMask ).isEmpty
        let shouldObserveActive = !self.eventMask.intersect( activeMask ).isEmpty
        
        if shouldObserveActive == wasObservingActive {
            return
        }
        
        if shouldObserveActive {
            
            self.currentApplication.addObserver( self, forKeyPath: "active", options: [ .New, .Old ], context: &OBWFilteringMenuEventSource.kvoContext )
        }
        else {
            
            self.currentApplication.removeObserver( self, forKeyPath: "active", context: &OBWFilteringMenuEventSource.kvoContext )
        }
    }
    
    /*==========================================================================*/
    // MARK: - NSKeyValueObserving implementation
    
    override func observeValueForKeyPath( keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void> ) {
        
        guard context == &OBWFilteringMenuEventSource.kvoContext else { return }
        guard keyPath == "active" else { return }
        
        guard let isActive = change?[NSKeyValueChangeNewKey] as? Bool else { return }
        guard let wasActive = change?[NSKeyValueChangeOldKey] as? Bool else { return }
        
        if isActive == wasActive { return }
        
        let cocoaEvent: NSEvent?
        
        if isActive && self.eventMask.contains( .ApplicationDidBecomeActive ) {
            
            cocoaEvent = NSEvent.otherEventWithType(
                .ApplicationDefined,
                location: NSZeroPoint,
                modifierFlags: [],
                timestamp: NSProcessInfo.processInfo().systemUptime,
                windowNumber: 0,
                context: nil,
                subtype: OBWApplicationEventSubtype.ApplicationDidBecomeActive.rawValue,
                data1: 0,
                data2: 0
            )
        }
        else if !isActive && self.eventMask.contains( .ApplicationDidResignActive ) {
            
            cocoaEvent = NSEvent.otherEventWithType(
                .ApplicationDefined,
                location: NSZeroPoint,
                modifierFlags: [],
                timestamp: NSProcessInfo.processInfo().systemUptime,
                windowNumber: 0,
                context: nil,
                subtype: OBWApplicationEventSubtype.ApplicationDidResignActive.rawValue,
                data1: 0,
                data2: 0
            )
        }
        else {
            return
        }
        
        if cocoaEvent != nil {
            NSApp.postEvent( cocoaEvent!, atStart: false )
        }
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuEventSource implementation
    
    func startPeriodicApplicationEventsAfterDelay( delayInSeconds: NSTimeInterval, withPeriod periodInSeconds: NSTimeInterval ) {
        
        if let _ = self.eventTimer {
            self.stopPeriodicApplicationEvents()
        }
        
        let timer = NSTimer(
            timeInterval: periodInSeconds,
            target: self,
            selector: #selector(OBWFilteringMenuEventSource.periodicApplicationEventTimerDidFire(_:)),
            userInfo: nil,
            repeats: true
        )
        
        timer.fireDate = NSDate( timeIntervalSinceNow: delayInSeconds )
        NSRunLoop.currentRunLoop().addTimer( timer, forMode: NSRunLoopCommonModes )
        
        self.eventTimer = timer
        self.eventMask.insert( .Periodic )
    }
    
    /*==========================================================================*/
    func stopPeriodicApplicationEvents() {
        
        self.eventMask.remove( .Periodic )
        
        self.eventTimer?.invalidate()
        self.eventTimer = nil
        
        NSApplication.sharedApplication().discardEventsMatchingMask( NSEventMask.ApplicationDefined, beforeEvent: nil )
    }
    
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuEventSource private
    
    lazy private var currentApplication: NSRunningApplication = NSRunningApplication.currentApplication()
    weak private var eventTimer: NSTimer? = nil
    
    private static var kvoContext = "OBWApplicationObservingContext"
    
    /*==========================================================================*/
    @objc private func periodicApplicationEventTimerDidFire( timer: NSTimer ) {
        
        guard self.eventMask.contains( .Periodic ) else { return }
        
        guard let cocoaEvent = NSEvent.otherEventWithType(
            .ApplicationDefined,
            location: NSZeroPoint,
            modifierFlags: [],
            timestamp: NSProcessInfo.processInfo().systemUptime,
            windowNumber: 0,
            context: nil,
            subtype: OBWApplicationEventSubtype.Periodic.rawValue,
            data1: 0,
            data2: 0
            )
            else { return }
        
        NSApp.postEvent( cocoaEvent, atStart: false )
    }

}
