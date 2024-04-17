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
    public var nextFamilyMembers: [FamilyMember] {
        var next = [FamilyMember]()
        if let spouse = self.familyMember.spouse {
            next.append(spouse)
        }
        next.append(contentsOf: self.familyMember.exSpouses)
        if let mother = self.familyMember.mother {
            next.append(mother)
            if let motherSpouse = mother.spouse, self.familyMember.fatherID != motherSpouse.id {
                next.append(motherSpouse)
            }
        }
        if let father = self.familyMember.father {
            next.append(father)
            if let fatherSpouse = father.spouse, self.familyMember.motherID != fatherSpouse.id {
                next.append(fatherSpouse)
            }
        }
        for child in self.familyMember.children {
            next.append(child)
            if let childInLaw = child.spouse {
                next.append(childInLaw)
            }
        }
        return next
    }
    
    init(_ familyMember: FamilyMember) {
        self.familyMember = familyMember
    }
    
    func setPosition(to position: SMPoint?) {
        self.position = position
    }
    
}
