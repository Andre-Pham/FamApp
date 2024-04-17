//
//  FamilyMemberStoreRenderProxy.swift
//  Fam
//
//  Created by Andre Pham on 18/4/2024.
//

import Foundation
import SwiftMath

class FamilyMemberStoreRenderProxy {
    
    public let family: FamilyMemberStore
    private(set) var connections = [SMLine]()
    
    init(_ family: FamilyMemberStore) {
        self.family = family
    }
    
}
