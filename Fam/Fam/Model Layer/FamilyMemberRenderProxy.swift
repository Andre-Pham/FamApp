//
//  FamilyMemberRenderProxy.swift
//  Fam
//
//  Created by Andre Pham on 18/4/2024.
//

import Foundation
import SwiftMath

class FamilyMemberRenderProxy {
    
    public let familyMember: FamilyMember
    private(set) var position: SMPoint? = nil
    
    init(_ familyMember: FamilyMember) {
        self.familyMember = familyMember
    }
    
}
