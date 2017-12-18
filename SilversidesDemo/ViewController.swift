/*===========================================================================
 ViewController.swift
 SilversidesDemo
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa
import OBWControls

/*==========================================================================*/

private class ItemInfo {
    
    enum ItemType {
        
        case volume
        case file
        case tail
    }
    
    let url: URL
    let type: ItemType
    
    init( url: URL, type: ItemType ) {
        self.url = url
        self.type = type
    }
}

/*==========================================================================*/
// MARK: -

class ViewController: NSViewController, NSMenuDelegate, OBWPathViewDelegate, OBWFilteringMenuDelegate {
    
    @IBOutlet var pathViewOutlet: OBWPathView! = nil
    
    fileprivate(set) var pathViewConfigured = false
    
    dynamic var pathViewEnabled = true {
        
        didSet {
            self.pathViewOutlet.enabled = self.pathViewEnabled
        }
    }
    
    dynamic var displayBoldItemTitles = false {
        
        didSet {
            
            for index in 0 ..< self.pathViewOutlet.numberOfItems {
                
                var pathItem = try! self.pathViewOutlet.item( atIndex: index )
                var style = pathItem.style
                
                if style.contains( .bold ) == self.displayBoldItemTitles { continue }
                
                if self.displayBoldItemTitles {
                    style.insert( .bold )
                }
                else {
                    style.remove( .bold )
                }
                
                pathItem.style = style
                
                try! self.pathViewOutlet.setItem( pathItem, atIndex: index )
            }
        }
    }
    
    dynamic var displayItemIcons = true {
        
        didSet {
            
            self.pathViewOutlet.beginPathItemUpdate()
            
            for index in 0 ..< self.pathViewOutlet.numberOfItems {
                
                var pathItem = try! self.pathViewOutlet.item( atIndex: index )
                
                let itemInfo = pathItem.representedObject as! ItemInfo
                if itemInfo.type == .tail {
                    continue
                }
                
                if self.displayItemIcons {
                    pathItem.image = NSWorkspace.shared().icon( forFile: itemInfo.url.path )
                }
                else {
                    pathItem.image = nil
                }
                
                try! self.pathViewOutlet.setItem( pathItem, atIndex: index )
            }
            
            try! self.pathViewOutlet.endPathItemUpdate()
        }
    }
    
    dynamic var displayItemTitlePrefixes = false {
        
        didSet {
            
            for index in 0 ..< self.pathViewOutlet.numberOfItems {
                
                var pathItem = try! self.pathViewOutlet.item( atIndex: index )
                
                if pathItem.title.hasPrefix( ViewController.titlePrefix ) == self.displayItemTitlePrefixes { return }
                
                if self.displayItemTitlePrefixes {
                    pathItem.title = ViewController.titlePrefix + pathItem.title
                }
                else {
                    
                    let range = pathItem.title.range( of: ViewController.titlePrefix )!
                    pathItem.title = pathItem.title.replacingCharacters( in: range, with: "" )
                }
                
                try! self.pathViewOutlet.setItem( pathItem, atIndex: index )
            }
        }
    }
    
    dynamic var volumeColor = NSColor.red {
        
        didSet {
            
            guard self.pathViewOutlet.numberOfItems > 0 else { return }
            
            var volumePathItem = try! self.pathViewOutlet.item( atIndex: 0 )
            volumePathItem.textColor = self.volumeColor
            
            try! self.pathViewOutlet.setItem( volumePathItem, atIndex: 0 )
        }
    }
    
    /*==========================================================================*/
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.pathViewOutlet.delegate = self
        
        let homePath = NSHomeDirectory()
        let homeURL = URL( fileURLWithPath: homePath )
        self.configurePathViewToShowURL( homeURL )
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuDelegate implementation
    
    /*==========================================================================*/
    func willBeginTrackingFilteringMenu( _ menu: OBWFilteringMenu ) {
        
        #if !USE_NSMENU
            guard menu.numberOfItems == 0 else { return }
            
            let parentPath = menu.title
            guard FileManager.default.fileExists( atPath: parentPath ) else { return }
            
            let parentURL = URL(fileURLWithPath: parentPath)
            
            _ = self.populateFilteringMenu( menu, withContentsAtURL: parentURL )
        #endif // !USE_NSMENU
    }
    
