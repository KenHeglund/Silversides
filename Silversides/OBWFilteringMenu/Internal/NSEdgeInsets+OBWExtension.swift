/*===========================================================================
 NSEdgeInsets+OBWExtension.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

extension NSEdgeInsets {
    
    /*==========================================================================*/
    var width: CGFloat {
        return self.left + self.right
    }
    
    /*==========================================================================*/
    var height: CGFloat {
        return self.top + self.bottom
    }
}
