/*===========================================================================
CaseLocalizableTests.swift
Silversides
Copyright (c) 2021 Ken Heglund. All rights reserved.
===========================================================================*/

import XCTest

@testable import OBWControls

enum TopLevelLocalizable: CaseLocalizable {
	case first
	case second
}

class CaseLocalizableTests: XCTestCase {
	enum EnclosedLocalizable: CaseLocalizable {
		case first
		case second
	}
	
	struct EnclosingStruct {
		enum DoubleEnclosedLocalizable: CaseLocalizable {
			case first
			case second
		}
	}
	
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}
	
	func testTopLevelKey() throws {
		XCTAssertEqual(TopLevelLocalizable.first.localizationKey, "SilversidesTests.TopLevelLocalizable.first")
	}
	
	func testEnclosedKey() throws {
		XCTAssertEqual(EnclosedLocalizable.first.localizationKey, "CaseLocalizableTests.first")
	}
	
	func testDoubleEnclosedKey() throws {
		XCTAssertEqual(EnclosingStruct.DoubleEnclosedLocalizable.first.localizationKey, "CaseLocalizableTests.EnclosingStruct.first")
	}
	
	func testTopLevelBundle() throws {
		XCTAssertEqual(TopLevelLocalizable.first.localizationBundle, .main)
	}
	
	func testEnclosedBundle() throws {
		XCTAssertNotEqual(EnclosedLocalizable.first.localizationBundle, .main)
	}
}
