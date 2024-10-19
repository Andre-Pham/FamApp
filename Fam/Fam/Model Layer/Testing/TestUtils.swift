//
//  TestUtils.swift
//  Fam
//
//  Created by Andre Pham on 19/10/2024.
//

import Foundation

@discardableResult
func testExecutionDuration(printedTaskName: String? = nil, _ test: () -> Void) -> Double {
    #if DEBUG
    let start = DispatchTime.now()
    test()
    let end = DispatchTime.now()
    let seconds = Double(end.uptimeNanoseconds - start.uptimeNanoseconds)/1_000_000_000
    if let printedTaskName {
        print("> \(printedTaskName) execution lasted: \(seconds) seconds")
    }
    return seconds
    #else
    return 0.0
    #endif
}

func assertOutsideUnitTests(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    #if DEBUG
    if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
        assert(condition(), message(), file: file, line: line)
    }
    #endif
}

func assertionFailureOutsideUnitTests(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    #if DEBUG
    if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
        assertionFailure(message(), file: file, line: line)
    }
    #endif
}

func assertDuringUnitTests(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    #if DEBUG
    if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
        assert(condition(), message(), file: file, line: line)
    }
    #endif
}

func assertionFailureDuringUnitTests(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    #if DEBUG
    if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
        assertionFailure(message(), file: file, line: line)
    }
    #endif
}
