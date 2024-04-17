//
//  FamColors.swift
//  Fam
//
//  Created by Andre Pham on 8/3/2024.
//

import Foundation
import UIKit

/// Predefined colors to be used application-wide. Always adaptive to light/dark mode.
/// Colors are named using light-mode convention, that is, colors should be named according to how they should be read in light mode. "Dark text" is text that is dark in light mode, and light in dark mode.
/// Colors that need to clarify that they don't change between light/dark mode should use "Permanent" in their name after their luminosity descriptor. For example, "whitePermanent".
enum FamColors {
    
    // MARK: - Identity
    
    static let accent = UIColor(named: "Assets#EC6572")!
    static let warning = UIColor(named: "Assets#CB4343")!
    static let success = UIColor(named: "Assets#51CF66")!
    
    // MARK: - Tasks
    
    static let ongoingTask = UIColor(named: "Assets#FE3A2E")!
    static let upcomingTask = UIColor(named: "Assets#007AFF")!
    static let completedTask = UIColor(named: "Assets#18C657")!
    
    // MARK: - Fill
    
    static let backgroundFill = UIColor(named: "Assets#F2F2F5#3B3B47")!
    static let foregroundFill = UIColor(named: "Assets#FFFFFF#201F25")!
    static let primaryComponentFill = Self.accent
    static let secondaryComponentFill = UIColor(named: "Assets#F4F5F7#454552")!
    
    // MARK: - Text
    
    static let textDark1 = UIColor(named: "Assets#000000#FFFFFF")!
    static let textDark2 = UIColor(named: "Assets#6A6B75#C3C1D9")!
    static let textDark3 = UIColor(named: "Assets#B2B3C2#767489")!
    static let textPrimaryComponent = UIColor(named: "Assets#FFFFFF")!
    static let textSecondaryComponent = Self.textDark1
    
    // MARK: - Adaptive Colors
    
    static let black = UIColor(named: "Assets#000000#FFFFFF")!
    static let white = UIColor(named: "Assets#FFFFFF#000000")!
    
    // MARK: - Colors
    
    static let whitePermanent = UIColor(named: "Assets#FFFFFF")!
    static let blackPermanent = UIColor(named: "Assets#000000")!
    
}