    /*==========================================================================*/
    func filteringMenu( _ menu: OBWFilteringMenu, accessibilityHelpForItem menuItem: OBWFilteringMenuItem ) -> String? {
        
        #if !USE_NSMENU
            let menuItemHasSubmenu = ( menuItem.submenu != nil )
            
            let folderFormat = NSLocalizedString( "Click this button to interact with the %@ folder", comment: "Folder menu item help format" ) as NSString
            let fileFormat = NSLocalizedString( "Click this button to select %@", comment: "File menu item help format" ) as NSString
            
            let helpString = NSString( format: ( menuItemHasSubmenu ? folderFormat : fileFormat ), menuItem.title ?? "" )
            
            return helpString as String
        #else
            return nil
        #endif // !USE_NSMENU
    }

    
    #if USE_NSMENU
    /*==========================================================================*/
    // MARK: - NSMenuDelegate implementation
    
    /*==========================================================================*/
    func numberOfItemsInMenu( menu: NSMenu ) -> Int {
        
        let parentPath = menu.title
        guard !parentPath.isEmpty else { return 0 }
        
        let parentURL = NSURL.fileURLWithPath( parentPath )
        
        guard let descendantURLs = ViewController.descendantURLsAtURL( parentURL ) else { return 0 }
        let childCount = descendantURLs.count
        
        return ( childCount > 0 ? childCount : 1 )
    }
    
    /*==========================================================================*/
    func menu( menu: NSMenu, updateItem item: NSMenuItem, atIndex index: Int, shouldCancel: Bool ) -> Bool {
        
        let parentPath = menu.title
        guard !parentPath.isEmpty else { return false }
        guard NSFileManager.defaultManager().fileExistsAtPath( parentPath ) else { return false }
        
        let parentURL = NSURL.fileURLWithPath( parentPath )
        guard let childURLs = ViewController.descendantURLsAtURL( parentURL ) else { return false }
        
        if childURLs.count == 0 && index == 0 {
            item.title = "Empty Folder"
            item.enabled = false
            return true
        }
        
        guard index >= 0 && index < childURLs.count else { return false }
        
        return self.updateMenuItem( item, withURL: childURLs[index] )
    }
    #endif // USE_NSMENU
    
    /*==========================================================================*/
    // MARK: - OBWPathViewDelegate implementation
    
    /*==========================================================================*/
    func pathView( _ pathView: OBWPathView, filteringMenuForItem pathItem: OBWPathItem, trigger: OBWPathItemTrigger ) -> OBWFilteringMenu? {
        
        #if !USE_NSMENU
            let itemInfo = pathItem.representedObject as! ItemInfo
            let itemURL: URL?
            
            switch itemInfo.type {
            case .file:
                itemURL = itemInfo.url.deletingLastPathComponent()
            case .tail:
                itemURL = itemInfo.url
            case .volume:
                itemURL = nil
            }
            
            let menu = OBWFilteringMenu( title: itemURL?.path ?? "" )
            menu.font = NSFont.systemFont( ofSize: 11.0 )
            
            guard self.populateFilteringMenu( menu, withContentsAtURL: itemURL ) else { return nil }
            
            return menu
        #else
            return nil
        #endif
    }
    
    /*==========================================================================*/
    func pathView( _ pathView: OBWPathView, menuForItem pathItem: OBWPathItem, trigger: OBWPathItemTrigger ) -> NSMenu? {
        
        #if USE_NSMENU
            let itemInfo = pathItem.representedObject as! ItemInfo
            let itemURL: NSURL?
            
            switch itemInfo.type {
            case .File:
                itemURL = itemInfo.url.URLByDeletingLastPathComponent!
            case .Tail:
                itemURL = itemInfo.url
            case .Volume:
                itemURL = nil
            }
            
            let menu = NSMenu( title: itemURL?.path ?? "" )
            menu.font = NSFont.systemFontOfSize( 11.0 )
            
            guard self.populateMenu( menu, withContentsAtURL: itemURL ) else { return nil }
            
            return menu
        #else
            return nil
        #endif
    }
    
    /*==========================================================================*/
    func pathViewAccessibilityDescription( _ pathView: OBWPathView ) -> String? {
        
        var url = URL( fileURLWithPath: "/" )
        
        for index in 0..<pathView.numberOfItems {
            
            let pathItem = try! pathView.item( atIndex: index )
            url = url.appendingPathComponent( pathItem.title )
        }
        
        return url.path
    }
    
    /*==========================================================================*/
    func pathViewAccessibilityHelp( _ pathView: OBWPathView ) -> String? {
        return NSLocalizedString( "This identifies the path to the current test item", comment: "Path View help" )
    }
    
