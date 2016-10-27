/*===========================================================================
 OBWFilteringMenuFieldEditor.swift
 Silversides
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

class OBWFilteringMenuFieldEditor: NSTextView {
    
    /*==========================================================================*/
    override init( frame frameRect: NSRect, textContainer container: NSTextContainer? ) {
        super.init( frame: frameRect, textContainer: container )
        self.fieldEditor = true
    }
    
    /*==========================================================================*/
    required init?( coder: NSCoder ) {
        super.init( coder: coder )
        self.fieldEditor = true
    }
    
    /*==========================================================================*/
    // MARK: - NSTextView overrides
    
    /*==========================================================================*/
    override func setSelectedRange( charRange: NSRange ) {
        
        let automaticSelectionChange = ( NSRunLoop.currentRunLoop().currentMode != nil )
        
        guard !automaticSelectionChange else { return }
        
        super.setSelectedRange( charRange )
    }
}
