/*===========================================================================
 OBWFilteringMenuView.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa
import Carbon.HIToolbox.Events

/*==========================================================================*/

let OBWFilteringMenuTotalItemSizeChangedNotification = Notification.Name(rawValue: "OBWFilteringMenuTotalItemSizeChangedNotification")
let OBWFilteringMenuViewPreviousGeometryKey = "OBWFilteringMenuViewPreviousGeometryKey"

private let OBWFilteringMenuAllowedModifiers: NSEvent.ModifierFlags = [.shift, .control, .option, .command]

/*==========================================================================*/

private func OBWStandardHeightForControlSize(_ controlSize: NSControl.ControlSize) -> CGFloat {
    
    switch controlSize {
    case .mini:     return 15.0
    case .small:    return 19.0
    default:        return 22.0
    }
}

/*==========================================================================*/

class OBWFilteringMenuView: NSView {
    
    init(menu: OBWFilteringMenu, minimumWidth: CGFloat?) {
        
        self.filteringMenu = menu
        
        let initialFrame = NSRect(
            width: OBWFilteringMenuView.filterMargins.width + OBWFilteringMenuItemView.minimumWidth,
            height: 0.0
        )
        
        let menuFont = menu.displayFont
        let filterFieldSize = NSControl.controlSizeForFontSize(menuFont.pointSize)
        
        let filterFrame = NSRect(
            x: OBWFilteringMenuView.filterMargins.left,
            y: 0.0,
            width: initialFrame.size.width - OBWFilteringMenuView.filterMargins.width,
            height: OBWStandardHeightForControlSize(filterFieldSize)
        )
        
        let filterField = NSTextField(frame: filterFrame)
        filterField.font = menuFont
        filterField.cell?.controlSize = filterFieldSize
        filterField.bezelStyle = .roundedBezel
        filterField.cell?.focusRingType = .none
        filterField.cell?.isScrollable = true
        (filterField.cell as? NSTextFieldCell)?.placeholderString = "Filter"
        filterField.autoresizingMask = [.width, .minYMargin]
        filterField.isHidden = true
        self.filterField  = filterField
        
        let filterFieldTitle = NSLocalizedString("Filter", comment: "The title of a filtering menu's editable text field")
        let filterFieldHelp = NSLocalizedString("The text in this field filters the items that appear in this menu", comment: "Help text for the filtering menu's editable text field")
        filterField.cell?.setAccessibilityTitle(filterFieldTitle)
        filterField.cell?.setAccessibilityHelp(filterFieldHelp)
        
        let scrollView = OBWFilteringMenuItemScrollView(menu: menu, minimumWidth: minimumWidth)
        self.scrollView = scrollView
        
        super.init(frame: initialFrame)
        
        self.autoresizingMask = [.minYMargin]
        self.autoresizesSubviews = true
        
        self.addSubview(filterField)
        self.setFrameSize(scrollView.frame.size)
        self.addSubview(scrollView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(OBWFilteringMenuView.textDidChange(_:)), name: NSText.didChangeNotification, object: nil)
    }
    