    /*==========================================================================*/
    func pathView( _ pathView: OBWPathView, accessibilityHelpForItem: OBWPathItem ) -> String? {
        return NSLocalizedString( "This identifies an element in the path to the current test item", comment: "Path Item View help" )
    }
    
    /*==========================================================================*/
    // MARK: - ViewController implementation
    
    /*==========================================================================*/
    func configurePathViewToShowURL( _ url: URL ) {
        
        self.pathViewOutlet.beginPathItemUpdate()
        
        DispatchQueue.global( qos: DispatchQoS.QoSClass.background).async {
            
            let pathItems = self.pathItemsForURL( url )
            
            DispatchQueue.main.async(execute: {
                self.pathViewOutlet.setItems( pathItems )
                try! self.pathViewOutlet.endPathItemUpdate()
                self.pathViewConfigured = true
            })
        }
        
    }
    
    /*==========================================================================*/
    func pathItemsForURL( _ url: URL ) -> [OBWPathItem] {
        
        // Build array of parent URLs back to the volume URL
        var parentURLArray: [URL] = []
        var parentURL = url
        
        while !ViewController.isVolumeRootURL( parentURL ) {
            
            parentURLArray.append( parentURL )
            
            let newParentURL = parentURL.deletingLastPathComponent()
            guard newParentURL != parentURL else { break }
            parentURL = newParentURL
            
        }
        
        // Volume path item
        let volumeInfo = ItemInfo( url: parentURL, type: .volume )
        var volumeItem = self.pathItemWithInfo( volumeInfo )
        volumeItem.textColor = self.volumeColor
        
        var pathItems = [volumeItem]
        
        // Center path items
        for itemURL in parentURLArray.reversed() {
            let itemInfo = ItemInfo( url: itemURL, type: .file )
            pathItems.append( self.pathItemWithInfo( itemInfo ) )
        }
        
        if !ViewController.isContainerURL( url ) {
            return pathItems
        }
        
        guard let descendantURLs = ViewController.descendantURLsAtURL( url ) else { return pathItems }
        
        // Add a tail path item when displaying a container URL
        let tailItem = OBWPathItem(
            title: ( descendantURLs.isEmpty ? "Empty Folder" : "No Selection" ),
            image: nil,
            representedObject: ItemInfo( url: url, type: .tail ),
            style: [ .italic, .noTextShadow ],
            textColor: NSColor( deviceWhite: 0.0, alpha: 0.5 ),
            accessible: !descendantURLs.isEmpty
        )
        
        pathItems.append( tailItem )
        
        return pathItems
    }
    
    /*==========================================================================*/
    class func isVolumeRootURL( _ url: URL ) -> Bool {
        
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
    class func isContainerURL( _ url: URL ) -> Bool {
        
        guard let resourceValues = try? (url as NSURL).resourceValues( forKeys: [ URLResourceKey.isDirectoryKey, URLResourceKey.isPackageKey ] ) else { return false }
        
        guard let isDirectory = resourceValues[URLResourceKey.isDirectoryKey] as? Bool else { return false }
        guard let isPackage = resourceValues[URLResourceKey.isPackageKey] as? Bool else { return false }
        
        return isDirectory && !isPackage
    }
    
    /*==========================================================================*/
    class func descendantURLsAtURL( _ url: URL? ) -> [URL]? {
        
        let fileManager = FileManager.default
        
        guard let parentURL = url else {
            return fileManager.mountedVolumeURLs( includingResourceValuesForKeys: nil, options: .skipHiddenVolumes )
        }
        
        guard ViewController.isContainerURL( parentURL ) else { return nil }
        
        let directoryOptions: FileManager.DirectoryEnumerationOptions = [
            .skipsSubdirectoryDescendants,
            .skipsPackageDescendants,
            .skipsHiddenFiles,
        ]
        
        guard let enumerator = fileManager.enumerator( at: parentURL, includingPropertiesForKeys: nil, options: directoryOptions, errorHandler: nil ) else { return nil }
        
        let urlArray = enumerator.allObjects as? [URL]
        
        let sortedArray = urlArray?.sorted(by: {
            (firstURL: URL, secondURL: URL) -> Bool in
            return firstURL.path.caseInsensitiveCompare(secondURL.path) == .orderedAscending
        })
        
        return sortedArray
    }
    
