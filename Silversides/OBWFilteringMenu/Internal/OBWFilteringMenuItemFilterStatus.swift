/*===========================================================================
OBWFilteringMenuItemFilterStatus.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import AppKit

extension NSAttributedString.Key {
	/// An attribute that indicates the region of the attributed string matches
	/// a portion of a filter.
	public static let filterMatch = NSAttributedString.Key("com.orderedbytes.Silversides.FilteringMenu.match")
}

/// A class that measures how well a menu item’s title matches a filter string.
class OBWFilteringMenuItemFilterStatus {
	/// Initialization.
	///
	/// - Parameter menuItem: The filtering menu item that the status applies to.
	private init(menuItem: OBWFilteringMenuItem) {
		self.menuItem = menuItem
		
		if let attributedTitle = menuItem.attributedTitle {
			self.searchableTitle = attributedTitle.string
		}
		else if let title = menuItem.title {
			self.searchableTitle = title
		}
		else {
			self.searchableTitle = ""
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
		let statusArray = menu.itemArray.map(OBWFilteringMenuItemFilterStatus.init)
		let filter = Filter(string: filterString)
		
		let dispatchGroup = DispatchGroup()
		statusArray.forEach({ status in
			dispatchGroup.enter()
			DispatchQueue.global(qos: .userInitiated).async {
				status.applyFilter(filter)
				dispatchGroup.leave()
			}
		})
		
		dispatchGroup.wait()
		
		// First pass - create a status for each menu item based on the filter string.  If a heading matched, increment each non-separator item match score until the next unmatched heading.
		var headingMatched = false
		statusArray.forEach({ status in
			if status.menuItem.isHeadingItem {
				headingMatched = status.isMatching
			}
			else if headingMatched, !status.menuItem.isSeparatorItem {
				status.isMatching = true
			}
		})
		
		// Second pass - restore headers that are followed by visible items before the next header.
		var previousHeaderStatus: OBWFilteringMenuItemFilterStatus?
		statusArray.forEach({ status in
			if status.menuItem.isHeadingItem {
				previousHeaderStatus = status
			}
			else if previousHeaderStatus?.isMatching == true {
				return
			}
			else if status.menuItem.isSeparatorItem {
				return
			}
			else if status.isMatching {
				previousHeaderStatus?.isMatching = true
				previousHeaderStatus = nil
			}
		})
		
		if menu.showSeparatorsWhileFiltered == false {
			return statusArray
		}
		
		// Third pass - remove adjacent separators and the first visible separator if there is nothing visible before it.
		var previousSeparatorStatus: OBWFilteringMenuItemFilterStatus? = nil
		var hasVisibleItem = false
		statusArray.forEach({ status in
			if status.menuItem.isSeparatorItem {
				if hasVisibleItem == false {
					status.isMatching = false
				}
				else if previousSeparatorStatus == nil {
					previousSeparatorStatus = status
				}
				else {
					status.isMatching = false
				}
			}
			else if status.menuItem.isHeadingItem {
				if status.isMatching {
					previousSeparatorStatus = status
					hasVisibleItem = true
				}
			}
			else if status.isMatching {
				previousSeparatorStatus = nil
				hasVisibleItem = true
			}
		})
		
		previousSeparatorStatus?.isMatching = false
		
		return statusArray
	}
		
	
	// MARK: - OBWFilteringMenuItemFilterStatus Interface
	
	/// The menu item associated with the filter status.
	let menuItem: OBWFilteringMenuItem
	
	/// An attributed string that is annotated with matching ranges.  Matching
	/// ranges will have the `NSAttributedString.Key.filterMatch` attribute with
	/// a value of `true`.
	private(set) var annotatedTitle: NSAttributedString?
	
	/// Indicates whether the menu item matches the current filter.
	private(set) var isMatching = true
	
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
	
	/// Applies a filter to the receiver.
	///
	/// - Parameter filter: The filter to apply.
	private func applyFilter(_ filter: Filter) {
		if case .empty = filter {
			self.isMatching = true
			self.annotatedTitle = nil
			return
		}
		
		if self.menuItem.isSeparatorItem {
			self.isMatching = (self.menuItem.menu?.showSeparatorsWhileFiltered == true)
			self.annotatedTitle = nil
			return
		}
		
		if case .string(let stringFilter) = filter {
			self.applyStringFilter(stringFilter)
		}
		else if case .regex(let regexFilter) = filter {
			self.applyRegexFilter(regexFilter)
		}
		
		for (_,alternateMenuItem) in self.menuItem.alternates {
			
			let alternateStatus = OBWFilteringMenuItemFilterStatus(menuItem: alternateMenuItem)
			alternateStatus.applyFilter(filter)
			
			let modifierMask = alternateMenuItem.keyEquivalentModifierMask
			self.addAlternateStatus(alternateStatus, withKey: modifierMask.rawValue)
		}
	}
	
	/// Applies the given filter string to the receiver.
	///
	/// - parameter filterString: The filter string to apply.
	private func applyStringFilter(_ filterString: String) {
		let searchableTitle = self.searchableTitle
		let workingAnnotatedTitle = NSMutableAttributedString(string: searchableTitle)
		
		let caseInsensitiveRanges = searchableTitle.rangesOfCharacters(in: filterString, options: .caseInsensitive)
		if caseInsensitiveRanges.isEmpty {
			self.isMatching = false
			self.annotatedTitle = nil
			return
		}
		
		caseInsensitiveRanges.forEach({ subrange in
			let attributeRange = NSRange(
				location: searchableTitle.distance(from: searchableTitle.startIndex, to: subrange.lowerBound),
				length: searchableTitle.distance(from: subrange.lowerBound, to: subrange.upperBound)
			)
			workingAnnotatedTitle.addAttribute(.filterMatch, value: true, range: attributeRange)
		})
		
		self.isMatching = true
		self.annotatedTitle = NSAttributedString(attributedString: workingAnnotatedTitle)
	}
	
	/// Applies the given filter regular expression to the receiver.
	///
	/// - parameter regex: The regular expression to apply.
	private func applyRegexFilter(_ regex: NSRegularExpression) {
		let searchableTitle = self.searchableTitle
		let matchingOptions = NSRegularExpression.MatchingOptions.reportCompletion
		let searchRange = NSRange(
			location: 0,
			length: searchableTitle.distance(from: searchableTitle.startIndex, to: searchableTitle.endIndex)
		)
		
		let matchingRange = regex.rangeOfFirstMatch(in: searchableTitle, options: matchingOptions, range: searchRange)
		if matchingRange.location == NSNotFound {
			self.isMatching = false
			self.annotatedTitle = nil
		}
		else {
			self.isMatching = true
			
			let workingAnnotatedTitle = NSMutableAttributedString(string: searchableTitle)
			workingAnnotatedTitle.addAttribute(.filterMatch, value: true, range: matchingRange)
			self.annotatedTitle = NSAttributedString(attributedString: workingAnnotatedTitle)
		}
	}
	
	
	// MARK: -
	
	/// An enum that identifies a filter type.
	private enum Filter {
		/// A string filter.
		case string(String)
		/// A regular expression filter.
		case regex(NSRegularExpression)
		/// An empty filter
		case empty
		
		init(string: String) {
			if string.isEmpty {
				self = .empty
			}
			else if let expression = try? NSRegularExpression(filterString: string) {
				self = .regex(expression)
			}
			else {
				self = .string(string)
			}
		}
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
