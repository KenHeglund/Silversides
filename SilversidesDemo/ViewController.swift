/*===========================================================================
 ViewController.swift
 SilversidesDemo
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit
import OBWControls

/*==========================================================================*/

private var ViewController_KVOContext = "KVOContext"

/*==========================================================================*/

private class ItemInfo {
    
    enum ItemType {
        
        case volume
        case file
        case tail
    }
    
    let url: URL
    let type: ItemType
    
    init(url: URL, type: ItemType) {
        self.url = url
        self.type = type
    }
}

/*==========================================================================*/
// MARK: -

class ViewController: NSViewController, NSMenuDelegate, OBWPathViewDelegate, OBWFilteringMenuDelegate {
    
    @IBOutlet var pathViewOutlet: OBWPathView! = nil
    @IBOutlet var styledFilteringPopUpButtonOutlet: NSPopUpButton! = nil
    @IBOutlet var regularFilteringPopUpButtonOutlet: NSPopUpButton! = nil
    @IBOutlet var smallFilteringPopUpButtonOutlet: NSPopUpButton! = nil
    @IBOutlet var miniFilteringPopUpButtonOutlet: NSPopUpButton! = nil
    @IBOutlet var regularStandardPopUpButtonOutlet: NSPopUpButton! = nil
    @IBOutlet var smallStandardPopUpButtonOutlet: NSPopUpButton! = nil
    @IBOutlet var miniStandardPopUpButtonOutlet: NSPopUpButton! = nil
    
    private(set) var pathViewConfigured = false
    private var kvoRegistered = false
    
    @objc dynamic var pathViewEnabled = true {
        
        didSet {
            self.pathViewOutlet.enabled = self.pathViewEnabled
        }
    }
    
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
    
    @objc dynamic var drawBackgroundColor = true {
        
        didSet {
            self.updatePathViewLayer()
        }
    }
    
    @objc dynamic var backgroundColor = NSColor.textBackgroundColor {
        
        didSet {
            self.updatePathViewLayer()
        }
    }
    
    @objc dynamic var drawBorder = true {
        
        didSet {
            self.updatePathViewLayer()
        }
    }
    
    @objc dynamic var borderColor = NSColor.tertiaryLabelColor {
        
        didSet {
            self.updatePathViewLayer()
        }
    }
    
