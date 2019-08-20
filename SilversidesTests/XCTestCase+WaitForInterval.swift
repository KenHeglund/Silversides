//
//  XCTestCase+WaitForInterval.swift
//  SilversidesTests
//
//  Created by Ken Heglund on 8/18/19.
//  Copyright © 2019 OrderedBytes. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase  {
    
    /// Wait for the given interval while the run loop is running.
    /// - parameter timeInterval: The time to wait given in milliseconds.
    func waitForInterval(milliseconds timeInterval: Int) {
        
        let queue = DispatchQueue.global(qos: .default)
        
        let expectation = self.expectation(description: "waitForInterval(_:)")
        let deadline =  DispatchTime.now() + DispatchTimeInterval.milliseconds(timeInterval)
        queue.asyncAfter(deadline: deadline) {
            expectation.fulfill()
        }
        
        let timeIntervalInSeconds: TimeInterval =  Double(timeInterval) / 1000.0
        
        self.waitForExpectations(timeout: timeIntervalInSeconds * 1.1, handler: nil)
    }
}
