//
//  UlysseTests.swift
//  UlysseTests
//
//  Created by Eric Duchenne on 03/05/2021.
//

import XCTest
@testable import Ulysse
@testable import InformationDataSource

class UlysseTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

   func testInitInformationDataSource() throws {
      let ids = InformationDataSource(region: .atlantique, info: .normal)
      XCTAssert(ids.region == Premar.atlantique)
      XCTAssert(ids.nature == TypeInformation.normal)
      XCTAssert(ids.items.count == 0)
      XCTAssert(ids.publishedOn == nil )
      XCTAssert(ids.lastModifiedOn == nil)
      XCTAssert(ids.lastCheckedServer == nil)
      XCTAssert(ids.sourceDescription == "")


   }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
