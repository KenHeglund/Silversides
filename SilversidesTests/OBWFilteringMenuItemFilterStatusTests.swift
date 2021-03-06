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
    
    func testRegexPatternFromString() {
        
        let menuItem = OBWFilteringMenuItem(title: "sampleTitle")
        
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/mp/").matchScore, 3)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "/mp/").matchScore, 0)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/mp").matchScore, 0)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/mp\\/").matchScore, 0)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g//").matchScore, 0)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "gg/mp/").matchScore, 0)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g\\/mp/").matchScore, 0)
    }
    
    func testStringFilterScore() {
        
        let menuItem = OBWFilteringMenuItem(title: "sampleTitle")
        
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "mp").matchScore, 3)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "Mp").matchScore, 2)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "mL").matchScore, 1)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "Tt").matchScore, 2)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "sampleTitlee").matchScore, 0)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "ssampleTitle").matchScore, 0)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "").matchScore, 3)
    }
    
    func testRegExFilterScore() {
        
        let menuItem = OBWFilteringMenuItem(title: "sampleTitle")
        
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/mp/").matchScore, 3)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/[Mm]p/").matchScore, 3)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/[l-p]{4}/").matchScore, 0)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/[as]{2}/").matchScore, 3)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/sampleTitle[0-9]/").matchScore, 0)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/[0-9]sampleTitle/").matchScore, 0)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g//").matchScore, 0)
    }
    
    func testStringFilterHighlight() {
        
        let menuItem = OBWFilteringMenuItem(title: "sampleTitle")
        
        let status = OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "apeil")
        let highlightedTitle = status.highlightedTitle
        XCTAssertNotNil(highlightedTitle)
        
        let underlinedIndicies = [ 1,3,5,7,9 ]
        
        for index in 0 ..< highlightedTitle.length {
            
            if underlinedIndicies.contains(index) {
                XCTAssertNotNil(highlightedTitle.attribute(.underlineStyle, at: index, effectiveRange: nil), "\(index)")
            }
            else {
                XCTAssertNil(highlightedTitle.attribute(.underlineStyle, at: index, effectiveRange: nil), "\(index)")
            }
        }
        
    }
    
    func testRegExFilterHighlight() {
        
        let menuItem = OBWFilteringMenuItem(title: "sampleTitle")
        
        let status = OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/[l-p]{3}/")
        let highlightedTitle = status.highlightedTitle
        XCTAssertNotNil(highlightedTitle)
        
        let underlinedIndicies = 2...4
        
        for index in 0 ..< highlightedTitle.length {
            
            if underlinedIndicies.contains(index) {
                XCTAssertNotNil(highlightedTitle.attribute(.underlineStyle, at: index, effectiveRange: nil), "\(index)")
            }
            else {
                XCTAssertNil(highlightedTitle.attribute(.underlineStyle, at: index, effectiveRange: nil), "\(index)")
            }
        }
        
    }
    
    func testMenuItemWithAttributedTitle() {
        
        let menuItem = OBWFilteringMenuItem(title: "")
        
        menuItem.attributedTitle = NSAttributedString(
            string: "sampleAttributedTitle",
            attributes: [.foregroundColor : NSColor.red]
        )
        
        let status = OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/t{2,}/")
        let highlightedTitle = status.highlightedTitle
        XCTAssertNotNil(highlightedTitle)
        
        let underlinedIndicies = 7...8
        
        for index in 0 ..< highlightedTitle.length {
            
            if underlinedIndicies.contains(index) {
                XCTAssertNotNil(highlightedTitle.attribute(.underlineStyle, at: index, effectiveRange: nil), "\(index)")
            }
            else {
                XCTAssertNil(highlightedTitle.attribute(.underlineStyle, at: index, effectiveRange: nil), "\(index)")
            }
        }
        
    }
    
    func testSeparatorItemMatching() {
        
        let menuItem = OBWFilteringMenuItem.separatorItem
        
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "abc").matchScore, 0)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "g/abc/").matchScore, 0)
        XCTAssertEqual(OBWFilteringMenuItemFilterStatus.filterStatus(menuItem, filterString: "").matchScore, 3)
    }
    
    func testAlternateMenuItemFiltering() {
        
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
        
        guard let stringFilterAlternates = stringFilterStatus.alternateStatus else {
            XCTFail()
            return
        }
        
        let shiftKey = NSEvent.ModifierFlags.shift.rawValue
        let optionKey = NSEvent.ModifierFlags.option.rawValue
        let commandKey = NSEvent.ModifierFlags.command.rawValue
        
        XCTAssertEqual(stringFilterAlternates[shiftKey]?.matchScore, 2)
        XCTAssertEqual(stringFilterAlternates[optionKey]?.matchScore, 2)
        XCTAssertEqual(stringFilterAlternates[commandKey]?.matchScore, 0)
        
        let regexFilterStatus = OBWFilteringMenuItemFilterStatus.filterStatus(parentMenuItem, filterString: "g/m{2}/")
        XCTAssertEqual(regexFilterStatus.matchScore, 0)
        
        guard let regexFilterAlternates = regexFilterStatus.alternateStatus else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(regexFilterAlternates[shiftKey]?.matchScore, 0)
        XCTAssertEqual(regexFilterAlternates[optionKey]?.matchScore, 0)
        XCTAssertEqual(regexFilterAlternates[commandKey]?.matchScore, 3)
    }
    
}
