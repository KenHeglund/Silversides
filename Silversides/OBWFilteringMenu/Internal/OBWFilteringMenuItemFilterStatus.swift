/*===========================================================================
 OBWFilteringMenuItemFilterStatus.swift
 Silversides
 Copyright (c) 2016 Ken Heglund. All rights reserved.
 ===========================================================================*/

import AppKit

/// A class that measures how well a menu item's title matches a filter string.
class OBWFilteringMenuItemFilterStatus {
    
    /// Initialize from a menu item.
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
    
    /// Return an array of filter status items, one for each menu item in the given menu.
    /// - parameter menu: The menu to build the status objects from.
    /// - parameter filterString: The filter to compare menu items titles to.
    class func filterStatus(_ menu: OBWFilteringMenu, filterString: String) -> [OBWFilteringMenuItemFilterStatus] {
        
        var statusArray: [OBWFilteringMenuItemFilterStatus] = []
        
        // First pass - create a status for each menu item based on the filter string.  If a heading matched, increment each non-separator item match score until the next unmatched heading.
        var headingMatched = false
        
        for menuItem in menu.itemArray {
            
            let status = OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: filterString)
            
            if menuItem.isHeadingItem {
                headingMatched = (status.matchScore != 0)
            }
            else if headingMatched {
                if menuItem.isSeparatorItem == false {
                    status.matchScore += 1
                }
            }
            
            statusArray.append(status)
        }
        
        // Second pass - restore headers that are followed by visible items before the next header.
        var previousHeaderStatus: OBWFilteringMenuItemFilterStatus? = nil
        
        for status in statusArray {
            
            if status.menuItem.isHeadingItem {
                previousHeaderStatus = status
            }
            else if previousHeaderStatus?.matchScore != 0 {
                continue
            }
            else if status.menuItem.isSeparatorItem {
                continue
            }
            else if status.matchScore > 0 {
                previousHeaderStatus?.matchScore += 1
                previousHeaderStatus = nil
            }
        }
        
        if menu.showSeparatorsWhileFiltered == false {
            return statusArray
        }
        
        // Third pass - remove adjacent separators and the first visible separator if there is nothing visible before it.
        var previousSeparatorStatus: OBWFilteringMenuItemFilterStatus? = nil
        var hasVisibleItem = false
        
        for status in statusArray {
            
            if status.menuItem.isSeparatorItem {
                if hasVisibleItem == false {
                    status.matchScore = 0
                }
                else if previousSeparatorStatus == nil {
                    previousSeparatorStatus = status
                }
                else {
                    status.matchScore = 0
                }
            }
            else if status.menuItem.isHeadingItem {
                if status.matchScore > 0 {
                    previousSeparatorStatus = status
                    hasVisibleItem = true
                }
            }
            else if status.matchScore > 0 {
                previousSeparatorStatus = nil
                hasVisibleItem = true
            }
        }
        
        previousSeparatorStatus?.matchScore = 0
        
