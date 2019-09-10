/*===========================================================================
 OBWFilteringMenuEventSubtype.swift
 OBWControls
 Copyright (c) 2019 OrderedBytes. All rights reserved.
 ===========================================================================*/

import AppKit

/// Application-specific NSEvent subtypes.
enum OBWFilteringMenuEventSubtype: Int16, CaseIterable {
    
    /// The current application has become the foreground application.
    case applicationDidBecomeActive = 1
    /// The current application has become a background application.
    case applicationDidResignActive
    /// An event generated on a specific interval.
    case periodic
    /// An accessible item was selected.
    case accessibleItemSelection
    /// A menu has an asynchronous update available
    case asyncMenuUpdate
    
    /// Initialize an instance from an NSEvent.
    init?(_ event: NSEvent) {
        
        guard let matchingCase = OBWFilteringMenuEventSubtype.allCases.first(where: { $0.rawValue == event.subtype.rawValue }) else {
            return nil
        }
        
        self = matchingCase
    }
}

extension OBWFilteringMenuEventSubtype {
    
    /// Post a generic application-specific event with the receiver's subtype.
    func post(atStart: Bool) {
        
        guard let event = NSEvent.otherEvent(
            with: .applicationDefined,
            location: NSZeroPoint,
            modifierFlags: [],
            timestamp: ProcessInfo().systemUptime,
            windowNumber: 0,
            context: nil,
            subtype: self.rawValue,
            data1: 0,
            data2: 0
        ) else {
            assertionFailure("Failed to create an application-specific event")
            return
        }
        
        NSApp.postEvent(event, atStart: atStart)
    }
    
}
