/*===========================================================================
 OBWFilteringMenu+SessionState.swift
 OBWControls
 Copyright (c) 2019 OrderedBytes. All rights reserved.
 ===========================================================================*/

extension OBWFilteringMenu {
    
    /// An enum describing the result of handling an event
    enum SessionState {
        /// The last event was unhandled.
        case unhandled
        /// The run loop will continue handling events.
        case `continue`
        /// The menu session was canceled by a user action without a menu item selection.
        case cancel
        /// The menu session was interrupted by a system event.
        case interrupt
        /// A menu item was selected by the user via a GUI interaction.
        case guiSelection
        /// A menu item was selected by accessibility APIs.
        case accessibleSelection
        /// The highlighted menu item changed.
        case highlight
        /// The contents of the filter field changed.
        case changeFilter
    }
    
}
