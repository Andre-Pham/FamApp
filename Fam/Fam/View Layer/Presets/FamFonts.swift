//
//  FamFonts.swift
//  Fam
//
//  Created by Andre Pham on 8/3/2024.
//

import Foundation
import UIKit

public func FamFont(font: String, size: Double) -> UIFont {
    assert(UIFont(name: font, size: size) != nil, "Font missing: \(font)")
    return UIFont(name: font, size: size)!
}

enum FamFonts {
    
    class Inter {
        public static let Black = "Inter-Black"
        public static let ExtraBold = "Inter-ExtraBold"
        public static let Bold = "Inter-Bold"
        public static let SemiBold = "Inter-SemiBold"
        public static let Medium = "Inter-Medium"
        public static let Regular = "Inter-Regular"
        public static let Light = "Inter-Light"
        public static let Thin = "Inter-Thin"
        private init() { }
    }
    
    class IBMPlexMono {
        public static let Bold = "IBMPlexMono-Bold"
        public static let BoldItalic = "IBMPlexMono-BoldItalic"
        public static let Medium = "IBMPlexMono-Medium"
        public static let MediumItalic = "IBMPlexMono-MediumItalic"
        public static let SemiBold = "IBMPlexMono-SemiBold"
        public static let SemiBoldItalic = "IBMPlexMono-SemiBoldItalic"
        private init() { }
    }
    
    class Poppins {
        public static let Bold = "Poppins-Bold"
        public static let BoldItalic = "Poppins-BoldItalic"
        public static let SemiBold = "Poppins-SemiBold"
        public static let SemiBoldItalic = "Poppins-SemiBoldItalic"
        public static let Medium = "Poppins-Medium"
        public static let MediumItalic = "Poppins-MediumItalic"
        public static let Regular = "Poppins-Regular"
        public static let RegularItalic = "Poppins-RegularItalic"
        public static let Light = "Poppins-Light"
        public static let LightItalic = "Poppins-LightItalic"
        private init() { }
    }
    
    class Quicksand {
        public static let Light = "Quicksand-Light"
        public static let Regular = "Quicksand-Regular"
        public static let Medium = "Quicksand-Medium"
        public static let SemiBold = "Quicksand-SemiBold"
        public static let Bold = "Quicksand-Bold"
        private init() { }
    }
    
}
