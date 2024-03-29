/*===========================================================================
OBWPathViewTests.swift
Silversides
Copyright (c) 2016 Ken Heglund. All rights reserved.
===========================================================================*/

import XCTest
@testable import SilversidesDemo
@testable import OBWControls

class OBWPathViewTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		
		// Put setup code here. This method is called before the invocation of each test method in the class.
		
		// Spin until the application's window loads.  This also allows time for the application to asynchronously display the initial path view contents.
		
		let startDate = Date()
		
		while true {
			assert(Date().timeIntervalSince(startDate) < 2.0)
			
			self.waitForInterval(milliseconds: 100)
			
			guard let window = NSApp.windows.first else { continue }
			guard let viewController = window.contentViewController as? ViewController else { continue }
			
			if viewController.pathViewConfigured {
				break
			}
		}
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testThatTrimmingAnEmptyImageProducesNil() throws {
		self.measure {
			let imageSize = NSSize(width: 10.0, height: 12.0)
			let emptyImage = NSImage(size: imageSize)
			XCTAssertNil(emptyImage.imageByTrimmingTransparentEdges())
		}
	}
	
	func testThatTrimmingAnOpaqueImageReturnsTheOriginalImage() throws {
		self.measure {
			let imageSize = NSSize(width: 10.0, height: 12.0)
			let drawnFrame = NSRect(origin: NSPoint.zero, size: imageSize)
			
			let sourceImage = NSImage(size: imageSize)
			sourceImage.withLockedFocus {
				NSColor.black.set()
				drawnFrame.fill()
			}
			
			let trimmedImage = sourceImage.imageByTrimmingTransparentEdges()
			XCTAssertTrue(trimmedImage === sourceImage)
		}
	}
	
	func testThatTrimmingAPartiallyEmptyImageProducesAProperlySizedImage() throws {
		self.measure {
			do {
				let imageSize = NSSize(width: 10.0, height: 12.0)
				let drawnFrame = NSRect(x: 3.0, y: 4.0, width: 2.0, height: 5.0)
				
				let sourceImage = NSImage(size: imageSize)
				sourceImage.withLockedFocus {
					NSColor.black.set()
					drawnFrame.fill()
				}
				
				let trimmedImage = try XCTUnwrap(sourceImage.imageByTrimmingTransparentEdges())
				XCTAssertEqual(drawnFrame.size, trimmedImage.size)
			}
			catch {
				
			}
		}
	}
	
	func testThatImbalancedEndItemUpdateThrowsError() throws {
		let pathView = OBWPathView(frame: .zero)
		
		XCTAssertThrowsError(try pathView.endPathItemUpdate())
		
		pathView.beginPathItemUpdate()
		try! pathView.endPathItemUpdate()
		
		XCTAssertThrowsError(try pathView.endPathItemUpdate())
	}
	
	func testThatPathViewItemCountsAreCorrect() throws {
		let pathView = OBWPathView(frame: .zero)
		
		pathView.setItems([])
		XCTAssertEqual(pathView.numberOfItems, 0)
		
		let items: [OBWPathItem] = [
			OBWPathItem(title: "first", image: nil, representedObject: nil, style: .default, textColor: nil),
			OBWPathItem(title: "second", image: nil, representedObject: nil, style: .default, textColor: nil),
			OBWPathItem(title: "third", image: nil, representedObject: nil, style: .default, textColor: nil),
		]
		
		pathView.setItems(items)
		XCTAssertEqual(pathView.numberOfItems, items.count)
		
		try! pathView.removeItemsFromIndex(1)
		XCTAssertEqual(pathView.numberOfItems, 1)
		
		let item = try! pathView.item(atIndex: 0)
		XCTAssertEqual(item.title, items[0].title)
	}
	
	func testThatRemoveItemsFromIndexThrowsProperly() throws {
		let pathView = OBWPathView(frame: .zero)
		
		let items: [OBWPathItem] = [
			OBWPathItem(title: "first", image: nil, representedObject: nil, style: .default, textColor: nil),
			OBWPathItem(title: "second", image: nil, representedObject: nil, style: .default, textColor: nil),
			OBWPathItem(title: "third", image: nil, representedObject: nil, style: .default, textColor: nil),
		]
		
		pathView.setItems(items)
		
		// Removing items from the end index should not throw
		try! pathView.removeItemsFromIndex(items.count)
		
		XCTAssertThrowsError(try pathView.removeItemsFromIndex(items.count + 1))
		
		try! pathView.removeItemsFromIndex(1)
		// Removing items from the end index should not throw
		try! pathView.removeItemsFromIndex(1)
	}
	
	func testThatItemsAreReplacedProperly() throws {
		let pathView = OBWPathView(frame: .zero)
		
		let items: [OBWPathItem] = [
			OBWPathItem(title: "first", image: nil, representedObject: nil, style: .default, textColor: nil),
			OBWPathItem(title: "second", image: nil, representedObject: nil, style: .default, textColor: nil),
			OBWPathItem(title: "third", image: nil, representedObject: nil, style: .default, textColor: nil),
		]
		
		pathView.setItems(items)
		XCTAssertEqual(try pathView.item(atIndex: 1).title, items[1].title)
		
		let newItem = OBWPathItem(title: "replacement", image: nil, representedObject: nil, style: .default, textColor: nil)
		
		try! pathView.setItem(newItem, atIndex: 1)
		XCTAssertEqual(try pathView.item(atIndex: 1).title, newItem.title)
	}
	
	func testVisualChangesSlowly() throws {
		let window = try XCTUnwrap(NSApp.windows.first)
		let windowController = try XCTUnwrap(window.windowController)
		let viewController = try XCTUnwrap(windowController.contentViewController as? ViewController)
		
		let URL1 = URL(fileURLWithPath: "/Applications/Utilities/", isDirectory: true)
		viewController.configurePathViewToShowURL(URL1)
		
		#if INTERACTIVE_TESTS
		Swift.print("The currently displayed URL should have animated to a new URL")
		self.waitForInterval(milliseconds: 3000)
		#endif // INTERACTIVE_TESTS
		
		let URL2 = URL(fileURLWithPath: "/Library/Logs/", isDirectory: true)
		viewController.configurePathViewToShowURL(URL2)
		
		#if INTERACTIVE_TESTS
		Swift.print("The currently displayed URL should have animated to a new URL")
		self.waitForInterval(milliseconds: 3000)
		#endif // INTERACTIVE_TESTS
		
		let URL3 = URL(fileURLWithPath: "/System/Library/Extensions/AppleHIDKeyboard.kext", isDirectory: true)
		viewController.configurePathViewToShowURL(URL3)
		
		#if INTERACTIVE_TESTS
		Swift.print("The currently displayed URL should have animated to a new URL")
		self.waitForInterval(milliseconds: 3000)
		#endif // INTERACTIVE_TESTS
	}
}
