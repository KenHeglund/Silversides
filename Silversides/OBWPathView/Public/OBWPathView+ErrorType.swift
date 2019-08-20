/*===========================================================================
 OBWPathView+ErrorType.swift
 OBWControls
 Copyright (c) 2019 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Foundation

public extension OBWPathView {
    
    /// An enum that defines the types of Errors that a Path View may throw.
    enum ErrorType: Error {
        /// The given index is not valid for the Path View.
        case invalidIndex(index: Int, endIndex: Int)
        /// endPathItemUpdate() was called too many times on a Path View.
        case imbalancedEndPathItemUpdate
        /// An error internal to OBWPathView.
        case internalConsistency(String)
    }
    
}

