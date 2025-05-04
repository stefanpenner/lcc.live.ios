//
//  lccUITests.swift
//  lccUITests
//
//  Created by Stefan Penner on 4/30/25.
//

import XCTest

final class lccUITests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each lcc method in the class.

        // In UI lccs it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI lccs it’s important to set the initial state - such as interface orientation - required for your lccs before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each lcc method in the class.
    }

    @MainActor
    func lccExample() throws {
        // UI lccs must launch the application that they lcc.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your lccs produce the correct results.
    }

    @MainActor
    func lccLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
