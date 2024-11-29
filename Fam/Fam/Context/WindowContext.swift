//
//  WindowContext.swift
//  Fam
//
//  Created by Andre Pham on 30/11/2024.
//

import Foundation
import UIKit

class WindowContext {
    
    private static var safeAreaInsets: UIEdgeInsets? {
        return Self.window?.safeAreaInsets
    }
    
    public static var topSafeAreaHeight: CGFloat {
        return Self.safeAreaInsets?.top ?? 0.0
    }
    
    public static var bottomSafeAreaHeight: CGFloat {
        return Self.safeAreaInsets?.bottom ?? 0.0
    }
    
    public static var windowHeight: CGFloat {
        if DeviceContext.deviceIsMac, let window = Self.window {
            return window.frame.size.height
        } else {
            return UIScreen.main.bounds.height
        }
    }
    
    public static var windowWidth: CGFloat {
        if DeviceContext.deviceIsMac, let window = Self.window {
            return window.frame.size.width
        } else {
            return UIScreen.main.bounds.width
        }
    }
    
    public static var windowOrientation: UIInterfaceOrientation {
        return Self.window?.windowScene?.interfaceOrientation ?? .unknown
    }
    
    public static var windowAspectRatio: CGFloat {
        if DeviceContext.deviceIsMac, let window = Self.window {
            return window.frame.size.width/window.frame.size.height
        } else {
            return UIScreen.main.bounds.width/UIScreen.main.bounds.height
        }
    }
    
    public static var window: UIWindow? {
        return (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first
    }
    
    private init() { }
    
}
