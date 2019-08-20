/*===========================================================================
 OBWFilteringMenuDebugView.swift
 Silversides
 Copyright (c) 2019 OrderedBytes. All rights reserved.
 ===========================================================================*/

import AppKit

typealias DrawingHandler = (NSView) -> Void

/// A window for debug drawing over the screen contents.
class OBWFilteringMenuDebugView: NSView {
    
    /// Invoke the drawing handlers.
    override func draw(_ dirtyRect: NSRect) {
        
        NSColor.clear.set()
        self.bounds.fill()
        
        for (_, handler) in self.drawingHandlers {
            handler(self)
        }
    }
    
    
    // MARK: - OBWFilteringMenuDebugView Interface
    
    /// Add a new drawing handler.
    @discardableResult
    func addDrawingHandler(_ handler: @escaping DrawingHandler) -> UUID {
        let uuid = UUID()
        self.drawingHandlers[uuid] = handler
        self.needsDisplay = true
        print("add: \(self.drawingHandlers.keys)")
        return uuid
    }
    
    /// Remove an existing drawing handler.
    func removeDrawingHandler(withIdentifier identifier: UUID) {
        self.drawingHandlers[identifier] = nil
        self.needsDisplay = true
        print("remove: \(self.drawingHandlers.keys)")
    }
    
    /// Remove all drawing handlers
    func removeAllDrawingHandlers() {
        self.drawingHandlers = [:]
        self.needsDisplay = true
        print("removeAll: \(self.drawingHandlers.keys)")
    }
    
    
    // MARK: - Private
    
    private var drawingHandlers: [UUID:DrawingHandler] = [:]
}
