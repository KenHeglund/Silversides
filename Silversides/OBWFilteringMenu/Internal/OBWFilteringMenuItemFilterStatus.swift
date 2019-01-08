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
    private init(menuItem: OBWFilteringMenuItem) {
        
        self.menuItem = menuItem
        
        if let attributedTitle = menuItem.attributedTitle {
            self.searchableTitle = attributedTitle.string
            self.highlightedTitle = NSAttributedString(attributedString: attributedTitle)
        }
        else if let title = menuItem.title {
            
            self.searchableTitle = title
            
            let attributes = [NSAttributedString.Key.font : menuItem.font]
            self.highlightedTitle = NSAttributedString(string: title, attributes: attributes)
        }
        else {
            self.searchableTitle = ""
            self.highlightedTitle = NSAttributedString()
        }
    }
    
    /*==========================================================================*/
    class func filterStatus(_ menu: OBWFilteringMenu, filterString: String) -> [OBWFilteringMenuItemFilterStatus] {
        
        var statusArray: [OBWFilteringMenuItemFilterStatus] = []
        
        // First pass - filter items by filterString, keep all headings
        for menuItem in menu.itemArray {
            statusArray.append(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: filterString))
        }
        
        // Second pass - filter headings that do not have any visible items following them
        var headingStatusToHide: OBWFilteringMenuItemFilterStatus? = nil
        
        for status in statusArray {
            
            if status.menuItem.isHeading == false {
                
                if status.matchScore > 0 {
                    headingStatusToHide = nil
                }
            }
            else {
                
                headingStatusToHide?.matchScore = 0
                headingStatusToHide = status
            }
        }
        
        headingStatusToHide?.matchScore = 0
        
        return statusArray
    }
    
    /*==========================================================================*/
    class func filterStatus(_ menuItem: OBWFilteringMenuItem, filterString: String) -> OBWFilteringMenuItemFilterStatus {
        
        let status = OBWFilteringMenuItemFilterStatus(menuItem: menuItem)
        
        let bestScore = OBWFilteringMenuItemMatchCriteria.all.memberCount
        let worstScore = 0
        
        guard filterString.isEmpty == false else {
            status.matchScore = bestScore
            return status
        }
        
        guard menuItem.isSeparatorItem == false && status.searchableTitle.isEmpty == false else {
            status.matchScore = worstScore
            return status
        }
        
        guard menuItem.isHeading == false else {
            status.matchScore = bestScore
            return status
        }
        
        let filterFunction: (OBWFilteringMenuItemFilterStatus, FilterArgument) -> Int
        let filterArgument: FilterArgument
        
        if let regexPattern = OBWFilteringMenuItemFilterStatus.regexPatternFromString(filterString) {
            filterFunction = OBWFilteringMenuItemFilterStatus.filter(_:withRegularExpression:)
            filterArgument = regexPattern
        }
        else {
            filterFunction = OBWFilteringMenuItemFilterStatus.filter(_:withString:)
            filterArgument = filterString
        }
        
        status.matchScore = filterFunction(status, filterArgument)
        
        for (_,alternateMenuItem) in menuItem.alternates {
            
            let alternateStatus = OBWFilteringMenuItemFilterStatus(menuItem: alternateMenuItem)
            alternateStatus.matchScore = filterFunction(alternateStatus, filterArgument)
            
            let modifierMask = alternateMenuItem.keyEquivalentModifierMask
            let key = OBWFilteringMenuItem.dictionaryKeyWithModifierMask(modifierMask)
            status.addAlternateStatus(alternateStatus, withKey: key)
        }
        
        return status
    }
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuItemFilterStatus internal
    
    let menuItem: OBWFilteringMenuItem
    private(set) var highlightedTitle: NSAttributedString
    private(set) var matchScore = OBWFilteringMenuItemMatchCriteria.all.memberCount
    private(set) var alternateStatus: [String:OBWFilteringMenuItemFilterStatus]? = nil
    
    /*==========================================================================*/
    // MARK: - OBWFilteringMenuItemFilterStatus private
    
    private let searchableTitle: String
    
    /*==========================================================================*/
    private class func regexPatternFromString(_ filterString: String) -> NSRegularExpression? {
        
        var pattern = filterString
        
        guard
            filterString.hasPrefix( "g/" ),
            filterString.hasSuffix( "/" ),
            filterString.hasSuffix( "\\/" ) == false
        else {
            return nil
        }
        
        pattern = pattern.replacingOccurrences(of: "g/", with: "", options: [.anchored], range: nil)
        pattern = pattern.replacingOccurrences(of: "/", with: "", options: [.anchored, .backwards], range: nil)
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) {
            return regex
        }
        
        return nil
    }
    
    /*==========================================================================*/
    private func addAlternateStatus(_ status: OBWFilteringMenuItemFilterStatus, withKey key: String) {
        
        if self.alternateStatus == nil {
            self.alternateStatus = [:]
        }
        
        self.alternateStatus?[key] = status
    }
    
    /*==========================================================================*/
    private class func highlightAttributes() -> [NSAttributedString.Key:Any] {
        
        var backgroundColor = NSColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 0.5)
        var underlineColor = NSColor(red: 0.65, green: 0.50, blue: 0.0, alpha: 0.75)
        
        if #available(macOS 10.14, *) {
            
            let knownAppearances: [NSAppearance.Name] = [.aqua, .darkAqua]
            
            if NSApp.effectiveAppearance.bestMatch(from: knownAppearances) == .darkAqua {
                backgroundColor = NSColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 0.25)
                underlineColor = NSColor(red: 0.85, green: 0.70, blue: 0.0, alpha: 0.75)
            }
        }
        
        let highlightAttributes: [NSAttributedString.Key:Any] = [
            .backgroundColor : backgroundColor,
            .underlineColor : underlineColor,
            .underlineStyle : 1 as AnyObject,
        ]
        
        return highlightAttributes
    }

    /*==========================================================================*/
    private class func filter(_ status: OBWFilteringMenuItemFilterStatus, withString filterArgument: FilterArgument) -> Int {
        
        let worstScore = 0
        
        guard let filterString = filterArgument as? String else {
            preconditionFailure("Expecting a String instance as the filterArgument")
        }
        
        let searchableTitle = status.searchableTitle
        let workingHighlightedTitle = NSMutableAttributedString(attributedString: status.highlightedTitle)
        let highlightAttributes = OBWFilteringMenuItemFilterStatus.highlightAttributes()

        var searchRange = searchableTitle.startIndex ..< searchableTitle.endIndex
        var matchMask = OBWFilteringMenuItemMatchCriteria.all
        var lastMatchIndex: String.Index? = nil
        
        for index in filterString.indices {
            
            let filterSubstring = String(filterString[index])
            
            guard let caseInsensitiveRange = searchableTitle.range(of: filterSubstring, options: .caseInsensitive, range: searchRange, locale: nil) else {
                return worstScore
            }
            
            if
                matchMask.contains(.caseSensitive),
                let caseSensitiveRange = searchableTitle.range(of: filterSubstring, options: .literal, range: searchRange, locale: nil),
                caseSensitiveRange == caseInsensitiveRange
            {
                // allow the case-sensitive flag to persist...
            }
            else {
                matchMask.remove(.caseSensitive)
            }
            
            if let lastMatchIndex = lastMatchIndex {
                
                if caseInsensitiveRange.lowerBound != searchableTitle.index(after: lastMatchIndex) {
                    matchMask.remove(.contiguous)
                }
            }
            
            let highlightRange = NSRange(
                location: searchableTitle.distance(from: searchableTitle.startIndex, to: caseInsensitiveRange.lowerBound),
                length: 1
            )
            
            workingHighlightedTitle.addAttributes(highlightAttributes, range: highlightRange)
            
            lastMatchIndex = caseInsensitiveRange.lowerBound
            searchRange = caseInsensitiveRange.upperBound ..< searchableTitle.endIndex
        }
        
        status.highlightedTitle = NSAttributedString(attributedString: workingHighlightedTitle)
        
        return matchMask.memberCount
    }
    
    /*==========================================================================*/
    private class func filter(_ status: OBWFilteringMenuItemFilterStatus, withRegularExpression filterArgument: FilterArgument) -> Int {
        
        let bestScore = OBWFilteringMenuItemMatchCriteria.all.memberCount
        let worstScore = 0
        
        guard let regex = filterArgument as? NSRegularExpression else {
            preconditionFailure("expecting an NSRegularExpression instance as the filterArgument")
        }
        
        let searchableTitle = status.searchableTitle
        let workingHighlightedTitle = NSMutableAttributedString(attributedString: status.highlightedTitle)
        let highlightAttributes = OBWFilteringMenuItemFilterStatus.highlightAttributes()
        
        var matchScore = worstScore
        let matchingOptions = NSRegularExpression.MatchingOptions.reportCompletion
        let searchRange = NSRange(location: 0, length: searchableTitle.distance(from: searchableTitle.startIndex, to: searchableTitle.endIndex))
        
        regex.enumerateMatches(in: searchableTitle, options: matchingOptions, range: searchRange) {
            (result: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool> ) in
            
            guard flags.contains(.internalError) == false else {
                stop.pointee = true
                return
            }
            
            guard let result = result else {
                return
            }
            
            for rangeIndex in 0 ..< result.numberOfRanges {
                
                let resultRange = result.range(at: rangeIndex)
                guard resultRange.location != NSNotFound else {
                    continue
                }
                
                matchScore = bestScore
                
                workingHighlightedTitle.addAttributes(highlightAttributes, range: resultRange)
            }
        }
        
        status.highlightedTitle = NSAttributedString(attributedString: workingHighlightedTitle)
        
        return matchScore
    }
    
    /*==========================================================================*/
    // MARK: -
    
    /*==========================================================================*/
    private struct OBWFilteringMenuItemMatchCriteria: OptionSet {
        
        init(rawValue: UInt) {
            self.rawValue = rawValue & 0x7
        }
        
        private(set) var rawValue: UInt
        
        static let basic            = OBWFilteringMenuItemMatchCriteria(rawValue: 1 << 0)
        static let caseSensitive    = OBWFilteringMenuItemMatchCriteria(rawValue: 1 << 1)
        static let contiguous       = OBWFilteringMenuItemMatchCriteria(rawValue: 1 << 2)
        
        static let all = OBWFilteringMenuItemMatchCriteria(rawValue: 0x7)
        static let last = OBWFilteringMenuItemMatchCriteria.contiguous
        
        var memberCount: Int {
            
            let rawValue = self.rawValue
            var bitMask = OBWFilteringMenuItemMatchCriteria.last.rawValue
            var bitCount = 0
            repeat {
                
                if (bitMask & rawValue) != 0 {
                    bitCount += 1
                }
                
                bitMask >>= 1
                
            } while bitMask != 0
            
            return bitCount
        }
    }
}
