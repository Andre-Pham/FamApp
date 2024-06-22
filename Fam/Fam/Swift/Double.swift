//
//  Double.swift
//  Fam
//
//  Created by Andre Pham on 31/5/2024.
//

import Foundation

extension Double {
    
    func toString(decimalPlaces: Int = 0) -> String {
        return NSString(format: "%.\(decimalPlaces)f" as NSString, self) as String
    }
    
    func toRoundedInt() -> Int {
        return Int(Darwin.round(self))
    }
    
    /// Retrieves the nearest double that's a multiple of x.
    /// Example:
    /// ``` 0.32.nearest(0.05) -> 0.3
    ///     0.33.nearest(0.05) -> 0.35
    /// ```
    /// - Parameters:
    ///   - x: The magnitude that the return value has to be a multiple of.
    /// - Returns: The nearest double `y` where `y%x == 0`
    func nearest(_ x: Double) -> Double {
        let decimals = String(x).split(separator: ".")[1]
        let decimalCount = decimals == "0" ? 0 : decimals.count
        let remainder = self.truncatingRemainder(dividingBy: x)
        let divisor = pow(10.0, Double(decimalCount))
        let lower = Darwin.round((self - remainder)*divisor)/divisor
        let upper = Darwin.round((self - remainder)*divisor)/divisor + x
        return (self - lower < upper - self) ? lower : upper
    }
    
    /// Round to x decimal places.
    /// Example: `0.545.rounded(decimalPlaces: 1) -> 0.5`
    /// - Parameters:
    ///   - decimalPlaces: The number of digits after the decimal point
    /// - Returns: The rounded double
    func rounded(decimalPlaces: Int) -> Double {
        let multiplier = pow(10.0, Double(decimalPlaces))
        return Darwin.round(self*multiplier)/multiplier
    }
    
    /// Check if this double is closer to a target than an alternative.
    /// Example: `0.5.isCloser(to: 0.6, than: 0.0) -> true`
    /// - Parameters:
    ///   - target: The value which returns true if closer
    ///   - alternative: The value which returns false if closer
    /// - Returns: True if the target is closer to this than the alternative
    func isCloser(to target: Double, than alternative: Double) -> Bool {
        let targetDifference = abs(self - target)
        let alternativeDifference = abs(self - alternative)
        return targetDifference.isLess(than: alternativeDifference)
    }
    
    /// Returns the integer bounded by the specified minimum and maximum values.
    /// - Parameters:
    ///   - minValue: The min value of the range
    ///   - maxValue: The max value of the range
    /// - Returns: This value bounded within the provided range
    func boundToRange(min minValue: Double, max maxValue: Double) -> Double {
        return Swift.max(Swift.min(maxValue, self), minValue)
    }
    
}
