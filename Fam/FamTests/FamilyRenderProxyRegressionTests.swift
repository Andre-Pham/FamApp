//
//  FamilyRenderProxyRegressionTests.swift
//  FamTests
//
//  Created by Andre Pham on 13/10/2024.
//

import XCTest
@testable import Fam

final class FamilyRenderProxyRegressionTests: XCTestCase {

    func testRegression1() throws {
        let family = MockFamilies.regression1
        let render = FamilyRenderProxy(family)
        XCTAssertEqual(render.countPositionConflicts(), 0, "Found unexpected position conflicts in family tree render, expected 0")
        XCTAssertEqual(render.countConnectionConflicts(), 0, "Found unexpected connection conflicts in family tree render, expected 0")
    }

}
