//
//  CoupleConnectionRender.swift
//  Fam
//
//  Created by Andre Pham on 18/4/2024.
//

import Foundation

class CoupleConnectionRender {
    
    public let malePartner: FamilyMemberRenderProxy
    public let femalePartner: FamilyMemberRenderProxy
    
    init(partner1: FamilyMemberRenderProxy, partner2: FamilyMemberRenderProxy) {
        assert(partner1.familyMember.sex != partner2.familyMember.sex, "Same sex partners leads to failed logic")
        if partner1.familyMember.sex == .male {
            self.malePartner = partner1
            self.femalePartner = partner2
        } else {
            self.femalePartner = partner1
            self.malePartner = partner2
        }
    }
    
}
