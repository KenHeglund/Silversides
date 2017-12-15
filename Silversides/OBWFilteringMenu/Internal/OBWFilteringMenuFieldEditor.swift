/*===========================================================================
 OBWFilteringMenuFieldEditor.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

class OBWFilteringMenuFieldEditor: NSTextView {
    
    /*==========================================================================*/
    override init( frame frameRect: NSRect, textContainer container: NSTextContainer? ) {
        super.init( frame: frameRect, textContainer: container )
        self.isFieldEditor = true
    }
    
    /*==========================================================================*/
    required init?( coder: NSCoder ) {
        fatalError( "init(coder:) has not been implemented" )
    }
    
    /*==========================================================================*/
    // MARK: - NSTextView overrides
    
    /*==========================================================================*/
    override func setSelectedRange( _ charRange: NSRange ) {
        
        let automaticSelectionChange = ( RunLoop.current.currentMode != nil )
        
        guard !automaticSelectionChange else { return }
        
        super.setSelectedRange( charRange )
    }
}
