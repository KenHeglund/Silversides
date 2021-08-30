/*===========================================================================
OBWFilteringMenuItemFilterStatus.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

/// A class that measures how well a menu item’s title matches a filter string.
class OBWFilteringMenuItemFilterStatus {
	/// Initialization.
	///
	/// - Parameter menuItem: The filtering menu item that the status applies to.
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
	
	/// Creates filter status objects for a menu’s items.
	///
	/// - Parameters:
	///   - menu: The filtering menu to create the status objects for.
	///   - filterString: The filter text to compare the titles of the menu’
	///   items to.
	///
	/// - Returns: An array of filter status objects that correspond to the menu
	/// items in `menu`.  The filter status objects are in the same order as the
	/// menu items.
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
	
	/// Creates a filter status object for a menu item.
	///
	/// - Parameters:
	///   - menuItem: The menu item to create the filter status object for.
	///   - filterString: The filter text to compare the title of the menu item
	///   to.
	///
	/// - Returns: A filter status object that corresponds to the `menuItem`.
	class func filterStatus(_ menuItem: OBWFilteringMenuItem, filterString: String) -> OBWFilteringMenuItemFilterStatus {
		let status = OBWFilteringMenuItemFilterStatus(menuItem: menuItem)
		
		let bestScore = MatchCriteria.totalMemberCount
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
	
	/// An attributed string highlighting the portion of the menu item’s title
	/// that matches the filter string.
	private(set) var highlightedTitle: NSAttributedString
	
	/// A score that indicates how well the menu item’s title matched the filter
	/// string.
	private(set) var matchScore = MatchCriteria.totalMemberCount
	
	/// An arry of status items associated with the menu item’s alternate items.
	private(set) var alternateStatus: [OBWFilteringMenuItem.AlternateKey: OBWFilteringMenuItemFilterStatus]? = nil
	
	
	// MARK: - Private
	
	/// A searchable representation of the menu item’s title.
	private let searchableTitle: String
	
	/// Adds a status object that applies to an alternate menu item.
	private func addAlternateStatus(_ status: OBWFilteringMenuItemFilterStatus, withKey key: OBWFilteringMenuItem.AlternateKey) {
		if self.alternateStatus == nil {
			self.alternateStatus = [:]
		}
		
		self.alternateStatus?[key] = status
	}
	
	/// Returns the `NSAttributedString` attributes for the highlighted section
	/// of a menu item title.
	private class func highlightAttributes() -> [NSAttributedString.Key: Any] {
		let bundle = Bundle(for: OBWFilteringMenu.self)
		let backgroundColor = NSColor(named: "MenuItemHighlightBackground", bundle: bundle) ?? NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
		let underlineColor = NSColor(named: "MenuItemHighlightUnderline", bundle: bundle) ?? NSColor(red: 0.65, green: 0.00, blue: 0.0, alpha: 0.75)
		
		let highlightAttributes: [NSAttributedString.Key: Any] = [
			.backgroundColor : backgroundColor,
			.underlineColor : underlineColor,
			.underlineStyle : 1,
		]
		
		return highlightAttributes
	}
	
	/// Applies a filter to the receiver.
	///
	/// - Parameter filter: The filter to apply.
	private func applyFilter(_ filter: Filter) {
		switch filter  {
			case .string(let stringFilter):
				self.applyStringFilter(stringFilter)
			case .regex(let regexFilter):
				self.applyRegexFilter(regexFilter)
		}
	}
	
	/// Applies the given filter string to the receiver.
	///
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
	///
	/// - parameter regex: The regular expression to apply.
	private func applyRegexFilter(_ regex: NSRegularExpression) {
		let bestScore = MatchCriteria.totalMemberCount
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
	
	/// A struct to track the number of criteria by which a menu item title
	/// matches a filter.
	private struct MatchCriteria: OptionSet {
		/// The raw value of the option set.
		let rawValue: UInt
		
		/// A basic case-insensitive match.
		static let basic = MatchCriteria(rawValue: 1 << 0)
		/// A case-sensitive match.
		static let caseSensitive = MatchCriteria(rawValue: 1 << 1)
		/// A match of contiguous characters.
		static let contiguous = MatchCriteria(rawValue: 1 << 2)
		
		/// All match criteria.
		static let all: MatchCriteria = [.basic, .caseSensitive, .contiguous]
		/// The total number of match criteria.
		static var totalMemberCount = MatchCriteria.all.memberCount
		
		/// The number of matching criteria.
		var memberCount: Int {
			self.rawValue.nonzeroBitCount
		}
	}
}


// MARK: -

private extension NSRegularExpression {
	/// Initialize an `NSRegularExpression` from a filter string.
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
