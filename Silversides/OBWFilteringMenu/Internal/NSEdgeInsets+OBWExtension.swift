/*===========================================================================
 NSEdgeInsets+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit

extension NSEdgeInsets {
    
    /// The sum of the left and right inset distances.
    var width: CGFloat {
        return self.left + self.right
    }
    
    /// The sum of the top and bottom inset distances.
    var height: CGFloat {
        return self.top + self.bottom
    }
    
}
