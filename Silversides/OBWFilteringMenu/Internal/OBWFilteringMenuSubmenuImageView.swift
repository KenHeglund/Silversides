/*===========================================================================
 OBWFilteringMenuSubmenuImageView.swift
 OBWControls
 Copyright (c) 2019 OrderedBytes. All rights reserved.
 ===========================================================================*/

import AppKit

class OBWFilteringMenuSubmenuImageView: NSImageView {
    
    /// Designated initializer.
    init(_ filteringMenuItem: OBWFilteringMenuItem) {
        
        self.menuItem = filteringMenuItem
        
        super.init(frame: NSRect(size: OBWFilteringMenuSubmenuImageView.size))
        
        self.imageFrameStyle = .none
        self.isEditable = false
    }
    
    /// Required initializer, currently unused.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// The view will be drawn.
    override func viewWillDraw() {
        super.viewWillDraw()
        
        self.isHidden = (self.menuItem.submenu == nil)
        
        if self.menuItem.isHighlighted {
            self.image = OBWFilteringMenuArrows.selectedRightArrow
        }
        else {
            self.image = OBWFilteringMenuArrows.unselectedRightArrow
        }
    }
    
    
    // MARK: - OBWFilteringMenuSubmenuImageView implementation
    
    static let size = NSSize(width: 9.0, height: 10.0)
    
    
    // MARK: - Private
    
    private let menuItem: OBWFilteringMenuItem
}
