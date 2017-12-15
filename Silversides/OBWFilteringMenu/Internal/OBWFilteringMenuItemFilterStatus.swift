/*===========================================================================
 OBWFilteringMenuItemFilterStatus.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

private protocol FilterArgument {}
extension String: FilterArgument {}
extension NSRegularExpression: FilterArgument {}

/*==========================================================================*/

class OBWFilteringMenuItemFilterStatus {
    
    /*==========================================================================*/
    fileprivate init( menuItem: OBWFilteringMenuItem ) {
        
        self.menuItem = menuItem
        
        if let attributedTitle = menuItem.attributedTitle {
            self.searchableTitle = attributedTitle.string
            self.highlightedTitle = NSAttributedString( attributedString: attributedTitle )
        }
        else if let title = menuItem.title {
            
            self.searchableTitle = title
            
            let attributes = [ NSFontAttributeName : menuItem.font ]
            self.highlightedTitle = NSAttributedString( string: title, attributes: attributes )
        }
        else {
            self.searchableTitle = ""
            self.highlightedTitle = NSAttributedString()
        }
    }
    
    /*==========================================================================*/
    class func filterStatus( _ menu: OBWFilteringMenu, filterString: String ) -> [OBWFilteringMenuItemFilterStatus] {
        
        var statusArray: [OBWFilteringMenuItemFilterStatus] = []
        
        for menuItem in menu.itemArray {
            statusArray.append( OBWFilteringMenuItemFilterStatus.filterStatus( menuItem, filterString: filterString ) )
        }
        
        return statusArray
    }
    
    /*==========================================================================*/
    class func filterStatus( _ menuItem: OBWFilteringMenuItem, filterString: String ) -> OBWFilteringMenuItemFilterStatus {
        
        let status = OBWFilteringMenuItemFilterStatus( menuItem: menuItem )
        
        let bestScore = OBWFilteringMenuItemMatchCriteria.All.memberCount
        let worstScore = 0
        
        guard !filterString.isEmpty else {
            status.matchScore = bestScore
            return status
        }
        
        guard !menuItem.isSeparatorItem && !status.searchableTitle.isEmpty else {
            status.matchScore = worstScore
            return status
        }
        
        let filterFunction: ( OBWFilteringMenuItemFilterStatus, FilterArgument ) -> Int
        let filterArgument: FilterArgument
        
        if let regexPattern = OBWFilteringMenuItemFilterStatus.regexPatternFromString( filterString ) {
            filterFunction = OBWFilteringMenuItemFilterStatus.filter(_:withRegularExpression:)
            filterArgument = regexPattern
        }
        else {
            filterFunction = OBWFilteringMenuItemFilterStatus.filter(_:withString:)
            filterArgument = filterString
        }
        
        status.matchScore = filterFunction( status, filterArgument )
        
        for (_,alternateMenuItem) in menuItem.alternates {
            
            let alternateStatus = OBWFilteringMenuItemFilterStatus( menuItem: alternateMenuItem )
            alternateStatus.matchScore = filterFunction( alternateStatus, filterArgument )
            
            let modifierMask = alternateMenuItem.keyEquivalentModifierMask
            let key = OBWFilteringMenuItem.dictionaryKeyWithModifierMask( modifierMask )
            status.addAlternateStatus( alternateStatus, withKey: key )
        }
        
        return status
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuItemFilterStatus internal
    
    let menuItem: OBWFilteringMenuItem
    fileprivate(set) var highlightedTitle: NSAttributedString
    fileprivate(set) var matchScore = OBWFilteringMenuItemMatchCriteria.All.memberCount
    fileprivate(set) var alternateStatus: [String:OBWFilteringMenuItemFilterStatus]? = nil
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuItemFilterStatus private
    
    fileprivate let searchableTitle: String
    
    /*==========================================================================*/
    fileprivate class func regexPatternFromString( _ filterString: String ) -> NSRegularExpression? {
        
        var pattern = filterString
        
        guard filterString.hasPrefix( "g/" ) else { return nil }
        guard filterString.hasSuffix( "/" ) else { return nil }
        guard !filterString.hasSuffix( "\\/" ) else { return nil }
        
        pattern = pattern.replacingOccurrences( of: "g/", with: "", options: [ .anchored ], range: nil )
        pattern = pattern.replacingOccurrences( of: "/", with: "", options: [ .anchored, .backwards ], range: nil )
        
        if let regex = try? NSRegularExpression( pattern: pattern, options: .anchorsMatchLines ) {
            return regex
        }
        
        return nil
    }
    
    /*==========================================================================*/
    fileprivate func addAlternateStatus( _ status: OBWFilteringMenuItemFilterStatus, withKey key: String ) {
        
        if self.alternateStatus == nil {
            self.alternateStatus = [key:status]
        }
        else {
            self.alternateStatus![key] = status
        }
    }
    
    /*==========================================================================*/
    fileprivate static var highlightAttributes: [String:AnyObject] = [
        NSBackgroundColorAttributeName : NSColor( deviceRed: 1.0, green: 1.0, blue: 0.0, alpha: 0.5 ),
        NSUnderlineStyleAttributeName : 1 as AnyObject,
        NSUnderlineColorAttributeName : NSColor( deviceRed: 0.65, green: 0.50, blue: 0.0, alpha: 0.75 ),
    ]
    
