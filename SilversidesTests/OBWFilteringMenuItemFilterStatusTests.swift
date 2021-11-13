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
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "g/mp/").isMatching, true)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "/mp/").isMatching, false)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "g/mp").isMatching, false)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "g/mp\\/").isMatching, false)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "g//").isMatching, false)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "gg/mp/").isMatching, false)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "g\\/mp/").isMatching, false)
	}
	
	func testStringFilterScore() throws {
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "mp").isMatching, true)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "Mp").isMatching, true)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "mL").isMatching, true)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "Tt").isMatching, true)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "sampleTitlee").isMatching, false)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "ssampleTitle").isMatching, false)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "").isMatching, true)
	}
	
	func testRegExFilterScore() throws {
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "g/mp/").isMatching, true)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "g/[Mm]p/").isMatching, true)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "g/[l-p]{4}/").isMatching, false)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "g/[as]{2}/").isMatching, true)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "g/sampleTitle[0-9]/").isMatching, false)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "g/[0-9]sampleTitle/").isMatching, false)
		XCTAssertEqual(try? filterStatus(menuItemTitle: "sampleText", filterString: "g//").isMatching, false)
	}
	
	func testStringFilterHighlight() throws {
		let filterStatus = try XCTUnwrap(filterStatus(menuItemTitle: "sampleTitle", filterString: "apeil"))
		let annotatedTitle = try XCTUnwrap(filterStatus.annotatedTitle)
		XCTAssertNotNil(annotatedTitle)
		
		let highlightIndicies = [1, 3, 5, 7, 9]
		
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
		let status = try XCTUnwrap(filterStatus(menuItemTitle: "sampleTitle", filterString: "g/[l-p]{3}/"))
		let annotatedTitle = try XCTUnwrap(status.annotatedTitle)
		
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
		
		let menu = OBWFilteringMenu(title: "menu")
		menu.addItems([menuItem])
		
		let status = try XCTUnwrap(OBWFilteringMenuItemFilterStatus.filterStatus(menu, filterString: "g/t{2,}/").first)
		let annotatedTitle = try XCTUnwrap(status.annotatedTitle)
		
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
		XCTAssertEqual(try? filterStatus(menuItemTitle: nil, filterString: "abc").isMatching, false)
		XCTAssertEqual(try? filterStatus(menuItemTitle: nil, filterString: "g/abc/").isMatching, false)
		XCTAssertEqual(try? filterStatus(menuItemTitle: nil, filterString: "").isMatching, true)
	}
	
	func testAlternateMenuItemFiltering() throws {
		let parentMenuItem = OBWFilteringMenuItem(title: "parentItem")
		
		let shiftItem = OBWFilteringMenuItem(title: "shiftItem")
		shiftItem.keyEquivalentModifierMask = [ .shift ]
		try parentMenuItem.addAlternateItem(shiftItem)
		
		let optionItem = OBWFilteringMenuItem(title: "optionItem")
		optionItem.keyEquivalentModifierMask = [ .option ]
		try parentMenuItem.addAlternateItem(optionItem)
		
		let commandItem = OBWFilteringMenuItem(title: "commandItem")
		commandItem.keyEquivalentModifierMask = [ .command ]
		try parentMenuItem.addAlternateItem(commandItem)
		
		let menu = OBWFilteringMenu(title: "menu")
		menu.addItems([parentMenuItem])
		
		let stringFilterStatus = try XCTUnwrap(OBWFilteringMenuItemFilterStatus.filterStatus(menu, filterString: "tt").first)
		XCTAssertTrue(stringFilterStatus.isMatching)
		
		let stringFilterAlternates = try XCTUnwrap(stringFilterStatus.alternateStatus)
		
		let shiftKey = NSEvent.ModifierFlags.shift.rawValue
		let optionKey = NSEvent.ModifierFlags.option.rawValue
		let commandKey = NSEvent.ModifierFlags.command.rawValue
		
		XCTAssertEqual(stringFilterAlternates[shiftKey]?.isMatching, true)
		XCTAssertEqual(stringFilterAlternates[optionKey]?.isMatching, true)
		XCTAssertEqual(stringFilterAlternates[commandKey]?.isMatching, false)
		
		let regexFilterStatus = try XCTUnwrap(OBWFilteringMenuItemFilterStatus.filterStatus(menu, filterString: "g/m{2}/").first)
		XCTAssertFalse(regexFilterStatus.isMatching)
		
		let regexFilterAlternates = try XCTUnwrap(regexFilterStatus.alternateStatus)
		
		XCTAssertEqual(regexFilterAlternates[shiftKey]?.isMatching, false)
		XCTAssertEqual(regexFilterAlternates[optionKey]?.isMatching, false)
		XCTAssertEqual(regexFilterAlternates[commandKey]?.isMatching, true)
	}
	
	/// A helper function that builds the status for a menu item.
	///
	/// - Parameters:
	///   - menuItemTitle: The title of the menu item to build.
	///   - filterString: The filter string to apply to the menu item.
	///   
	/// - Returns: The status of applying `filterString` to a menu item with the title `menuItemTitle`.
	private func filterStatus(menuItemTitle: String?, filterString: String) throws -> OBWFilteringMenuItemFilterStatus {
		let menuItem: OBWFilteringMenuItem
		if let menuItemTitle = menuItemTitle {
			menuItem = OBWFilteringMenuItem(title: menuItemTitle)
		}
		else {
			menuItem = OBWFilteringMenuItem.separatorItem
		}
		let menu = OBWFilteringMenu(title: "menu")
		menu.addItems([menuItem])
		
		let filterStatus = try XCTUnwrap(OBWFilteringMenuItemFilterStatus.filterStatus(menu, filterString: filterString).first, "\(filterString)")
		return filterStatus
	}
}
