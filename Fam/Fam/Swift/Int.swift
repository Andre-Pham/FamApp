//
//  Int.swift
//  Fam
//
//  Created by Andre Pham on 31/5/2024.
//

import Foundation

extension Int {
    
    public var isEven: Bool {
        return self % 2 == 0
    }
    
    public var isOdd: Bool {
        return self % 2 != 0
    }
    
    /// Retrieves the nearest integer that's a multiple of x.
    /// Example:
    /// ``` 451.nearest(10) -> 450
    ///     450.nearest(100) -> 500
    ///     499.nearest(1000) -> 0
    /// ```
    /// - Parameters:
    ///   - x: The magnitude that the return value has to be a multiple of.
    /// - Returns: The nearest integer `y` where `y%x == 0`
    func nearest(_ x: Int) -> Int {
        let lowerBound = (self/x)*x
        return self - lowerBound > x/2 - 1 ? lowerBound + x : lowerBound
    }
    
    /// Returns the integer bounded by the specified minimum and maximum values.
    /// - Parameters:
    ///   - minValue: The min value of the range
    ///   - maxValue: The max value of the range
    /// - Returns: This value bounded within the provided range
    func boundToRange(min minValue: Int, max maxValue: Int) -> Int {
        return Swift.max(Swift.min(maxValue, self), minValue)
    }
    
}
