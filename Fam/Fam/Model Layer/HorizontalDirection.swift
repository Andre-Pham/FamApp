//
//  HorizontalDirection.swift
//  Fam
//
//  Created by Andre Pham on 6/7/2024.
//

import Foundation

enum HorizontalDirection {
    case right
    case left
    
    public var oppositeDirection: HorizontalDirection {
        return self == .right ? .left : .right
    }
    
    public var directionMultiplier: Double {
        return self == .right ? 1 : -1
    }
}