        return statusArray
    }
    
    /// Returns a status object for the given menu item.
    class func filterStatus(_ menuItem: OBWFilteringMenuItem, filterString: String) -> OBWFilteringMenuItemFilterStatus {
        
        let status = OBWFilteringMenuItemFilterStatus(menuItem: menuItem)
        
        let bestScore = MatchCriteria.memberCount
        let worstScore = 0
        
        guard filterString.isEmpty == false else {
            status.matchScore = bestScore
            return status
        }
        
        if menuItem.isSeparatorItem {
            if menuItem.menu?.showSeparatorsWhileFiltered == true {
                status.matchScore = bestScore
            }
            else {
                status.matchScore = worstScore
            }
            return status
        }
        
        let filter: Filter
        if let regexPattern = try? NSRegularExpression(filterString: filterString) {
            filter = .regex(regexPattern)
        }
        else {
            filter = .string(filterString)
        }
        
        status.applyFilter(filter)
        
        for (_,alternateMenuItem) in menuItem.alternates {
            
            let alternateStatus = OBWFilteringMenuItemFilterStatus(menuItem: alternateMenuItem)
            alternateStatus.applyFilter(filter)

            let modifierMask = alternateMenuItem.keyEquivalentModifierMask
            status.addAlternateStatus(alternateStatus, withKey: modifierMask.rawValue)
        }
        
        return status
    }
    
    
    // MARK: - OBWFilteringMenuItemFilterStatus Interface
    
    /// The menu item associated with the filter status.
    let menuItem: OBWFilteringMenuItem
    
    /// An attributed string highlighting the portion of the menu item's title that matches the filter string.
    private(set) var highlightedTitle: NSAttributedString
    
    /// A score that indicates how well the menu item's title matched the filter string.
    private(set) var matchScore = MatchCriteria.memberCount
    
    /// An arry of status items associated with the menu item's alternate items.
    private(set) var alternateStatus: [OBWFilteringMenuItem.AlternateKey:OBWFilteringMenuItemFilterStatus]? = nil
    
    
    // MARK: - Private
    
    /// A searchable representation of the menu item's title.
    private let searchableTitle: String
    
    /// Adds a status object that applies to an alternate menu item.
    private func addAlternateStatus(_ status: OBWFilteringMenuItemFilterStatus, withKey key: OBWFilteringMenuItem.AlternateKey) {
        
        if self.alternateStatus == nil {
            self.alternateStatus = [:]
        }
        
        self.alternateStatus?[key] = status
    }
    
    /// Returns the NSAttributedString attributes for the highlighted section of a menu item title.
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
            .underlineStyle : 1,
        ]
        
        return highlightAttributes
    }
    
    /// Apples a filter to the receiver.
    private func applyFilter(_ filter: Filter) {
        
        switch filter  {
        case .string(let stringFilter):
            self.applyStringFilter(stringFilter)
        case .regex(let regexFilter):
            self.applyRegexFilter(regexFilter)
        }
    }
    
    /// Applies the given filter string to the receiver.
    /// - parameter filterString: The filter string to apply.
    private func applyStringFilter(_ filterString: String) {
        
        let worstScore = 0
        
        let searchableTitle = self.searchableTitle
        let workingHighlightedTitle = NSMutableAttributedString(attributedString: self.highlightedTitle)
        let highlightAttributes = OBWFilteringMenuItemFilterStatus.highlightAttributes()
        
        var searchRange = searchableTitle.startIndex ..< searchableTitle.endIndex
        var matchMask = MatchCriteria.all
        var lastMatchIndex: String.Index? = nil
        
        for index in filterString.indices {
            
            let filterSubstring = String(filterString[index])
            
            guard let caseInsensitiveRange = searchableTitle.range(of: filterSubstring, options: .caseInsensitive, range: searchRange, locale: nil) else {
                self.matchScore = worstScore
                return
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
        
        self.highlightedTitle = NSAttributedString(attributedString: workingHighlightedTitle)
        self.matchScore = matchMask.memberCount
    }
    
    /// Applies the given filter regular expression to the receiver.
    /// - parameter regex: The regular expression to apply.
    private func applyRegexFilter(_ regex: NSRegularExpression) {
        
        let bestScore = MatchCriteria.memberCount
        let worstScore = 0
        
        let searchableTitle = self.searchableTitle
        let workingHighlightedTitle = NSMutableAttributedString(attributedString: self.highlightedTitle)
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
        
        self.highlightedTitle = NSAttributedString(attributedString: workingHighlightedTitle)
        self.matchScore = matchScore
    }
    
    
    // MARK: -
    
    /// An enum that identifies a filter type.
    private enum Filter {
        /// A string filter.
        case string(String)
        /// A regular expression filter.
        case regex(NSRegularExpression)
    }
    
    
    // MARK: -
    
    /// A struct to track the number of criteria by which a menu item title matches a filter.
    private struct MatchCriteria: OptionSet {
        
        let rawValue: UInt
        
        static let basic = MatchCriteria(rawValue: 1 << 0)
        static let caseSensitive = MatchCriteria(rawValue: 1 << 1)
        static let contiguous = MatchCriteria(rawValue: 1 << 2)
        
        static var all: MatchCriteria = {
            return [.basic, .caseSensitive, .contiguous]
        }()
        
        static var memberCount: Int = {
            return MatchCriteria.all.memberCount
        }()
        
        var memberCount: Int {
            
            let rawValue = self.rawValue
            var bitMask = UInt(0x1)
            var bitCount = 0
            repeat {
                
                if (bitMask & rawValue) != 0 {
                    bitCount += 1
                }
                
                bitMask <<= 1
                
            } while bitMask != 0
            
            return bitCount
        }
    }
}


// MARK: -

private extension NSRegularExpression {
    
    /// Initialize an NSRegularExpression from a filter string.
    convenience init?(filterString: String) throws {
        
        guard
            filterString.hasPrefix( "g/" ),
            filterString.hasSuffix( "/" ),
            filterString.hasSuffix( "\\/" ) == false
        else {
            return nil
        }
        
        let pattern = String(filterString.dropFirst(2).dropLast(1))
        
        try self.init(pattern: pattern, options: .anchorsMatchLines)
    }
}