    /*==========================================================================*/
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.commonInitialization()
    }
    
    /*==========================================================================*/
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInitialization()
    }
    
    /*==========================================================================*/
    private func commonInitialization() {
        NSApp.addObserver(self, forKeyPath: #keyPath(NSApplication.effectiveAppearance), options: [], context: &ViewController_KVOContext)
        self.kvoRegistered = true
    }
    
    /*==========================================================================*/
    deinit {
        
        if self.kvoRegistered {
            NSApp.removeObserver(self, forKeyPath: #keyPath(NSApplication.effectiveAppearance), context: &ViewController_KVOContext)
        }
    }
    
    /*==========================================================================*/
    // MARK: - NSKeyValueObserving overrides
    
    /*==========================================================================*/
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if context != &ViewController_KVOContext {
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
        
        if keyPath == #keyPath(NSApplication.effectiveAppearance) {
            DispatchQueue.main.async {
                self.updatePathViewLayer()
            }
        }
    }
    
    /*==========================================================================*/
    // MARK: - NSView overrides
    
    /*==========================================================================*/
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
            if self.populateFilteringMenu(menu, withContentsAtURL: popupButtonBaseURL, subdirectories: false) {
                
                for menuItem in menu.itemArray {
                    menuItem.image?.size = OBWFilteringMenu.iconSize(for: cell.controlSize)
                }
                
                cell.filteringMenu = menu
            }
        }
        
        self.regularStandardPopUpButtonOutlet.menu = ViewController.makeStandardMenu()
        self.smallStandardPopUpButtonOutlet.menu = ViewController.makeStandardMenu()
        self.miniStandardPopUpButtonOutlet.menu = ViewController.makeStandardMenu()
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuDelegate implementation
    
    /*==========================================================================*/
    func filteringMenuWillAppear( _ menu: OBWFilteringMenu ) {
        
        #if !USE_NSMENU
            guard menu.numberOfItems == 0 else {
                return
            }
            
            let parentPath = menu.title
            guard FileManager.default.fileExists(atPath: parentPath) else {
                return
            }
            
            let parentURL = URL(fileURLWithPath: parentPath)
            
            guard self.populateFilteringMenu(menu, withContentsAtURL: parentURL, subdirectories: true) else {
                return
            }
        
            for menuItem in menu.itemArray {
                menuItem.image?.size = OBWFilteringMenu.iconSize(for: .small)
            }
        #endif // !USE_NSMENU
    }
    
    /*==========================================================================*/
    func filteringMenu(_ menu: OBWFilteringMenu, accessibilityHelpForItem menuItem: OBWFilteringMenuItem) -> String? {
        
        #if !USE_NSMENU
            let menuItemHasSubmenu = (menuItem.submenu != nil)
            
            let folderFormat = NSLocalizedString("Click this button to interact with the %@ folder", comment: "Folder menu item help format")
            let fileFormat = NSLocalizedString("Click this button to select %@", comment: "File menu item help format")
            let format = menuItemHasSubmenu ? folderFormat : fileFormat
            return String.localizedStringWithFormat(format, menuItem.title ?? "")
        #else
            return nil
        #endif // !USE_NSMENU
    }

    
    #if USE_NSMENU
    /*==========================================================================*/
    // MARK: - NSMenuDelegate implementation
    
    /*==========================================================================*/
    func numberOfItemsInMenu(menu: NSMenu) -> Int {
        
        let parentPath = menu.title
        guard parentPath.isEmpty == false else {
            return 0
        }
        
        let parentURL = NSURL.fileURLWithPath(parentPath)
        
        guard let descendantURLs = ViewController.descendantURLsAtURL(parentURL) else {
            return 0
        }
        
        let childCount = descendantURLs.count
        
        return (childCount > 0 ? childCount : 1)
    }
    
    /*==========================================================================*/
    func menu(menu: NSMenu, updateItem item: NSMenuItem, atIndex index: Int, shouldCancel: Bool) -> Bool {
        
        let parentPath = menu.title
        
        guard
            parentPath.isEmpty == false,
            NSFileManager.defaultManager().fileExistsAtPath(parentPath)
        else {
            return false
        }
        
        let parentURL = NSURL.fileURLWithPath(parentPath)
        
        guard let childURLs = ViewController.descendantURLsAtURL(parentURL) else {
            return false
        }
        
        if childURLs.count == 0 && index == 0 {
            item.title = "Empty Folder"
            item.enabled = false
            return true
        }
        
        guard index >= 0 && index < childURLs.count else {
            return false
        }
        
        return self.updateMenuItem(item, withURL: childURLs[index])
    }
    #endif // USE_NSMENU
    
    /*==========================================================================*/
    // MARK: - OBWPathViewDelegate implementation
    
    /*==========================================================================*/
    func pathView(_ pathView: OBWPathView, filteringMenuForItem pathItem: OBWPathItem, activatedBy activation: OBWPathItem.ActivationType) -> OBWFilteringMenu? {
        
        #if !USE_NSMENU
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
            menu.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .small))
            
            guard self.populateFilteringMenu(menu, withContentsAtURL: itemURL, subdirectories: true) else {
                    return nil
                }
        
            for menuItem in menu.itemArray {
                menuItem.image?.size = OBWFilteringMenu.iconSize(for: .small)
            }

            return menu
        #else
            return nil
        #endif
    }
    
    /*==========================================================================*/
    func pathView(_ pathView: OBWPathView, menuForItem pathItem: OBWPathItem, activatedBy activation: OBWPathItem.ActivationType) -> NSMenu? {
        
        #if USE_NSMENU
            guard let itemInfo = pathItem.representedObject as? ItemInfo else {
                assertionFailure()
                return nil
            }
        
            let itemURL: NSURL?
            
            switch itemInfo.type {
            case .File:
                itemURL = itemInfo.url.URLByDeletingLastPathComponent
            case .Tail:
                itemURL = itemInfo.url
            case .Volume:
                itemURL = nil
            }
            
            let menu = NSMenu(title: itemURL?.path ?? "")
            menu.font = NSFont.systemFontOfSize(11.0)
            
            guard self.populateMenu(menu, withContentsAtURL: itemURL) else {
                return nil
            }
            
            return menu
        #else
            return nil
        #endif
    }
    
    /*==========================================================================*/
    func pathViewAccessibilityDescription(_ pathView: OBWPathView) -> String? {
        
        var url = URL(fileURLWithPath: "/")
        
        for index in 0..<pathView.numberOfItems {
            
            let pathItem = try! pathView.item(atIndex: index)
            url = url.appendingPathComponent(pathItem.title)
        }
        
        return url.path
    }
    
    /*==========================================================================*/
    func pathViewAccessibilityHelp(_ pathView: OBWPathView) -> String? {
        return NSLocalizedString("This identifies the path to the current test item", comment: "Path View help")
    }
    
    /*==========================================================================*/
    func pathView(_ pathView: OBWPathView, accessibilityHelpForItem: OBWPathItem) -> String? {
        return NSLocalizedString("This identifies an element in the path to the current test item", comment: "Path Item View help")
    }
    
    /*==========================================================================*/
    // MARK: - ViewController implementation
    
    /*==========================================================================*/
    func configurePathViewToShowURL(_ url: URL) {
        
        self.pathViewOutlet.beginPathItemUpdate()
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            
            let pathItems = self.pathItemsForURL(url)
            
            DispatchQueue.main.async(execute: {
                self.pathViewOutlet.setItems(pathItems)
                try! self.pathViewOutlet.endPathItemUpdate()
                self.pathViewConfigured = true
            })
        }
        
    }
    
    /*==========================================================================*/
    func pathItemsForURL(_ url: URL) -> [OBWPathItem] {
        
        // Build array of parent URLs back to the volume URL
        var parentURLArray: [URL] = []
        var parentURL = url
        
        while ViewController.isVolumeRootURL(parentURL) == false {
            
            parentURLArray.append(parentURL)
            
            let newParentURL = parentURL.deletingLastPathComponent()
            guard newParentURL != parentURL else {
                break
            }
            
            parentURL = newParentURL
        }
        
        // Volume path item
        let volumeInfo = ItemInfo(url: parentURL, type: .volume)
        var volumeItem = self.pathItemWithInfo(volumeInfo)
        volumeItem.textColor = self.volumeColor
        
        var pathItems = [volumeItem]
        
        // Center path items
        for itemURL in parentURLArray.reversed() {
            let itemInfo = ItemInfo(url: itemURL, type: .file)
            pathItems.append(self.pathItemWithInfo(itemInfo))
        }
        
        if ViewController.isContainerURL(url) == false {
            return pathItems
        }
        
        guard let descendantURLs = ViewController.descendantURLsAtURL(url) else {
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
    
    /*==========================================================================*/
    class func isVolumeRootURL(_ url: URL) -> Bool {
        
        let lastPathComponent = url.lastPathComponent
        let relativePath = url.relativePath
        if lastPathComponent == relativePath {
            return true
        }
        
        let shortenedPath = url.deletingLastPathComponent().path
        if shortenedPath == "/Volumes" {
            return true
        }
        
        return false
    }
    
    /*==========================================================================*/
    class func isContainerURL(_ url: URL) -> Bool {
        
        guard let resourceValues = try? (url as NSURL).resourceValues( forKeys: [.isDirectoryKey, .isPackageKey] ) else {
            return false
        }
        
        guard
            let isDirectory = resourceValues[URLResourceKey.isDirectoryKey] as? Bool,
            let isPackage = resourceValues[URLResourceKey.isPackageKey] as? Bool
        else {
            return false
        }
        
        return isDirectory && isPackage == false
    }
    
    /*==========================================================================*/
    class func descendantURLsAtURL(_ url: URL?) -> [URL]? {
        
        let fileManager = FileManager.default
        
        guard let parentURL = url else {
            return fileManager.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: .skipHiddenVolumes)
        }
        
        guard ViewController.isContainerURL(parentURL) else {
            return nil
        }
        
        let directoryOptions: FileManager.DirectoryEnumerationOptions = [
            .skipsSubdirectoryDescendants,
            .skipsPackageDescendants,
            .skipsHiddenFiles,
        ]
        
        guard let enumerator = fileManager.enumerator(at: parentURL, includingPropertiesForKeys: nil, options: directoryOptions, errorHandler: nil) else {
            return nil
        }
        
        let urlArray = enumerator.allObjects as? [URL]
        
        let sortedArray = urlArray?.sorted(by: {
            (firstURL: URL, secondURL: URL) -> Bool in
            return firstURL.path.caseInsensitiveCompare(secondURL.path) == .orderedAscending
        })
        
        return sortedArray
    }
    
    #if USE_NSMENU
    /*==========================================================================*/
    func populateMenu(menu: NSMenu, withContentsAtURL parentURL: NSURL?) -> Bool {
        
        guard let descendantURLs = ViewController.descendantURLsAtURL(parentURL) else {
            return false
        }
        
        if descendantURLs.isEmpty == false {
            
            for childURL in descendantURLs {
                
                let item = NSMenuItem()
                
                guard self.updateMenuItem(item, withURL: childURL) else {
                    continue
                }
                
                menu.addItem(item)
            }
            
            return true
        }
        else {
            
            let menuItem = NSMenuItem(title: "Empty Folder", action: nil, keyEquivalent: "")
            menuItem.enabled = false
            menu.addItem(menuItem)
            
            return false
        }
    }
    
    /*==========================================================================*/
    func updateMenuItem(menuItem: NSMenuItem, withURL url: NSURL) -> Bool {
        
        guard let path = url.path else {
            assertionFailure()
            return false
        }
        
        let displayName = NSFileManager.defaultManager().displayNameAtPath(path)
        guard displayName.isEmpty == false else {
            return false
        }
        
        menuItem.title = displayName
        menuItem.target = self
        menuItem.action = #selector(ViewController.selectURL(_:))
        menuItem.representedObject = url
        
        let icon = NSWorkspace.sharedWorkspace().iconForFile(path)
        icon.size = NSSize(width: 17.0, height: 17.0)
        menuItem.image = icon
        
        if ViewController.isContainerURL(url) == false {
            return true
        }
        
        let submenu = NSMenu(title: path)
        submenu.delegate = self
        submenu.font = NSFont.systemFontOfSize(11.0)
        menuItem.submenu = submenu
        
        return true
    }
    #endif // USE_NSMENU
    
    #if !USE_NSMENU
    /*==========================================================================*/
    func populateFilteringMenu(_ menu: OBWFilteringMenu, withContentsAtURL parentURL: URL?, subdirectories: Bool) -> Bool {
        
        // TODO: When navigating via VoiceOver, insert an item at the top of the menu that allows the parent URL to be selected.  Without that item, a URL representing a folder cannot be selected.
        
        guard let descendantURLs = ViewController.descendantURLsAtURL(parentURL) else {
            return false
        }
        
        if descendantURLs.isEmpty == false {
            
            var urlCount = 0
            
            for url in descendantURLs {
                
                if urlCount % 5 == 0 {
                    
                    if menu.itemArray.count > 0 {
                        menu.addItem(OBWFilteringMenuItem.separatorItem)
                    }
                    
                    let menuItem = OBWFilteringMenuItem(headingTitled: "Group \(urlCount / 5 + 1)")
                    menu.addItem(menuItem)
                }
                
                if let menuItem = self.filteringMenuItem(withURL: url as NSURL, subdirectories: subdirectories) {
                    menu.addItem(menuItem)
                }
                
                urlCount += 1
            }
            
            return true
        }
        else {
            
            let menuItem = OBWFilteringMenuItem(title: "Empty Folder")
            menuItem.enabled = false
            menu.addItem(menuItem)
            
            return false
        }
    }
    
    /*==========================================================================*/
    func filteringMenuItem(withURL url: NSURL, subdirectories: Bool) -> OBWFilteringMenuItem? {
        
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
        
        guard subdirectories, ViewController.isContainerURL(url as URL) else {
            return menuItem
        }
        
        let submenu = OBWFilteringMenu(title: path)
        submenu.delegate = self
        menuItem.submenu = submenu
        
        return menuItem
    }
    #endif // !USE_NSMENU
    
    /*==========================================================================*/
    @objc func selectURL(_ sender: AnyObject?) {
        
        guard
            let menuItem = sender as? NSMenuItem,
            let url = menuItem.representedObject as? URL
        else {
            return
        }
        
        self.configurePathViewToShowURL(url)
    }
    
    /*==========================================================================*/
    // MARK: - ViewController internal
    
    static let titlePrefix = "Title: "
    
    /*==========================================================================*/
    private func pathItemWithInfo(_ info: ItemInfo) -> OBWPathItem {
        
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
    
    /*==========================================================================*/
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
    
    /*==========================================================================*/
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
    
    /*==========================================================================*/
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
