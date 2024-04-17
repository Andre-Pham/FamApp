//
//  Environment.swift
//  Fam
//
//  Created by Andre Pham on 17/4/2024.
//

import Foundation
import UIKit

class Environment {
    
    public static let inst = Environment()
    
    private var safeAreaInsets: UIEdgeInsets? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        return windowScene.windows.first?.safeAreaInsets
    }
    
    public var deviceType: UIUserInterfaceIdiom {
        return UIDevice.current.userInterfaceIdiom
    }
    
    public var deviceIsMac: Bool {
        return ProcessInfo.processInfo.isiOSAppOnMac
    }
    
    public var topSafeAreaHeight: CGFloat {
        return self.safeAreaInsets?.top ?? 0.0
    }
    
    public var bottomSafeAreaHeight: CGFloat {
        return self.safeAreaInsets?.bottom ?? 0.0
    }
    
    public var screenHeight: CGFloat {
        if self.deviceIsMac,
           let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.frame.size.height
        } else {
            return UIScreen.main.bounds.height
        }
    }
    
    public var screenWidth: CGFloat {
        if self.deviceIsMac,
           let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.frame.size.width
        } else {
            return UIScreen.main.bounds.width
        }
    }
    
    public var window: UIWindow? {
        return (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first
    }
    
    public var deviceIsTiny: Bool {
        return self.screenHeight.isLessOrEqual(to: 667)
    }
    
    public var deviceIsLarge: Bool {
        return self.deviceType != .phone
    }
    
    public var applicationState: UIApplication.State {
        UIApplication.shared.applicationState
    }
    
    public var executingUIPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    public var executingUnitTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil
    }
    
    private init() { }
    
}
