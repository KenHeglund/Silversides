//
//  OBWPathView+CompressionPriority.swift
//  OBWControls
//
//  Created by Ken Heglund on 8/13/19.
//  Copyright © 2019 OrderedBytes. All rights reserved.
//

import Foundation

extension OBWPathView {
    
    /// An enum that describes the compression resistance priority of Path Items based on their location within the list of items.
    enum CompressionPriority: Int {
        /// Items in the middle of the list.  Lowest resistance to compression
        case interior = 0
        /// The leading path item.  Second lowest resistance to compression
        case head
        /// The penultimate path item.  Second highest resistance to compression.
        case penultimate
        /// The trailing path item.  Highest resistance to compression.
        case tail
    }
}

extension OBWPathView.CompressionPriority: Comparable {
    
    public static func <(lhs: OBWPathView.CompressionPriority, rhs: OBWPathView.CompressionPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