    #if USE_NSMENU
    /*==========================================================================*/
    func populateMenu( menu: NSMenu, withContentsAtURL parentURL: NSURL? ) -> Bool {
        
        guard let descendantURLs = ViewController.descendantURLsAtURL( parentURL ) else { return false }
        
        if !descendantURLs.isEmpty {
            
            for childURL in descendantURLs {
                
                let item = NSMenuItem()
                
                guard self.updateMenuItem( item, withURL: childURL ) else { continue }
                
                menu.addItem( item )
            }
            
            return true
        }
        else {
            
            let menuItem = NSMenuItem( title: "Empty Folder", action: nil, keyEquivalent: "" )
            menuItem.enabled = false
            menu.addItem( menuItem )
            
            return false
        }
    }
    
    /*==========================================================================*/
    func updateMenuItem( menuItem: NSMenuItem, withURL url: NSURL ) -> Bool {
        
        let path = url.path!
        let displayName = NSFileManager.defaultManager().displayNameAtPath( path )
        guard !displayName.isEmpty else { return false }
        
        menuItem.title = displayName
        menuItem.target = self
        menuItem.action = #selector(ViewController.selectURL(_:))
        menuItem.representedObject = url
        
        let icon = NSWorkspace.sharedWorkspace().iconForFile( path )
        icon.size = NSSize( width: 17.0, height: 17.0 )
        menuItem.image = icon
        
        if !ViewController.isContainerURL( url ) {
            return true
        }
        
        let submenu = NSMenu( title: path )
        submenu.delegate = self
        submenu.font = NSFont.systemFontOfSize( 11.0 )
        menuItem.submenu = submenu
        
        return true
    }
    #endif // USE_NSMENU
    
    #if !USE_NSMENU
    /*==========================================================================*/
    func populateFilteringMenu( _ menu: OBWFilteringMenu, withContentsAtURL parentURL: URL? ) -> Bool {
        
        // TODO: When navigating via VoiceOver, insert an item at the top of the menu that allows the parent URL to be selected.  Without that item, a URL representing a folder cannot be selected.
        
        guard let descendantURLs = ViewController.descendantURLsAtURL( parentURL ) else { return false }
        
        if !descendantURLs.isEmpty {
            
            for url in descendantURLs {
                
                if let menuItem = self.filteringMenuItem( withURL: url as NSURL ) {
                    menu.addItem( menuItem )
                }
            }
            
            return true
        }
        else {
            
            let menuItem = OBWFilteringMenuItem( title: "Empty Folder" )
            menuItem.enabled = false
            menu.addItem( menuItem )
            
            return false
        }
    }
    
    /*==========================================================================*/
    func filteringMenuItem( withURL url: NSURL ) -> OBWFilteringMenuItem? {
        
        guard let path = url.path else { return nil }
        let displayName = FileManager.default.displayName( atPath: path )
        guard !displayName.isEmpty else { return nil }
        
        let menuItem = OBWFilteringMenuItem( title: displayName )
        menuItem.representedObject = url
        menuItem.actionHandler = {
            [weak self] in
            guard let url = $0.representedObject as? NSURL else { return }
            self?.configurePathViewToShowURL( url as URL )
        }
        
        let icon = NSWorkspace.shared().icon( forFile: path )
        icon.size = NSSize( width: 17.0, height: 17.0 )
        menuItem.image = icon
        
        if !ViewController.isContainerURL( url as URL ) {
            return menuItem
        }
        
        let submenu = OBWFilteringMenu( title: path )
        submenu.delegate = self
        submenu.font = NSFont.systemFont( ofSize: 11.0 )
        menuItem.submenu = submenu
        
        return menuItem
    }
    #endif // !USE_NSMENU
    
    /*==========================================================================*/
    @objc func selectURL( _ sender: AnyObject? ) {
        
        guard let menuItem = sender as? NSMenuItem else { return }
        guard let url = menuItem.representedObject as? URL else { return }
        self.configurePathViewToShowURL( url )
    }
    
    /*==========================================================================*/
    // MARK: - ViewController internal
    
    static let titlePrefix = "Title: "
    /*==========================================================================*/
    fileprivate func pathItemWithInfo( _ info: ItemInfo ) -> OBWPathItem {
        
        let path = info.url.path
        let prefix = ( self.displayItemTitlePrefixes ? ViewController.titlePrefix : "" )
        let title = prefix + FileManager.default.displayName( atPath: path )
        let image: NSImage? = ( self.displayItemIcons ? NSWorkspace.shared().icon( forFile: path ) : nil )
        let style: OBWPathItemStyle = ( self.displayBoldItemTitles ? .bold : .default )
        
        let pathItem = OBWPathItem(
            title: title,
            image: image,
            representedObject: info,
            style: style,
            textColor: nil
        )
        
        return pathItem
    }
    
}