    /*==========================================================================*/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*==========================================================================*/
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSText.didChangeNotification, object: nil)
    }
    
    /*==========================================================================*/
    // MARK: - NSResponder overrides
    
    /*==========================================================================*/
    override func cursorUpdate(with event: NSEvent) {
        
        guard
            self.dispatchingCursorUpdateToFilterField == false,
            let locationInView = event.locationInView(self)
        else {
            return
        }
        
        let filterField = self.filterField
        let filterFieldFrame = filterField.frame
        
        if filterField.isHidden == false && NSPointInRect(locationInView, filterFieldFrame) {
            
            // The search field might call -[super cursorUpdate:], which might eventually reach -[NSResponder cursorUpdate:], which will send the message up the responder chain, which leads back here.  'dispatchingCursorUpdateToFilterField' is used to break that recursion.
            
            self.dispatchingCursorUpdateToFilterField = true
            filterField.cursorUpdate(with: event)
            self.dispatchingCursorUpdateToFilterField = false
        }
        else {
            NSCursor.arrow.set()
        }
    }
    
    /*==========================================================================*/
    // MARK: - NSView overrides
    
    /*==========================================================================*/
    override func draw(_ dirtyRect: NSRect) {
        #if DEBUG_MENU_TINTING
            NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.1).set()
            NSRectFill(self.bounds)
        #endif
    }
    
    /*==========================================================================*/
    // MARK: - NSAccessibility implementation
    
    /*==========================================================================*/
    override func isAccessibilityElement() -> Bool {
        return true
    }
    
    /*==========================================================================*/
    override func accessibilityRole() -> NSAccessibility.Role? {
        return NSAccessibility.Role.list
    }
    
    /*==========================================================================*/
    override func accessibilityRoleDescription() -> String? {
        return NSAccessibility.Role.list.description(with: nil)
    }
    
    /*==========================================================================*/
    override func accessibilityChildren() -> [Any]? {
        
        guard var children = self.scrollView.accessibilityChildren() else {
            return nil
        }
        
        if self.filterField.isHidden == false {
            children.append(filterField)
        }
        
        return NSAccessibility.unignoredChildren(from: children)
    }
    
    /*==========================================================================*/
    override func isAccessibilityEnabled() -> Bool {
        return true
    }
    
    /*==========================================================================*/
    override func accessibilityParent() -> Any? {
        
        guard let window = self.window else {
            return nil
        }
        
        return NSAccessibility.unignoredAncestor(of: window)
    }
    
    /*==========================================================================*/
    override func accessibilitySelectedChildren() -> [Any]? {
        
        guard
            let menuItem = self.filteringMenu.highlightedItem,
            let itemView = self.viewForMenuItem(menuItem)
        else {
            return []
        }
        
        return [itemView]
    }
    
    /*==========================================================================*/
    override func accessibilityTitleUIElement() -> Any? {
        return self
    }
    
    /*==========================================================================*/
    override func accessibilityVisibleChildren() -> [Any]? {
        return self.scrollView.accessibilityChildren()
    }
    
    /*==========================================================================*/
    override func accessibilityOrientation() -> NSAccessibilityOrientation {
        return .vertical
    }
    
    /*==========================================================================*/
    override func accessibilityTopLevelUIElement() -> Any? {
        return self.window
    }
    
    /*==========================================================================*/
    override func setAccessibilitySelectedChildren(_ accessibilitySelectedChildren: [Any]?) {
        
        let selectedView = accessibilitySelectedChildren?.first as? OBWFilteringMenuItemView
        self.filteringMenu.highlightedItem = selectedView?.menuItem
    }
    
    /*==========================================================================*/
    // MARK: - NSControl delegate implementation
    
    /*==========================================================================*/
    @objc func textDidChange(_ notification: Notification) {
        
        let filterField = self.filterField
        
        guard
            let notificationObject = notification.object as? NSText,
            let currentEditor = filterField.currentEditor(),
            notificationObject === currentEditor
        else {
            return
        }
        
        NSAccessibility.post(element: currentEditor, notification: NSAccessibility.Notification.focusedUIElementChanged)
        
        let filterString = filterField.stringValue
        let menuItemArray = self.filteringMenu.itemArray
        
        let filterEventNumber = self.lastFilterEventNumber + 1
        self.lastFilterEventNumber = filterEventNumber
        
        DispatchQueue.global(qos: .default).async {
            
            var statusArray: [OBWFilteringMenuItemFilterStatus] = []
            
            for menuItem in menuItemArray {
                
                guard self.lastFilterEventNumber == filterEventNumber else {
                    return
                }
                
                statusArray.append(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: filterString))
            }
            
            DispatchQueue.main.async {
                
                guard self.lastFilterEventNumber == filterEventNumber else {
                    return
                }
                
                self.applyFilterResults(statusArray)
            }
        }
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuView implementation
    
    static let filterMargins = NSEdgeInsets(top: 4.0, left: 20.0, bottom: 4.0, right: 20.0)
    
    var totalMenuItemSize: NSSize { return self.scrollView.totalMenuItemSize }
    var menuItemBounds: NSRect { return self.scrollView.menuItemBounds }
    
    /*==========================================================================*/
    var outerMenuMargins: NSEdgeInsets {
        
        let filterField = self.filterField
        
        guard filterField.isHidden == false else {
            return NSEdgeInsetsZero
        }
        
        let filterAreaHeight = OBWFilteringMenuView.filterMargins.height + filterField.frame.size.height
        
        return NSEdgeInsets(top: filterAreaHeight, left: 0.0, bottom: 0.0, right: 0.0)
    }
    
    /*==========================================================================*/
    var minimumHeightAtTop: CGFloat {
        
        let scrollViewMinimumHeight = self.scrollView.minimumHeightAtTop
        
        let filterField = self.filterField
        if filterField.isHidden {
            return scrollViewMinimumHeight
        }
        
        let filterMargins = OBWFilteringMenuView.filterMargins
        let minimumHeight = scrollViewMinimumHeight + filterMargins.height + filterField.frame.size.height
        
        return minimumHeight
    }

    /*==========================================================================*/
    var minimumHeightAtBottom: CGFloat {
        
        let scrollViewMinimumHeight = self.scrollView.minimumHeightAtBottom
        
        let filterField = self.filterField
        if filterField.isHidden {
            return scrollViewMinimumHeight
        }
        
        let filterMargins = OBWFilteringMenuView.filterMargins
        let minimumHeight = scrollViewMinimumHeight + filterMargins.height + filterField.frame.size.height
        
        return minimumHeight
    }
    
    /*==========================================================================*/
    func handleLeftMouseButtonDownEvent(_ event: NSEvent) -> OBWFilteringMenuEventResult {
        
        let filterField = self.filterField
        
        guard
            filterField.isHidden == false,
            let locationInView = event.locationInView(self),
            NSPointInRect(locationInView, filterField.frame)
        else {
            return .unhandled
        }
        
        filterField.mouseDown(with: event)
        
        return .continue
    }
    
    /*==========================================================================*/
    func handleKeyboardEvent(_ event: NSEvent) -> OBWFilteringMenuEventResult {
        
        let keyCode = Int(event.keyCode)
        
        let scrollView = self.scrollView
        let filterField = self.filterField
        var currentEditor = filterField.currentEditor()
        
        if event.modifierFlags.contains(.command) {
            
            if currentEditor != nil {
                NSApp.sendEvent(event)
            }
            
            return .continue
        }
        
        if keyCode == kVK_Tab {
            
            if filterField.isHidden {
                return .continue
            }
            
            self.moveKeyboardFocusToFilterFieldAndSelectAll(true)
            
            return .highlight
        }
        
        let filteringMenu = self.filteringMenu
        let currentHighlightedItem = filteringMenu.highlightedItem
        let currentHighlightedItemView: OBWFilteringMenuItemView?
            
        if let currentHighlightedItem = currentHighlightedItem {
            currentHighlightedItemView = scrollView.viewForMenuItem(currentHighlightedItem)
        }
        else {
            currentHighlightedItemView = nil
        }
        
        var nextHighlightedItemView = currentHighlightedItemView
        
        if [kVK_UpArrow, kVK_Home, kVK_PageUp].contains(keyCode) {
            
            if
                let currentEditor = currentEditor,
                currentHighlightedItem == nil
            {
                currentEditor.keyDown(with: event)
                return .continue
            }
            
            if keyCode == kVK_UpArrow {
                nextHighlightedItemView = scrollView.previousViewBeforeItem(currentHighlightedItem)
            }
            else if keyCode == kVK_Home {
                nextHighlightedItemView = scrollView.nextViewAfterItem(nil)
            }
            else if keyCode == kVK_PageUp {
                nextHighlightedItemView = scrollView.scrollItemsDownOnePage()
            }
            
            if nextHighlightedItemView === currentHighlightedItemView && filterField.isHidden == false {
                self.moveKeyboardFocusToFilterFieldAndSelectAll(true)
                return .highlight
            }
            
            if
                let nextHighlightedItemView = nextHighlightedItemView,
                nextHighlightedItemView !== currentHighlightedItemView
            {
                filteringMenu.highlightedItem = nextHighlightedItemView.menuItem
                scrollView.scrollItemToVisible(nextHighlightedItemView.menuItem)
                return .highlight
            }
            
            return .continue
        }
        else if [kVK_DownArrow, kVK_End, kVK_PageDown].contains(keyCode) {
            
            if currentEditor != nil {
                self.window?.makeFirstResponder( nil )
                nextHighlightedItemView = scrollView.nextViewAfterItem(currentHighlightedItem)
            }
            else if keyCode == kVK_DownArrow {
                nextHighlightedItemView = scrollView.nextViewAfterItem(currentHighlightedItem)
            }
            else if keyCode == kVK_End {
                nextHighlightedItemView = scrollView.previousViewBeforeItem(nil)
            }
            else if keyCode == kVK_PageDown {
                nextHighlightedItemView = scrollView.scrollItemsUpOnePage()
            }
            
            if
                let nextHighlightedItemView = nextHighlightedItemView,
                nextHighlightedItemView !== currentHighlightedItemView
            {
                filteringMenu.highlightedItem = nextHighlightedItemView.menuItem
                scrollView.scrollItemToVisible(nextHighlightedItemView.menuItem)
                return .highlight
            }
            
            return .continue
        }
        
        if [kVK_LeftArrow, kVK_RightArrow, kVK_Space, kVK_Return, kVK_ANSI_KeypadEnter].contains(keyCode) {
            
            if let currentEditor = currentEditor {
                currentEditor.keyDown(with: event)
                return .continue
            }
            else {
                return .unhandled
            }
        }
        
        if filterField.isHidden {
            
            let filterMargins = OBWFilteringMenuView.filterMargins
            var scrollViewFrame = self.scrollView.frame
            scrollViewFrame.size.height -= (filterMargins.height + filterField.frame.size.height)
            self.scrollView.setFrameSize(scrollViewFrame.size)
            
            var filterFieldFrame = filterField.frame
            filterFieldFrame.origin.y = scrollViewFrame.maxY + filterMargins.bottom
            filterField.setFrameOrigin(filterFieldFrame.origin)
            filterField.isHidden = false
            
            // Set the string value to an initial non-empty string that will get selected and replaced by the typed character.  This prods the search field to display the cancel button.
            filterField.stringValue = " "
            
            if let window = self.window as? OBWFilteringMenuWindow {
                _ = window.displayUpdatedTotalMenuItemSize()
            }
        }
        
        if currentEditor == nil {
            self.moveKeyboardFocusToFilterFieldAndSelectAll(true)
            currentEditor = filterField.currentEditor()
        }
        
        if let currentEditor = currentEditor {
            currentEditor.keyDown(with: event)
        }
        
        return .changeFilter
    }
    
    /*==========================================================================*/
    func handleFlagsChangedEvent(_ event: NSEvent) {
        
        let modifierFlags = event.modifierFlags.intersection(OBWFilteringMenuAllowedModifiers)
        
        if self.scrollView.applyModifierFlags(modifierFlags) {
            
            if let window = self.window as? OBWFilteringMenuWindow {
                _ = window.displayUpdatedTotalMenuItemSize()
            }
        }
    }
    
    /*==========================================================================*/
    func applyFilterResults(_ statusArray: [OBWFilteringMenuItemFilterStatus]) {
        
        if self.scrollView.applyFilterResults(statusArray) {
            
            if let window = self.window as? OBWFilteringMenuWindow {
                _ = window.displayUpdatedTotalMenuItemSize()
            }
        }
    }
    
    /*==========================================================================*/
    func selectFirstMenuItemView() {
        self.filteringMenu.highlightedItem = self.scrollView.nextViewAfterItem(nil)?.menuItem
    }
    
    /*==========================================================================*/
    func menuItemAtLocation(_ locationInView: NSPoint) -> OBWFilteringMenuItem? {
        
        let scrollView = self.scrollView
        let locationInScrollView = self.convert(locationInView, to: scrollView)
        return scrollView.menuItemAtLocation(locationInScrollView)
    }
    
    /*==========================================================================*/
    func menuPartAtLocation(_ locationInView: NSPoint) -> OBWFilteringMenuPart {
        
        let filterField = self.filterField
        if filterField.isHidden == false && NSPointInRect(locationInView, filterField.frame) {
            return .filter
        }
        
        let scrollView = self.scrollView
        let locationInScrollView = self.convert(locationInView, to: scrollView)
        return scrollView.menuPartAtLocation(locationInScrollView)
    }
    
    /*==========================================================================*/
    func viewForMenuItem(_ menuItem: OBWFilteringMenuItem) -> OBWFilteringMenuItemView? {
        return self.scrollView.viewForMenuItem(menuItem)
    }
    
    /*==========================================================================*/
    func scrollItemsDownWithAcceleration(_ acceleration: Double) -> Bool {
        return self.scrollView.scrollItemsDownWithAcceleration(acceleration)
    }
    
    /*==========================================================================*/
    func scrollItemsUpWithAcceleration(_ acceleration: Double) -> Bool {
        return self.scrollView.scrollItemsUpWithAcceleration(acceleration)
    }
    
    /*==========================================================================*/
    func setMenuItemBoundsOriginY(_ boundsOriginY: CGFloat) {
        self.scrollView.setMenuItemBoundsOriginY(boundsOriginY)
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuView private
    
    unowned private let filteringMenu: OBWFilteringMenu
    unowned private let filterField: NSTextField
    unowned private let scrollView: OBWFilteringMenuItemScrollView
    private var lastFilterEventNumber: Int = 0
    private var dispatchingCursorUpdateToFilterField = false
    
    /*==========================================================================*/
    private func moveKeyboardFocusToFilterFieldAndSelectAll(_ selectAll: Bool) {
        
        self.filteringMenu.highlightedItem = nil
        
        let filterField = self.filterField
        filterField.selectText(nil)
        
        guard let currentEditor = filterField.currentEditor() else {
            return
        }
        
        if selectAll {
            currentEditor.selectAll(nil)
        }
        else {
            let selectionRange = NSRange(location: currentEditor.string.utf8.count, length: 0)
            currentEditor.selectedRange = selectionRange
        }
    }
}
