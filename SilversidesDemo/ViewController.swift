/*===========================================================================
 ViewController.swift
 SilversidesDemo
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit
import OBWControls

/// A class that provides basic information about a path view item.
private class ItemInfo {
    
    /// The type of path view item.
    enum ItemType {
        /// The item represents a filesystem volume.
        case volume
        /// The item represents a file.
        case file
        /// The item contains trailing information about the path view's URL.
        case tail
    }
    
    /// The URL represented by the path view item.
    let url: URL
    /// The path view item's type.
    let type: ItemType
    
    init(url: URL, type: ItemType) {
        self.url = url
        self.type = type
    }
}


// MARK: -

class ViewController: NSViewController {
    
    // MARK: - Lifecycle
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.commonInitialization()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInitialization()
    }
    
    private func commonInitialization() {
        NSApp.addObserver(self, forKeyPath: #keyPath(NSApplication.effectiveAppearance), options: [], context: &ViewController.kvoContext)
        self.kvoRegistered = true
    }
    
    deinit {
        
        if self.kvoRegistered {
            NSApp.removeObserver(self, forKeyPath: #keyPath(NSApplication.effectiveAppearance), context: &ViewController.kvoContext)
        }
    }
    
    
    /// MARK: - Observable Properties.
    
    /// Indicates whether the path view has been configured to display a URL.
    private(set) var pathViewConfigured = false
    
    /// If `true`, the user can interact with the path view.
    @objc dynamic var pathViewEnabled = true {
        didSet {
            self.pathViewOutlet.enabled = self.pathViewEnabled
        }
    }
    
    /// If `true`, path view item titles are draw in bold typeface.
    @objc dynamic var displayBoldItemTitles = false {
        didSet {
            
            for index in 0 ..< self.pathViewOutlet.numberOfItems {
                
                var pathItem = try! self.pathViewOutlet.item(atIndex: index)
                var style = pathItem.style
                
                if style.contains(.bold) == self.displayBoldItemTitles {
                    continue
                }
                
                if self.displayBoldItemTitles {
                    style.insert(.bold)
                }
                else {
                    style.remove(.bold)
                }
                
                pathItem.style = style
                
                try! self.pathViewOutlet.setItem(pathItem, atIndex: index)
            }
        }
    }
    
    /// If `true`, path view items display icons.
    @objc dynamic var displayItemIcons = true {
        didSet {
            
            self.pathViewOutlet.beginPathItemUpdate()
            
            for index in 0 ..< self.pathViewOutlet.numberOfItems {
                
                var pathItem = try! self.pathViewOutlet.item(atIndex: index)
                
                guard let itemInfo = pathItem.representedObject as? ItemInfo else {
                    assertionFailure()
                    return
                }
                
                if itemInfo.type == .tail {
                    continue
                }
                
                if self.displayItemIcons {
                    pathItem.image = NSWorkspace.shared.icon(forFile: itemInfo.url.path)
                }
                else {
                    pathItem.image = nil
                }
                
                try! self.pathViewOutlet.setItem(pathItem, atIndex: index)
            }
            
            try! self.pathViewOutlet.endPathItemUpdate()
        }
    }
    
    /// If `true`, path view items draw title prefixes.
    @objc dynamic var displayItemTitlePrefixes = false {
        didSet {
            
            for index in 0 ..< self.pathViewOutlet.numberOfItems {
                
                var pathItem = try! self.pathViewOutlet.item(atIndex: index)
                
                if pathItem.title.hasPrefix(ViewController.titlePrefix) == self.displayItemTitlePrefixes {
                    return
                }
                
                if self.displayItemTitlePrefixes {
                    pathItem.title = ViewController.titlePrefix + pathItem.title
                }
                else {
                    
                    guard let range = pathItem.title.range(of: ViewController.titlePrefix) else {
                        assertionFailure()
                        return
                    }
                    
                    pathItem.title = pathItem.title.replacingCharacters(in: range, with: "")
                }
                
                try! self.pathViewOutlet.setItem(pathItem, atIndex: index)
            }
        }
    }
    
    /// The color of the "volume" item in the path view.
    @objc dynamic var volumeColor = NSColor.systemRed {
        didSet {
            
            guard self.pathViewOutlet.numberOfItems > 0 else {
                return
            }
            
            var volumePathItem = try! self.pathViewOutlet.item(atIndex: 0)
            volumePathItem.textColor = self.volumeColor
            
            try! self.pathViewOutlet.setItem(volumePathItem, atIndex: 0)
        }
    }
    
    /// If `true`, the path view draws a background.
    @objc dynamic var drawBackgroundColor = true {
        didSet {
            self.updatePathViewLayer()
        }
    }
    
    /// The background color of the path view.
    @objc dynamic var backgroundColor = NSColor.textBackgroundColor {
        didSet {
            self.updatePathViewLayer()
        }
    }
    
    /// If `true`, a border is drawn around the path view.
    @objc dynamic var drawBorder = true {
        didSet {
            self.updatePathViewLayer()
        }
    }
    
    /// The path view's border color.
    @objc dynamic var borderColor = NSColor.tertiaryLabelColor {
        didSet {
            self.updatePathViewLayer()
        }
    }
    
    
    // MARK: - NSKeyValueObserving Overrides
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if context != &ViewController.kvoContext {
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
        
        if keyPath == #keyPath(NSApplication.effectiveAppearance) {
            DispatchQueue.main.async {
                self.updatePathViewLayer()
            }
        }
    }
    
    
    // MARK: - NSView Overrides
    
    /// Configure the main view.
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        assert(self.pathViewOutlet != nil)
        assert(self.styledFilteringPopUpButtonOutlet != nil)
        assert(self.regularFilteringPopUpButtonOutlet != nil)
        assert(self.smallFilteringPopUpButtonOutlet != nil)
        assert(self.miniFilteringPopUpButtonOutlet != nil)
        assert(self.regularStandardPopUpButtonOutlet != nil)
        assert(self.smallStandardPopUpButtonOutlet != nil)
        assert(self.miniStandardPopUpButtonOutlet != nil)
        
        // Do any additional setup after loading the view.
        
        self.pathViewOutlet.delegate = self
        self.updatePathViewLayer()
        
        let homePath = NSHomeDirectory()
        let homeURL = URL(fileURLWithPath: homePath)
        self.configurePathViewToShowURL(homeURL)
        
        NSColorPanel.shared.showsAlpha = true
        
        guard
            let styledCell = self.styledFilteringPopUpButtonOutlet.cell as? OBWFilteringPopUpButtonCell,
            let regularCell = self.regularFilteringPopUpButtonOutlet.cell as? OBWFilteringPopUpButtonCell,
            let smallCell = self.smallFilteringPopUpButtonOutlet.cell as? OBWFilteringPopUpButtonCell,
            let miniCell = self.miniFilteringPopUpButtonOutlet.cell as? OBWFilteringPopUpButtonCell
        else {
            assertionFailure("cells for the filtering pop up buttons are expected to be a OBWFilteringPopUpButtonCell")
            return
        }
        
        styledCell.filteringMenu = ViewController.makeStyledMenu()
        
        let popupButtonBaseURL = URL(fileURLWithPath: "/Volumes/Macintosh HD/Applications")
        
        for cell in [regularCell, smallCell, miniCell] {
            
            let menu = OBWFilteringMenu(title: "")
            self.populateFilteringMenu(menu, withContentsAtURL: popupButtonBaseURL, subdirectories: false)
            guard menu.numberOfItems > 0 else {
                continue
            }
            
            for menuItem in menu.itemArray {
                menuItem.image?.size = OBWFilteringMenu.iconSize(for: cell.controlSize)
            }
            
            cell.filteringMenu = menu
        }
        
        self.regularStandardPopUpButtonOutlet.menu = ViewController.makeStandardMenu()
        self.smallStandardPopUpButtonOutlet.menu = ViewController.makeStandardMenu()
        self.miniStandardPopUpButtonOutlet.menu = ViewController.makeStandardMenu()
    }
    
    
    // MARK: - ViewController Implementation
    
    /// Configures the path view to display the given URL.
    func configurePathViewToShowURL(_ url: URL) {
        
        self.pathViewOutlet.beginPathItemUpdate()
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            
            // Filesystem access can be slow...
            let pathItems = self.pathItemsForURL(url)
            
            DispatchQueue.main.async(execute: {
                self.pathViewOutlet.setItems(pathItems)
                try! self.pathViewOutlet.endPathItemUpdate()
                self.pathViewConfigured = true
            })
        }
        
    }
    
    /// Creates an array of path items to represent the given URL.
    func pathItemsForURL(_ url: URL) -> [OBWPathItem] {
        
        // Build array of parent URLs back to the volume URL
        var parentURLArray: [URL] = []
        var parentURL = url
        
        while parentURL.isVolumeRoot == false {
            
            parentURLArray.append(parentURL)
            
            let newParentURL = parentURL.deletingLastPathComponent()
            guard newParentURL != parentURL else {
                break
            }
            
            parentURL = newParentURL
        }
        
        // Volume path item
        let volumeInfo = ItemInfo(url: parentURL, type: .volume)
        var volumeItem = self.makePathItem(with: volumeInfo)
        volumeItem.textColor = self.volumeColor
        
        var pathItems = [volumeItem]
        
        // Center path items
        for itemURL in parentURLArray.reversed() {
            let itemInfo = ItemInfo(url: itemURL, type: .file)
            pathItems.append(self.makePathItem(with: itemInfo))
        }
        
        if url.isContainer == false {
            return pathItems
        }
        
        guard let descendantURLs = url.descendantURLs else {
            return pathItems
        }
        
        // Add a tail path item when displaying a container URL
        let tailItem = OBWPathItem(
            title: (descendantURLs.isEmpty ? "Empty Folder" : "No Selection"),
            image: nil,
            representedObject: ItemInfo(url: url, type: .tail),
            style: [.italic, .noTextShadow],
            textColor: NSColor.disabledControlTextColor,
            accessible: descendantURLs.isEmpty == false
        )
        
        pathItems.append(tailItem)
        
        return pathItems
    }
    
    /// Populates the given menu with items representing the descendants of the location represented by the menu.
    /// - parameter menu: The filtering menu to populate.
    /// - parameter parentURL: The container location.
    /// - parameter subdirectories: If `true`, menu items that represent a container location will contain an empty submenu to display the descendants of that location.
    func populateFilteringMenu(_ menu: OBWFilteringMenu, withContentsAtURL parentURL: URL?, subdirectories: Bool) {
        
        // TODO: When navigating via VoiceOver, insert an item at the top of the menu that allows the parent URL to be selected.  Without that item, a URL representing a folder cannot be selected.
        
        menu.removeAllItems()
        
        let menuItems = self.makeFilteringMenuItems(forContentsAtURL: parentURL, subdirectories: subdirectories)
        
        if menuItems.isEmpty == false {
            menu.addItems(menuItems)
        }
        else {
            menu.addItem(ViewController.emptyFolderMenuItem)
        }
    }
    
    /// Returns menu items for the descendants of the given URL.
    /// - parameter parentURL: A container URL.
    /// - parameter subdirectories: If `true`, each container menu item will contain an empty submenu to represent its descendants.
    /// - returns: An array of filtering menu items.
    func makeFilteringMenuItems(forContentsAtURL parentURL: URL?, subdirectories: Bool) -> [OBWFilteringMenuItem] {
        
        let descendantURLs: [URL]
        if let parentURL = parentURL {
            descendantURLs = parentURL.descendantURLs ?? []
        }
        else {
            descendantURLs = ViewController.mountedVolumeURLs
        }
        
        var menuItems: [OBWFilteringMenuItem] = []
        var urlCount = 0
        
        for url in descendantURLs {
            
            if urlCount % 5 == 0 {
                
                if menuItems.count > 0 {
                    menuItems.append(OBWFilteringMenuItem.separatorItem)
                }
                
                let menuItem = OBWFilteringMenuItem(headingTitled: "Group \(urlCount / 5 + 1)")
                menuItems.append(menuItem)
            }
            
            if let menuItem = self.makeFilteringMenuItem(withURL: url as NSURL, subdirectories: subdirectories) {
                menuItems.append(menuItem)
            }
            
            urlCount += 1
        }
        
        return menuItems
    }
    
    /// Returns a filtering menu item that represents the item at the given URL.
    /// - parameter url: A URL that identifies the represented item.
    /// - parameter subdirectories: If `true` and `url` is a container, the menu item will contain an empty submenu to represent the descendants of `url`.
    /// - returns: A filtering menu item representing the given URL, or `nil` if a menu item could not be created.
    func makeFilteringMenuItem(withURL url: NSURL, subdirectories: Bool) -> OBWFilteringMenuItem? {
        
        guard let path = url.path else {
            return nil
        }
        
        let displayName = FileManager.default.displayName(atPath: path)
        
        guard displayName.isEmpty == false else {
            return nil
        }
        
        let menuItem = OBWFilteringMenuItem(title: displayName)
        menuItem.representedObject = url
        menuItem.actionHandler = {
            [weak self] in
            
            guard let url = $0.representedObject as? NSURL else {
                return
            }
            
            self?.configurePathViewToShowURL(url as URL)
        }
        
        let icon = NSWorkspace.shared.icon(forFile: path)
        menuItem.image = icon
        
        guard subdirectories, (url as URL).isContainer else {
            return menuItem
        }
        
        let submenu = OBWFilteringMenu(title: path)
        submenu.delegate = self
        menuItem.submenu = submenu
        
        return menuItem
    }
    
    
    // MARK: - Private
    
    /// A sample title string.
    private static let titlePrefix = "Title: "
    
    /// Returns URLs of the mounted Volumes.
    private static var mountedVolumeURLs: [URL] {
        return FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: .skipHiddenVolumes) ?? []
    }
    
    /// A menu item that is shown when the container has no contents.
    private static var emptyFolderMenuItem: OBWFilteringMenuItem = {
        let menuItem = OBWFilteringMenuItem(title: "Empty Folder")
        menuItem.enabled = false
        return menuItem
    }()
    
    /// A menu item that is shown when the content of a menu are being constructed.
    private static var loadingMenuItem: OBWFilteringMenuItem = {
        let menuItem = OBWFilteringMenuItem(title: "Loading…")
        menuItem.enabled = false
        return menuItem
    }()
    
    /// Interface outlets.
    @IBOutlet private var pathViewOutlet: OBWPathView! = nil
    @IBOutlet private var styledFilteringPopUpButtonOutlet: NSPopUpButton! = nil
    @IBOutlet private var regularFilteringPopUpButtonOutlet: NSPopUpButton! = nil
    @IBOutlet private var smallFilteringPopUpButtonOutlet: NSPopUpButton! = nil
    @IBOutlet private var miniFilteringPopUpButtonOutlet: NSPopUpButton! = nil
    @IBOutlet private var regularStandardPopUpButtonOutlet: NSPopUpButton! = nil
    @IBOutlet private var smallStandardPopUpButtonOutlet: NSPopUpButton! = nil
    @IBOutlet private var miniStandardPopUpButtonOutlet: NSPopUpButton! = nil
    
    /// A context object for KVO notifications.
    private static var kvoContext = "KVOContext"
    
    /// Indicates whether the object has been registered for KVO notifications.
    private var kvoRegistered = false
    
    /// Returns a newly created path item.
    private func makePathItem(with info: ItemInfo) -> OBWPathItem {

        let path = info.url.path
        let prefix = (self.displayItemTitlePrefixes ? ViewController.titlePrefix : "")
        let title = prefix + FileManager.default.displayName(atPath: path)
        let image: NSImage? = (self.displayItemIcons ? NSWorkspace.shared.icon(forFile: path) : nil)
        let style: OBWPathItemStyle = (self.displayBoldItemTitles ? .bold : .default)

        let pathItem = OBWPathItem(
            title: title,
            image: image,
            representedObject: info,
            style: style,
            textColor: nil
        )

        return pathItem
    }
    
    /// Updates the properties of the path view layer to match the current settings.
    private func updatePathViewLayer() {
        
        guard
            let pathView = self.pathViewOutlet,
            let layer = pathView.layer
        else {
            return
        }
        
        let previousAppearance = NSAppearance.current
        NSAppearance.current = pathView.effectiveAppearance
        defer {
            NSAppearance.current = previousAppearance
        }
        
        if self.drawBackgroundColor {
            layer.backgroundColor = self.backgroundColor.cgColor
        }
        else {
            layer.backgroundColor = nil
        }
        
        if self.drawBorder {
            layer.borderWidth = 1.0
            layer.borderColor = self.borderColor.cgColor
        }
        else {
            layer.borderColor = nil
            layer.borderWidth = 0.0
        }
    }
    
    /// Returns a filtering menu that uses attributed titles.
    private static func makeStyledMenu() -> OBWFilteringMenu {
        
        let filteringMenu = OBWFilteringMenu(title: "Styled")
        
        guard let font = NSFont.userFixedPitchFont(ofSize: 12.0) else {
            assertionFailure("Failed to obtain the system fixed pitch font")
            return filteringMenu
        }
        
        let attributes: [NSAttributedString.Key : Any] = [
            .font : font,
            .foregroundColor : NSColor.systemYellow,
        ]
        
        let attributedString = NSAttributedString(string: "Attributed String", attributes: attributes)
        
        let menuItem1 = OBWFilteringMenuItem(title: "")
        menuItem1.attributedTitle = attributedString
        filteringMenu.addItem(menuItem1)
        
        let menuItem2 = OBWFilteringMenuItem(title: "")
        menuItem2.attributedTitle = attributedString
        menuItem2.enabled = false
        filteringMenu.addItem(menuItem2)
        
        filteringMenu.addSeparatorItem()
        
        let basicString = "Basic String"
        
        let menuItem3 = OBWFilteringMenuItem(title: basicString)
        filteringMenu.addItem(menuItem3)
        
        let menuItem4 = OBWFilteringMenuItem(title: basicString)
        menuItem4.enabled = false
        filteringMenu.addItem(menuItem4)
        
        return filteringMenu
    }
    
    /// Returns a placeholder standard menu.
    private static func makeStandardMenu() -> NSMenu {
        
        let standardMenu = NSMenu(title: "Standard")
        
        let filterItem = NSMenuItem(title: "filter", action: nil, keyEquivalent: "")
        
        let parentFrame = NSRect(x: 0.0, y: 0.0, width: 100.0, height: 32.0)
        let parentView = NSView(frame: parentFrame)
        parentView.autoresizingMask = .width
        
        let searchFrame = NSRect(x: 0.0, y: 0.0, width: 20.0, height: 20.0)
        let searchField = NSSearchField(frame: searchFrame)
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholderString = "Filter"
        searchField.focusRingType = .none
        parentView.addSubview(searchField)
        
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 2.0),
            searchField.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -2.0),
            searchField.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 8.0),
            searchField.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -8.0),
        ])
        
        filterItem.view = parentView
        standardMenu.addItem(filterItem)
        
        let itemMap: [(String, String, Int)] = [
            ("First", NSImage.computerName, 0),
            ("Second", NSImage.folderName, 1),
            ("Third", NSImage.folderSmartName, 2),
            ("Fourth", NSImage.trashEmptyName, 1),
            ("Fifth", NSImage.trashFullName, 0),
        ]
        
        for (title, imageName, indentationLevel) in itemMap {
            
            let menuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            menuItem.image = NSImage(named: imageName)
            menuItem.indentationLevel = indentationLevel
            standardMenu.addItem(menuItem)
        }
        
        return standardMenu
    }
}


// MARK: - OBWFilteringMenuDelegate

extension ViewController: OBWFilteringMenuDelegate {
    
    /// The given menu is about to appear on-screen.  Perform final configuration of the menu.
    func filteringMenuWillAppear(_ menu: OBWFilteringMenu) {
        
        let parentPath = menu.title
        guard FileManager.default.fileExists(atPath: parentPath) else {
            return
        }
        
        menu.removeAllItems()
        menu.addItem(ViewController.loadingMenuItem)
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            let parentURL = URL(fileURLWithPath: parentPath)
            let menuItems = self.makeFilteringMenuItems(forContentsAtURL: parentURL, subdirectories: true)
            
            DispatchQueue.main.async {
                
                menu.asyncUpdate(with: {
                    filteringMenu in
                    
                    filteringMenu.removeAllItems()
                    
                    if menuItems.isEmpty == false {
                        filteringMenu.addItems(menuItems)
                    }
                    else {
                        filteringMenu.addItem(ViewController.emptyFolderMenuItem)
                    }
                    
                    self.resizeMenu(filteringMenu, to: .small)
                })
            }
        }
    }
    
    /// Returns accessibility help for the given menu item.
    /// - parameter menu: The menu object that is making the delegate request.
    /// - parameter menuItem: The menu item that help information is being requested for.
    /// - returns: A help string.
    func filteringMenu(_ menu: OBWFilteringMenu, accessibilityHelpForItem menuItem: OBWFilteringMenuItem) -> String? {
        
        let menuItemHasSubmenu = (menuItem.submenu != nil)
        
        let folderFormat = NSLocalizedString("Click this button to interact with the %@ folder", comment: "Folder menu item help format")
        let fileFormat = NSLocalizedString("Click this button to select %@", comment: "File menu item help format")
        let format = menuItemHasSubmenu ? folderFormat : fileFormat
        return String.localizedStringWithFormat(format, menuItem.title ?? "")
    }
    
}


// MARK: - OBWPathViewDelegate

extension ViewController: OBWPathViewDelegate {
    
    /// Returns a filtering menu for the given path item.
    /// - parameter pathView: The path view object making the delegate request.
    /// - parameter pathItem: The item that will host the menu.
    /// - parameter interaction: The type of interaction that the user will have with the menu.
    /// - returns: A filtering menu.
    func pathView(_ pathView: OBWPathView, filteringMenuForItem pathItem: OBWPathItem, interaction: OBWPathItem.InteractionType) -> OBWFilteringMenu? {
        
        guard let itemInfo = pathItem.representedObject as? ItemInfo else {
            assertionFailure()
            return nil
        }
        
        let itemURL: URL?
        
        switch itemInfo.type {
        case .file:
            itemURL = itemInfo.url.deletingLastPathComponent()
        case .tail:
            itemURL = itemInfo.url
        case .volume:
            itemURL = nil
        }
        
        let menu = OBWFilteringMenu(title: itemURL?.path ?? "")
        self.populateFilteringMenu(menu, withContentsAtURL: itemURL, subdirectories: true)
        self.resizeMenu(menu, to: .small)
        
        return menu
    }
    
    /// Set the size of the given menu to the given control size.
    /// - parameter menu: The filtering menu.
    /// - parameter controlSize: A standard control size of the menu item titles and icons.
    private func resizeMenu(_ menu: OBWFilteringMenu, to controlSize: NSControl.ControlSize) {
        
        menu.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: controlSize))
        
        for menuItem in menu.itemArray {
            menuItem.image?.size = OBWFilteringMenu.iconSize(for: controlSize)
        }
    }
    
    /// Returns an accessible description for the path view.
    func pathViewAccessibilityDescription(_ pathView: OBWPathView) -> String? {
        
        var url = URL(fileURLWithPath: "/")
        
        for index in 0..<pathView.numberOfItems {
            
            if let pathItem = try? pathView.item(atIndex: index) {
                url.appendPathComponent(pathItem.title)
            }
        }
        
        return url.path
    }
    
    /// Returns accessibility help for the path view.
    func pathViewAccessibilityHelp(_ pathView: OBWPathView) -> String? {
        return NSLocalizedString("This identifies the path to the current test item", comment: "Path View help")
    }
    
    /// Returns accessibility help for the given path view item.
    func pathView(_ pathView: OBWPathView, accessibilityHelpForItem: OBWPathItem) -> String? {
        return NSLocalizedString("This identifies an element in the path to the current test item", comment: "Path Item View help")
    }
}
