//
//  AppContext.swift
//  Fam
//
//  Created by Andre Pham on 30/11/2024.
//

import Foundation
import UIKit

class AppContext {
    
    public static var versionNumber: String {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            return "\(version)"
        }
        assertionFailure("Failed to get version number")
        return ""
    }
    
    public static var versionAndBuildNumber: String {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            return "\(version) (\(build))"
        }
        assertionFailure("Failed to get version number")
        return ""
    }
    
    public static var applicationState: UIApplication.State {
        UIApplication.shared.applicationState
    }
    
    private init() { }
    
}
