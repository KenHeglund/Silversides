/*===========================================================================
 OBWPathItem+InteractionType.swift
 OBWControls
 Copyright (c) 2019 OrderedBytes. All rights reserved.
 ===========================================================================*/

import AppKit

public extension OBWPathItem {
    
    /// An enum that defines how interaction with a Path Item is initiated.
    enum InteractionType {
        /// Interaction was initiated with a mouse click.
        case gui(NSEvent)
        /// Interaction was initiated via accessibility APIs (e.g. VoiceOver).
        case accessibility
    }

}
