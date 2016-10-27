/*===========================================================================
 ViewController.swift
 SilversidesDemo
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa
import OBWControls

/*==========================================================================*/

private class ItemInfo {
    
    enum ItemType {
        
        case Volume
        case File
        case Tail
    }
    
    let URL: NSURL
    let type: ItemType
    
    init( URL: NSURL, type: ItemType ) {
        self.URL = URL
        self.type = type
    }
}

/*==========================================================================*/
// MARK: -

class ViewController: NSViewController, NSMenuDelegate, OBWPathViewDelegate, OBWFilteringMenuDelegate {
    
    @IBOutlet var pathViewOutlet: OBWPathView! = nil
    
    private(set) var pathViewConfigured = false
    
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
                
                if style.contains( .Bold ) == self.displayBoldItemTitles { continue }
                
                if self.displayBoldItemTitles {
                    style = style.union( .Bold )
                }
                else {
                    style = style.subtract( .Bold )
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
                if itemInfo.type == .Tail {
                    continue
                }
                
                if self.displayItemIcons {
                    pathItem.image = NSWorkspace.sharedWorkspace().iconForFile( itemInfo.URL.path! )
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
                    
                    let range = pathItem.title.rangeOfString( ViewController.titlePrefix )!
                    pathItem.title = pathItem.title.stringByReplacingCharactersInRange( range, withString: "" )
                }
                
                try! self.pathViewOutlet.setItem( pathItem, atIndex: index )
            }
        }
    }
    
    dynamic var volumeColor = NSColor.redColor() {
        
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
        let homeURL = NSURL.fileURLWithPath( homePath )
        self.configurePathViewToShowURL( homeURL )
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuDelegate implementation
    
    /*==========================================================================*/
    func willBeginTrackingFilteringMenu( menu: OBWFilteringMenu ) {
        
        #if !USE_NSMENU
            guard menu.numberOfItems == 0 else { return }
            
            let parentPath = menu.title
            guard NSFileManager.defaultManager().fileExistsAtPath( parentPath ) else { return }
            
            let parentURL = NSURL.fileURLWithPath( parentPath )
            
            self.populateFilteringMenu( menu, withContentsAtURL: parentURL )
        #endif // !USE_NSMENU
    }
    
    /*==========================================================================*/
    func filteringMenu( menu: OBWFilteringMenu, accessibilityHelpForItem menuItem: OBWFilteringMenuItem ) -> String? {
        
        #if !USE_NSMENU
            let menuItemHasSubmenu = ( menuItem.submenu != nil )
            
            let folderFormat = NSLocalizedString( "Click this button to interact with the %@ folder", comment: "Folder menu item help format" )
            let fileFormat = NSLocalizedString( "Click this button to select %@", comment: "File menu item help format" )
            
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
    func pathView( pathView: OBWPathView, filteringMenuForItem pathItem: OBWPathItem, trigger: OBWPathItemTrigger ) -> OBWFilteringMenu? {
        
        #if !USE_NSMENU
            let itemInfo = pathItem.representedObject as! ItemInfo
            let itemURL: NSURL?
            
            switch itemInfo.type {
            case .File:
                itemURL = itemInfo.URL.URLByDeletingLastPathComponent!
            case .Tail:
                itemURL = itemInfo.URL
            case .Volume:
                itemURL = nil
            }
            
            let menu = OBWFilteringMenu( title: itemURL?.path ?? "" )
            menu.font = NSFont.systemFontOfSize( 11.0 )
            
            guard self.populateFilteringMenu( menu, withContentsAtURL: itemURL ) else { return nil }
            
            return menu
        #else
            return nil
        #endif
    }
    
    /*==========================================================================*/
    func pathView( pathView: OBWPathView, menuForItem pathItem: OBWPathItem, trigger: OBWPathItemTrigger ) -> NSMenu? {
        
        #if USE_NSMENU
            let itemInfo = pathItem.representedObject as! ItemInfo
            let itemURL: NSURL?
            
            switch itemInfo.type {
            case .File:
                itemURL = itemInfo.URL.URLByDeletingLastPathComponent!
            case .Tail:
                itemURL = itemInfo.URL
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
    func pathViewAccessibilityDescription( pathView: OBWPathView ) -> String? {
        
        var URL: NSURL = NSURL.fileURLWithPath( "/" )
        
        for index in 0..<pathView.numberOfItems {
            
            let pathItem = try! pathView.item( atIndex: index )
            URL = URL.URLByAppendingPathComponent( pathItem.title )!
        }
        
        return URL.path
    }
    
    /*==========================================================================*/
    func pathViewAccessibilityHelp( pathView: OBWPathView ) -> String? {
        return NSLocalizedString( "This identifies the path to the current test item", comment: "Path View help" )
    }
    
    /*==========================================================================*/
    func pathView( pathView: OBWPathView, accessibilityHelpForItem: OBWPathItem ) -> String? {
        return NSLocalizedString( "This identifies an element in the path to the current test item", comment: "Path Item View help" )
    }
    
    /*==========================================================================*/
    // MARK: - ViewController implementation
    
    /*==========================================================================*/
    func configurePathViewToShowURL( URL: NSURL ) {
        
        self.pathViewOutlet.beginPathItemUpdate()
        
        dispatch_async( dispatch_get_global_queue( QOS_CLASS_BACKGROUND, 0 ) ) {
            
            let pathItems = self.pathItemsForURL( URL )
            
            dispatch_async( dispatch_get_main_queue(), {
                self.pathViewOutlet.setItems( pathItems )
                try! self.pathViewOutlet.endPathItemUpdate()
                self.pathViewConfigured = true
            })
        }
        
    }
    
    /*==========================================================================*/
    func pathItemsForURL( URL: NSURL ) -> [OBWPathItem] {
        
        // Build array of parent URLs back to the volume URL
        var parentURLArray: [NSURL] = []
        var parentURL = URL
        
        while !ViewController.isVolumeRootURL( parentURL ) {
            
            parentURLArray.append( parentURL )
            
            guard let newParentURL = parentURL.URLByDeletingLastPathComponent else { break }
            parentURL = newParentURL
            
        }
        
        // Volume path item
        let volumeInfo = ItemInfo( URL: parentURL, type: .Volume )
        var volumeItem = self.pathItemWithInfo( volumeInfo )
        volumeItem.textColor = self.volumeColor
        
        var pathItems = [volumeItem]
        
        // Center path items
        for itemURL in parentURLArray.reverse() {
            let itemInfo = ItemInfo( URL: itemURL, type: .File )
            pathItems.append( self.pathItemWithInfo( itemInfo ) )
        }
        
        if !ViewController.isContainerURL( URL ) {
            return pathItems
        }
        
        guard let descendantURLs = ViewController.descendantURLsAtURL( URL ) else { return pathItems }
        
        // Add a tail path item when displaying a container URL
        let tailItem = OBWPathItem(
            title: ( descendantURLs.isEmpty ? "Empty Folder" : "No Selection" ),
            image: nil,
            representedObject: ItemInfo( URL: URL, type: .Tail ),
            style: [ .Italic, .NoTextShadow ],
            textColor: NSColor( deviceWhite: 0.0, alpha: 0.5 ),
            accessible: !descendantURLs.isEmpty
        )
        
        pathItems.append( tailItem )
        
        return pathItems
    }
    
    /*==========================================================================*/
    class func isVolumeRootURL( URL: NSURL ) -> Bool {
        
        guard let lastPathComponent = URL.lastPathComponent else { return false }
        guard let relativePath = URL.relativePath else { return false }
        if lastPathComponent == relativePath {
            return true
        }
        
        guard let shortenedPath = URL.URLByDeletingLastPathComponent?.path else { return false }
        if shortenedPath == "/Volumes" {
            return true
        }
        
        return false
    }
    
    /*==========================================================================*/
    class func isContainerURL( URL: NSURL ) -> Bool {
        
        guard let resourceValues = try? URL.resourceValuesForKeys( [ NSURLIsDirectoryKey, NSURLIsPackageKey ] ) else { return false }
        
        guard let isDirectory = resourceValues[NSURLIsDirectoryKey] as? Bool else { return false }
        guard let isPackage = resourceValues[NSURLIsPackageKey] as? Bool else { return false }
        
        return isDirectory && !isPackage
    }
    
    /*==========================================================================*/
    class func descendantURLsAtURL( URL: NSURL? ) -> [NSURL]? {
        
        let fileManager = NSFileManager.defaultManager()
        
        guard let parentURL = URL else {
            return fileManager.mountedVolumeURLsIncludingResourceValuesForKeys( nil, options: .SkipHiddenVolumes )
        }
        
        guard ViewController.isContainerURL( parentURL ) else { return nil }
        
        let directoryOptions: NSDirectoryEnumerationOptions = [
            .SkipsSubdirectoryDescendants,
            .SkipsPackageDescendants,
            .SkipsHiddenFiles,
            ]
        
        guard let enumerator = fileManager.enumeratorAtURL( parentURL, includingPropertiesForKeys: nil, options: directoryOptions, errorHandler: nil ) else { return nil }
        
        let urlArray = enumerator.allObjects as? [NSURL]
        
        return urlArray
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
    func updateMenuItem( menuItem: NSMenuItem, withURL URL: NSURL ) -> Bool {
        
        let path = URL.path!
        let displayName = NSFileManager.defaultManager().displayNameAtPath( path )
        guard !displayName.isEmpty else { return false }
        
        menuItem.title = displayName
        menuItem.target = self
        menuItem.action = #selector(ViewController.selectURL(_:))
        menuItem.representedObject = URL
        
        let icon = NSWorkspace.sharedWorkspace().iconForFile( path )
        icon.size = NSSize( width: 17.0, height: 17.0 )
        menuItem.image = icon
        
        if !ViewController.isContainerURL( URL ) {
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
    func populateFilteringMenu( menu: OBWFilteringMenu, withContentsAtURL parentURL: NSURL? ) -> Bool {
        
        // TODO: When navigating via VoiceOver, insert an item at the top of the menu that allows the parent URL to be selected.  Without that item, a URL representing a folder cannot be selected.
        
        guard let descendantURLs = ViewController.descendantURLsAtURL( parentURL ) else { return false }
        
        if !descendantURLs.isEmpty {
            
            for URL in descendantURLs {
                
                if let menuItem = self.filteringMenuItem( withURL: URL ) {
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
    func filteringMenuItem( withURL URL: NSURL ) -> OBWFilteringMenuItem? {
        
        guard let path = URL.path else { return nil }
        let displayName = NSFileManager.defaultManager().displayNameAtPath( path )
        guard !displayName.isEmpty else { return nil }
        
        let menuItem = OBWFilteringMenuItem( title: displayName )
        menuItem.representedObject = URL
        menuItem.actionHandler = {
            [weak self] in
            guard let URL = $0.representedObject as? NSURL else { return }
            self?.configurePathViewToShowURL( URL )
        }
        
        let icon = NSWorkspace.sharedWorkspace().iconForFile( path )
        icon.size = NSSize( width: 17.0, height: 17.0 )
        menuItem.image = icon
        
        if !ViewController.isContainerURL( URL ) {
            return menuItem
        }
        
        let submenu = OBWFilteringMenu( title: path )
        submenu.delegate = self
        submenu.font = NSFont.systemFontOfSize( 11.0 )
        menuItem.submenu = submenu
        
        return menuItem
    }
    #endif // !USE_NSMENU
    
    /*==========================================================================*/
    @objc func selectURL( sender: AnyObject? ) {
        
        guard let menuItem = sender as? NSMenuItem else { return }
        guard let URL = menuItem.representedObject as? NSURL else { return }
        self.configurePathViewToShowURL( URL )
    }
    
    /*==========================================================================*/
    // MARK: - ViewController internal
    
    static let titlePrefix = "Title: "
    /*==========================================================================*/
    private func pathItemWithInfo( info: ItemInfo ) -> OBWPathItem {
        
        let path = info.URL.path!
        let prefix = ( self.displayItemTitlePrefixes ? ViewController.titlePrefix : "" )
        let title = prefix + NSFileManager.defaultManager().displayNameAtPath( path )
        let image: NSImage? = ( self.displayItemIcons ? NSWorkspace.sharedWorkspace().iconForFile( path ) : nil )
        let style: OBWPathItemStyle = ( self.displayBoldItemTitles ? .Bold : .Default )
        
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
