//
//  XcodeContext.swift
//  Fam
//
//  Created by Andre Pham on 30/11/2024.
//

import Foundation

class XcodeContext {
    
    public static var executingPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    public static var executingUnitTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil
    }
    
    private init() { }
    
}
