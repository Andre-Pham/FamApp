//
//  DeviceContext.swift
//  Fam
//
//  Created by Andre Pham on 30/11/2024.
//

import Foundation
import UIKit

class DeviceContext {
    
    public static var deviceType: UIUserInterfaceIdiom {
        return UIDevice.current.userInterfaceIdiom
    }
    
    public static var deviceIsMac: Bool {
        return ProcessInfo.processInfo.isiOSAppOnMac
    }
    
    public static var deviceOrientation: UIDeviceOrientation {
        return UIDevice.current.orientation
    }
    
    public static var deviceIsTiny: Bool {
        return WindowContext.windowHeight.isLessOrEqual(to: 667)
    }
    
    public static var deviceIsLarge: Bool {
        return Self.deviceType != .phone
    }
    
    private init() { }
    
}