    /*==========================================================================*/
    fileprivate class func filter( _ status: OBWFilteringMenuItemFilterStatus, withString filterArgument: FilterArgument ) -> Int {
        
        let worstScore = 0
        
        guard let filterString = filterArgument as? String else {
            preconditionFailure( "Expecting a String instance as the filterArgument" )
        }
        
        let searchableTitle = status.searchableTitle
        let workingHighlightedTitle = NSMutableAttributedString( attributedString: status.highlightedTitle )
        let highlightAttributes = OBWFilteringMenuItemFilterStatus.highlightAttributes
        
        var searchRange = searchableTitle.startIndex ..< searchableTitle.endIndex
        var matchMask = OBWFilteringMenuItemMatchCriteria.All
        var lastMatchIndex: String.Index? = nil
        
        for sourceIndex in filterString.characters.indices {
            
            guard !searchRange.isEmpty else { return worstScore }
            
            let filterSubstring = filterString.substring( with: sourceIndex ..< filterString.index(after: sourceIndex) )
            
            guard let caseInsensitiveRange = searchableTitle.range( of: filterSubstring, options: .caseInsensitive, range: searchRange, locale: nil ) else { return worstScore }
            
            let caseSensitiveRange = searchableTitle.range( of: filterSubstring, options: .literal, range: searchRange, locale: nil )
            
            if caseSensitiveRange == nil || caseInsensitiveRange != caseSensitiveRange! {
                matchMask.remove( .CaseSensitive )
            }
            
            if let lastMatchIndex = lastMatchIndex {
                
                if caseInsensitiveRange.lowerBound != searchableTitle.index(after: lastMatchIndex) {
                    matchMask.remove( .Contiguous )
                }
            }
            
            let highlightRange = NSRange(
                location: searchableTitle.characters.distance(from: searchableTitle.startIndex, to: caseInsensitiveRange.lowerBound),
                length: 1
            )
            
            workingHighlightedTitle.addAttributes( highlightAttributes, range: highlightRange )
            
            lastMatchIndex = caseInsensitiveRange.lowerBound
            searchRange = caseInsensitiveRange.upperBound ..< searchableTitle.endIndex
        }
        
        status.highlightedTitle = NSAttributedString( attributedString: workingHighlightedTitle )
        
        return matchMask.memberCount
    }
    
    /*==========================================================================*/
    fileprivate class func filter( _ status: OBWFilteringMenuItemFilterStatus, withRegularExpression filterArgument: FilterArgument ) -> Int {
        
        let bestScore = OBWFilteringMenuItemMatchCriteria.All.memberCount
        let worstScore = 0
        
        guard let regex = filterArgument as? NSRegularExpression else {
            preconditionFailure( "expecting an NSRegularExpression instance as the filterArgument" )
        }
        
        let searchableTitle = status.searchableTitle
        let workingHighlightedTitle = NSMutableAttributedString( attributedString: status.highlightedTitle )
        let highlightAttributes = OBWFilteringMenuItemFilterStatus.highlightAttributes
        
        var matchScore = worstScore
        let matchingOptions = NSRegularExpression.MatchingOptions.reportCompletion
        let searchRange = NSRange( location: 0, length: searchableTitle.characters.distance(from: searchableTitle.startIndex, to: searchableTitle.endIndex) )
        
        regex.enumerateMatches( in: searchableTitle, options: matchingOptions, range: searchRange) { ( result: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool> ) in
            
            guard !flags.contains( .internalError ) else {
                stop.pointee = true
                return
            }
            
            guard let result = result else { return }
            
            for rangeIndex in 0 ..< result.numberOfRanges {
                
                let resultRange = result.rangeAt( rangeIndex )
                guard resultRange.location != NSNotFound else { continue }
                
                matchScore = bestScore
                
                workingHighlightedTitle.addAttributes( highlightAttributes, range: resultRange )
            }
        }
        
        status.highlightedTitle = NSAttributedString( attributedString: workingHighlightedTitle )
        
        return matchScore
    }
    
    /*==========================================================================*/
    // MARK: -
    
    /*==========================================================================*/
    fileprivate struct OBWFilteringMenuItemMatchCriteria: OptionSet {
        
        init( rawValue: UInt ) {
            self.rawValue = rawValue & 0x7
        }
        
        fileprivate(set) var rawValue: UInt
        
        static let Basic            = OBWFilteringMenuItemMatchCriteria( rawValue: 1 << 0 )
        static let CaseSensitive    = OBWFilteringMenuItemMatchCriteria( rawValue: 1 << 1 )
        static let Contiguous       = OBWFilteringMenuItemMatchCriteria( rawValue: 1 << 2 )
        
        static let All = OBWFilteringMenuItemMatchCriteria( rawValue: 0x7 )
        static let Last = OBWFilteringMenuItemMatchCriteria.Contiguous
        
        var memberCount: Int {
            
            let rawValue = self.rawValue
            var bitMask = OBWFilteringMenuItemMatchCriteria.Last.rawValue
            var bitCount = 0
            repeat {
                
                if ( bitMask & rawValue ) != 0 {
                    bitCount += 1
                }
                
                bitMask >>= 1
                
            } while bitMask != 0
            
            return bitCount
        }
    }
    
}
