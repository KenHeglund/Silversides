/*===========================================================================
OBWFilteringMenuItemFilterStatusTests.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import XCTest
@testable import OBWControls

class OBWFilteringMenuItemFilterStatusTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testRegexPatternFromString() throws {
		let menuItem = OBWFilteringMenuItem(title: "sampleTitle")
		
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/mp/").matchScore, 3)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "/mp/").matchScore, 0)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/mp").matchScore, 0)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/mp\\/").matchScore, 0)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g//").matchScore, 0)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "gg/mp/").matchScore, 0)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g\\/mp/").matchScore, 0)
	}
	
	func testStringFilterScore() throws {
		let menuItem = OBWFilteringMenuItem(title: "sampleTitle")
		
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "mp").matchScore, 3)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "Mp").matchScore, 2)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "mL").matchScore, 1)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "Tt").matchScore, 2)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "sampleTitlee").matchScore, 0)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "ssampleTitle").matchScore, 0)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "").matchScore, 3)
	}
	
	func testRegExFilterScore() throws {
		let menuItem = OBWFilteringMenuItem(title: "sampleTitle")
		
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/mp/").matchScore, 3)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/[Mm]p/").matchScore, 3)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/[l-p]{4}/").matchScore, 0)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/[as]{2}/").matchScore, 3)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/sampleTitle[0-9]/").matchScore, 0)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/[0-9]sampleTitle/").matchScore, 0)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g//").matchScore, 0)
	}
	
	func testStringFilterHighlight() throws {
		let menuItem = OBWFilteringMenuItem(title: "sampleTitle")
		
		let status = OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "apeil")
		let annotatedTitle = status.annotatedTitle
		XCTAssertNotNil(annotatedTitle)
		
		let highlightIndicies = [ 1,3,5,7,9 ]
		
		for index in 0 ..< annotatedTitle.length {
			if highlightIndicies.contains(index) {
				XCTAssertEqual(annotatedTitle.attribute(.filterMatch, at: index, effectiveRange: nil) as? Bool, true, "\(index)")
			}
			else {
				XCTAssertNil(annotatedTitle.attribute(.filterMatch, at: index, effectiveRange: nil), "\(index)")
			}
		}
	}
	
	func testRegExFilterHighlight() throws {
		let menuItem = OBWFilteringMenuItem(title: "sampleTitle")
		
		let status = OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/[l-p]{3}/")
		let annotatedTitle = status.annotatedTitle
		XCTAssertNotNil(annotatedTitle)
		
		let highlightIndicies = 2...4
		
		for index in 0 ..< annotatedTitle.length {
			if highlightIndicies.contains(index) {
				XCTAssertEqual(annotatedTitle.attribute(.filterMatch, at: index, effectiveRange: nil) as? Bool, true, "\(index)")
			}
			else {
				XCTAssertNil(annotatedTitle.attribute(.filterMatch, at: index, effectiveRange: nil), "\(index)")
			}
		}
	}
	
	func testMenuItemWithAttributedTitle() throws {
		let menuItem = OBWFilteringMenuItem(title: "")
		
		menuItem.attributedTitle = NSAttributedString(
			string: "sampleAttributedTitle",
			attributes: [
				.foregroundColor : NSColor.red,
				.font : NSFont.menuFont(ofSize: 13.0),
			]
		)
		
		let status = OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/t{2,}/")
		let annotatedTitle = status.annotatedTitle
		XCTAssertNotNil(annotatedTitle)
		
		let highlightIndicies = 7...8
		
		for index in 0 ..< annotatedTitle.length {
			if highlightIndicies.contains(index) {
				XCTAssertEqual(annotatedTitle.attribute(.filterMatch, at: index, effectiveRange: nil) as? Bool, true, "\(index)")
			}
			else {
				XCTAssertNil(annotatedTitle.attribute(.filterMatch, at: index, effectiveRange: nil), "\(index)")
			}
		}
	}
	
	func testSeparatorItemMatching() throws {
		let menuItem = OBWFilteringMenuItem.separatorItem
		
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "abc").matchScore, 0)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/abc/").matchScore, 0)
		XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "").matchScore, 3)
	}
	
	func testAlternateMenuItemFiltering() throws {
		let parentMenuItem = OBWFilteringMenuItem(title: "parentItem")
		
		let shiftItem = OBWFilteringMenuItem(title: "shiftItem")
		shiftItem.keyEquivalentModifierMask = [ .shift ]
		try! parentMenuItem.addAlternateItem(shiftItem)
		
		let optionItem = OBWFilteringMenuItem(title: "optionItem")
		optionItem.keyEquivalentModifierMask = [ .option ]
		try! parentMenuItem.addAlternateItem(optionItem)
		
		let commandItem = OBWFilteringMenuItem(title: "commandItem")
		commandItem.keyEquivalentModifierMask = [ .command ]
		try! parentMenuItem.addAlternateItem(commandItem)
		
		let stringFilterStatus = OBWFilteringMenuItemFilterStatus.filterStatus(parentMenuItem, filterString: "tt")
		XCTAssertEqual(stringFilterStatus.matchScore, 2)
		
		let stringFilterAlternates = try XCTUnwrap(stringFilterStatus.alternateStatus)
		
		let shiftKey = NSEvent.ModifierFlags.shift.rawValue
		let optionKey = NSEvent.ModifierFlags.option.rawValue
		let commandKey = NSEvent.ModifierFlags.command.rawValue
		
		XCTAssertEqual(stringFilterAlternates[shiftKey]?.matchScore, 2)
		XCTAssertEqual(stringFilterAlternates[optionKey]?.matchScore, 2)
		XCTAssertEqual(stringFilterAlternates[commandKey]?.matchScore, 0)
		
		let regexFilterStatus = OBWFilteringMenuItemFilterStatus.filterStatus(parentMenuItem, filterString: "g/m{2}/")
		XCTAssertEqual(regexFilterStatus.matchScore, 0)
		
		let regexFilterAlternates = try XCTUnwrap(regexFilterStatus.alternateStatus)
		
		XCTAssertEqual(regexFilterAlternates[shiftKey]?.matchScore, 0)
		XCTAssertEqual(regexFilterAlternates[optionKey]?.matchScore, 0)
		XCTAssertEqual(regexFilterAlternates[commandKey]?.matchScore, 3)
	}
}

extension NSAttributedString {
	/// Indicates whether the receiver uses a font with the given trait at the
	/// given index.
	///
	/// - Parameters:
	///   - trait: The font trait to test for.
	///   - index: The location at which to test the font traits.
	///
	/// - Returns: `true` if the receiver uses a font with `trait` at `index`.
	func hasFontTrait(_ trait: NSFontDescriptor.SymbolicTraits, at index: Int) -> Bool {
		guard let font = self.attribute(.font, at: index, effectiveRange: nil) as? NSFont else {
			return false
		}
		return font.fontDescriptor.symbolicTraits.contains(trait)
	}
}
