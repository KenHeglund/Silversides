/*===========================================================================
 OBWFilteringPopUpButtonCell.swift
 Silversides
 Copyright (c) 2018 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit

/// An NSPopUpButtonCell subclass that displays an OBWFilteringMenu when clicked.
public class OBWFilteringPopUpButtonCell: NSPopUpButtonCell {
    
    // MARK: - NSPopUpButtonCell overrides
    
    /// Display the associated filtering menu and begin tracking the cursor.
    public override func trackMouse(with event: NSEvent, in cellFrame: NSRect, of controlView: NSView, untilMouseUp flag: Bool) -> Bool {
        
        guard let menu = self.filteringMenu else {
            return false
        }
        
        // As of macOS 10.14 (at least -- maybe they've always been), control view coordinates are flipped.
        assert(controlView.isFlipped, "`controlView` coordinates are not flipped, probably want to check baseline calculations.")
        
        let controlSize = self.controlSize
        let fontSize = NSFont.systemFontSize(for: controlSize)
        menu.font = NSFont.menuFont(ofSize: fontSize)
        
        let menuItem = self.visibleFilteringItem
        
        menu.itemArray.forEach({ $0.state = ($0 === menuItem ? .on : .off) })
        
        // These offsets were determined experimentally on macOS 10.14.
        let horizontalOffset: CGFloat
        switch controlSize {
        case .mini:
            horizontalOffset = -11.0
        case .small:
            horizontalOffset = -13.0
        case .regular:
            fallthrough
        @unknown default:
            horizontalOffset = -12.0
        }
        
        let alignmentFrame = controlView.alignmentRect(forFrame: controlView.frame)
        let alignmentBounds = controlView.convert(alignmentFrame, from: controlView.superview)
        let baselineOffset = controlView.firstBaselineOffsetFromTop
        let baselineOrigin = NSPoint(
            x: alignmentBounds.minX + horizontalOffset,
            y: (controlView.isFlipped ? alignmentBounds.minY + baselineOffset : alignmentBounds.maxY - baselineOffset)
        )

        #if DEBUG_MENU_ITEM_BASELINE
        _ = OBWFilteringMenuDebugWindow.shared
        #endif
        
        OBWFilteringMenuDebugWindow.addDrawingHandler({
            [weak controlView]
            debugView in
            
            guard let localView = controlView else {
                return
            }
            
            let convertRectFromLocalToDraw: (NSRect) -> NSRect = {
                rectInSourceView in
                
                let inLocalWindow = localView.convert(rectInSourceView, to: nil)
                let inScreen = localView.window!.convertToScreen(inLocalWindow)
                let inDestWindow = debugView.window!.convertFromScreen(inScreen)
                let inDestView = debugView.convert(inDestWindow, from: nil)
                return inDestView
            }
            
            let convertPointFromLocalToDraw: (NSPoint) -> NSPoint = {
                pointInSourceView in
                
                let inLocalWindow = localView.convert(pointInSourceView, to: nil)
                let inScreen = localView.window!.convertPoint(toScreen: inLocalWindow)
                let inDestWindow = debugView.window!.convertPoint(fromScreen: inScreen)
                let inDestView = debugView.convert(inDestWindow, from: nil)
                return inDestView
            }
            
            NSColor.systemRed.withAlphaComponent(0.5).set()
            let controlBoundsInDestView = convertRectFromLocalToDraw(localView.bounds)
            controlBoundsInDestView.frame()
            
            NSColor.systemBlue.withAlphaComponent(0.5).set()
            let layoutFrameInLocalView = localView.convert(alignmentBounds, from: localView)
            let layoutBoundsInDestView = convertRectFromLocalToDraw(layoutFrameInLocalView)
            layoutBoundsInDestView.frame()
            
            let baselineInDestView = convertPointFromLocalToDraw(baselineOrigin)
            let path = NSBezierPath()
            path.move(to: NSPoint(x: layoutBoundsInDestView.minX, y: baselineInDestView.y))
            path.line(to: NSPoint(x: layoutBoundsInDestView.maxX, y: baselineInDestView.y))
            path.stroke()
        })
        
        menu.popUpMenuPositioningItem(menuItem, aligning: .baseline, atPoint: baselineOrigin, inView: controlView, matchingWidth: true, withEvent: event, highlighting: .item)
        
        return true
    }
    
    
    // MARK: - OBWFilteringPopUpButtonCell implementation
    
    /// The pop up button's filtering menu.
    public var filteringMenu: OBWFilteringMenu? = nil {
        
        willSet {
            self.visibleFilteringItem = nil
            NotificationCenter.default.removeObserver(self, name: OBWFilteringMenu.didSelectItemNotification, object: self.filteringMenu)
        }
        didSet {
            NotificationCenter.default.addObserver(self, selector: #selector(didSelectMenuItem(_:)), name: OBWFilteringMenu.didSelectItemNotification, object: self.filteringMenu)
            
            if let firstMenuItem = self.filteringMenu?.itemArray.first(where: {
                !$0.isSeparatorItem && !$0.isHeadingItem
            }) {
                self.displayMenuItem(firstMenuItem)
            }
        }
    }
    
    /// The title shown when no menu item is currently being displayed.
    public var placeholderTitle = ""
    
    /// The currently-visible filtering menu item.
    public var selectedFilteringItem: OBWFilteringMenuItem? {
        return self.visibleFilteringItem
    }
    
    /// Display the given filtering menu item
    public func select(_ filteringItem: OBWFilteringMenuItem?) {
        self.displayMenuItem(filteringItem)
    }
    
    
    // MARK: - Private
    
    /// The filtering menu item whose properties are being displayed by the cell.
    private var visibleFilteringItem: OBWFilteringMenuItem? = nil
    
    /// A filtering menu item was selected.
    @objc private func didSelectMenuItem(_ notification: Notification) {
        
        guard
            let menu = notification.object as? OBWFilteringMenu,
            menu === self.filteringMenu,
            let menuItem = notification.userInfo?[OBWFilteringMenu.Key.item] as? OBWFilteringMenuItem
        else {
            return
        }
        
        self.displayMenuItem(menuItem)
        
        if let target = self.target, let action = self.action {
            _ = target.perform(action, with: self.controlView)
        }
    }
    
    /// Display the title and icon of the given filtering menu item on the pop up button.  Uses an NSMenu for display purposes.
    private func displayMenuItem(_ filteringMenuItem: OBWFilteringMenuItem?) {
        
        if self.menu == nil {
            self.menu = NSMenu(title: "Placeholder")
        }
        
        self.visibleFilteringItem = filteringMenuItem
        
        self.menu?.removeAllItems()
        
        let standardMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        
        if let item = filteringMenuItem {
            
            if let title = item.title, !title.isEmpty {
                standardMenuItem.title = title
            }
            else if let title = item.attributedTitle?.string, !title.isEmpty {
                standardMenuItem.title = title
            }
            else {
                standardMenuItem.title = self.placeholderTitle
            }
            
            standardMenuItem.image = item.image
        }
        else {
            standardMenuItem.title = self.placeholderTitle
            standardMenuItem.isEnabled = false
        }
        
        self.menu?.addItem(standardMenuItem)
        self.setTitle(standardMenuItem.title)
    }
    
}
