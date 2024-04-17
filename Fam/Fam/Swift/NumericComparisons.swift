//
//  NumericComparisons.swift
//  Fam
//
//  Created by Andre Pham on 17/4/2024.
//

import Foundation

extension Double {
    
    public static let defaultPrecision: Double = 1e-5
    
    /// `self < x`
    public func isLess(than x: Double, precision: Double = Self.defaultPrecision) -> Bool {
        return (x - self > precision)
    }
    
    /// `self <= x`
    public func isLessOrEqual(to x: Double, precision: Double = Self.defaultPrecision) -> Bool {
        return self.isEqual(to: x, precision: precision) || self.isLess(than: x, precision: precision)
    }
    
    /// `self > x`
    public func isGreater(than x: Double, precision: Double = Self.defaultPrecision) -> Bool {
        return (self - x > precision)
    }
    
    /// `self >= x`
    public func isGreaterOrEqual(to x: Double, precision: Double = Self.defaultPrecision) -> Bool {
        return self.isEqual(to: x, precision: precision) || self.isGreater(than: x, precision: precision)
    }
    
    /// `self == x`
    public func isEqual(to x: Double, precision: Double = Self.defaultPrecision) -> Bool {
        return (abs(self - x) <= precision)
    }
    
    /// `self == 0`
    public func isZero(precision: Double = Self.defaultPrecision) -> Bool {
        return self.isEqual(to: 0.0, precision: precision)
    }
    
    /// `self < 0`
    public func isLessThanZero(precision: Double = Self.defaultPrecision) -> Bool {
        return self.isLess(than: 0.0, precision: precision)
    }
    
    /// `self <= 0`
    public func isLessOrEqualZero(precision: Double = Self.defaultPrecision) -> Bool {
        return self.isLessOrEqual(to: 0.0, precision: precision)
    }
    
    /// `self > 0`
    public func isGreaterThanZero(precision: Double = Self.defaultPrecision) -> Bool {
        return self.isGreater(than: 0.0, precision: precision)
    }
    
    /// `self >= 0`
    public func isGreaterOrEqualZero(precision: Double = Self.defaultPrecision) -> Bool {
        return self.isGreaterOrEqual(to: 0.0, precision: precision)
    }
    
}

extension Float {
    
    public static let defaultPrecision: Float = 1e-5
    
    /// `self < x`
    public func isLess(than x: Float, precision: Float = Self.defaultPrecision) -> Bool {
        return (x - self > precision)
    }
    
    /// `self <= x`
    public func isLessOrEqual(to x: Float, precision: Float = Self.defaultPrecision) -> Bool {
        return self.isEqual(to: x, precision: precision) || self.isLess(than: x, precision: precision)
    }
    
    /// `self > x`
    public func isGreater(than x: Float, precision: Float = Self.defaultPrecision) -> Bool {
        return (self - x > precision)
    }
    
    /// `self >= x`
    public func isGreaterOrEqual(to x: Float, precision: Float = Self.defaultPrecision) -> Bool {
        return self.isEqual(to: x, precision: precision) || self.isGreater(than: x, precision: precision)
    }
    
    /// `self == x`
    public func isEqual(to x: Float, precision: Float = Self.defaultPrecision) -> Bool {
        return (abs(self - x) <= precision)
    }
    
    /// `self == 0`
    public func isZero(precision: Float = Self.defaultPrecision) -> Bool {
        return self.isEqual(to: 0.0, precision: precision)
    }
    
    /// `self < 0`
    public func isLessThanZero(precision: Float = Self.defaultPrecision) -> Bool {
        return self.isLess(than: 0.0, precision: precision)
    }
    
    /// `self <= 0`
    public func isLessOrEqualZero(precision: Float = Self.defaultPrecision) -> Bool {
        return self.isLessOrEqual(to: 0.0, precision: precision)
    }
    
    /// `self > 0`
    public func isGreaterThanZero(precision: Float = Self.defaultPrecision) -> Bool {
        return self.isGreater(than: 0.0, precision: precision)
    }
    
    /// `self >= 0`
    public func isGreaterOrEqualZero(precision: Float = Self.defaultPrecision) -> Bool {
        return self.isGreaterOrEqual(to: 0.0, precision: precision)
    }
    
}

extension CGFloat {
    
    public static let defaultPrecision: CGFloat = 1e-5
    
    /// `self < x`
    public func isLess(than x: CGFloat, precision: CGFloat = Self.defaultPrecision) -> Bool {
        return (x - self > precision)
    }
    
    /// `self <= x`
    public func isLessOrEqual(to x: CGFloat, precision: CGFloat = Self.defaultPrecision) -> Bool {
        return self.isEqual(to: x, precision: precision) || self.isLess(than: x, precision: precision)
    }
    
    /// `self > x`
    public func isGreater(than x: CGFloat, precision: CGFloat = Self.defaultPrecision) -> Bool {
        return (self - x > precision)
    }
    
    /// `self >= x`
    public func isGreaterOrEqual(to x: CGFloat, precision: CGFloat = Self.defaultPrecision) -> Bool {
        return self.isEqual(to: x, precision: precision) || self.isGreater(than: x, precision: precision)
    }
    
    /// `self == x`
    public func isEqual(to x: CGFloat, precision: CGFloat = Self.defaultPrecision) -> Bool {
        return (abs(self - x) <= precision)
    }
    
    /// `self == 0`
    public func isZero(precision: CGFloat = Self.defaultPrecision) -> Bool {
        return self.isEqual(to: 0.0, precision: precision)
    }
    
    /// `self < 0`
    public func isLessThanZero(precision: CGFloat = Self.defaultPrecision) -> Bool {
        return self.isLess(than: 0.0, precision: precision)
    }
    
    /// `self <= 0`
    public func isLessOrEqualZero(precision: CGFloat = Self.defaultPrecision) -> Bool {
        return self.isLessOrEqual(to: 0.0, precision: precision)
    }
    
    /// `self > 0`
    public func isGreaterThanZero(precision: CGFloat = Self.defaultPrecision) -> Bool {
        return self.isGreater(than: 0.0, precision: precision)
    }
    
    /// `self >= 0`
    public func isGreaterOrEqualZero(precision: CGFloat = Self.defaultPrecision) -> Bool {
        return self.isGreaterOrEqual(to: 0.0, precision: precision)
    }
    
}
