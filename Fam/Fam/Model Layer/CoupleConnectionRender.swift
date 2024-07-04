//
//  CoupleConnectionRender.swift
//  Fam
//
//  Created by Andre Pham on 18/4/2024.
//

import Foundation

class CoupleConnectionRender {
    
    public let leftPartner: FamilyMemberRenderProxy
    public let rightPartner: FamilyMemberRenderProxy
    
    init(partner1: FamilyMemberRenderProxy, partner2: FamilyMemberRenderProxy) {
        assert(partner1.preferredDirection != partner2.preferredDirection, "Same direction partners leads to failed logic")
        switch partner1.preferredDirection {
        case .right:
            self.leftPartner = partner2
            self.rightPartner = partner1
        case .left:
            self.leftPartner = partner1
            self.rightPartner = partner2
        }
    }
    
}
