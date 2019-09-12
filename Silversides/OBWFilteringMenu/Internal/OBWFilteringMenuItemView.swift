/*===========================================================================
 OBWFilteringMenuItemView.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit

/// A view that displays a menu item.
class OBWFilteringMenuItemView: NSView {
    
    /// Initialize a menu item view with a menu item.
    init(menuItem: OBWFilteringMenuItem) {
        
        self.menuItem = menuItem
        self.alternateViews = menuItem.alternates.mapValues(OBWFilteringMenuItemView.makeViewWithMenuItem)
        
        let placeholderFrame = NSRect(width: OBWFilteringMenuItemView.minimumWidth, height: 10.0)
        super.init(frame: placeholderFrame)
        
        self.autoresizingMask = .width
    }
    
    /// Required initializer, currently unused.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - OBWFilteringMenuItemView implementation
    
    /// The minimum width that the view will occupy.
    static let minimumWidth: CGFloat = 100.0
    
    /// The view's menu item.
    let menuItem: OBWFilteringMenuItem
    
    /// The view's alternate menu item views.
    let alternateViews: [OBWFilteringMenuItem.AlternateKey:OBWFilteringMenuItemView]
    
    /// The current view's current filter status, if any.
    private(set) var filterStatus: OBWFilteringMenuItemFilterStatus? = nil
    
    /// The preferred size of the view to display its contents.
    var preferredSize: NSSize {
        fatalError("This must be overridden.")
    }
    
    /// Creates a OBWFilteringMenuItemView for the given menu item.
    class func makeViewWithMenuItem(_ menuItem: OBWFilteringMenuItem) -> OBWFilteringMenuItemView {
        
        if menuItem.isSeparatorItem {
            return OBWFilteringMenuSeparatorItemView(menuItem: menuItem)
        }
        
        return OBWFilteringMenuActionItemView(menuItem: menuItem)
    }
    
    /// Applies the given status to the receiver and its alternate views.
    func applyFilterStatus(_ status: OBWFilteringMenuItemFilterStatus) {
        
        self.filterStatus = status
        
        guard let alternateStatus = status.alternateStatus else {
            return
        }
        
        for (key, view) in self.alternateViews {
            view.filterStatus = alternateStatus[key]
        }
    }
    
}
