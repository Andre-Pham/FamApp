//
//  FamilyMemberStore.swift
//  Fam
//
//  Created by Andre Pham on 17/4/2024.
//

import Foundation

class FamilyMemberStore {
    
    public let id = UUID()
    private var familyMembers = [UUID: FamilyMember]()
    
    init() { }
    
    func getFamilyMember(id: UUID) -> FamilyMember? {
        return self.familyMembers[id]
    }
    
    func getAllFamilyMembers() -> [FamilyMember] {
        return Array(self.familyMembers.values)
    }
    
    func addFamilyMember(_ familyMember: FamilyMember) {
        self.familyMembers[familyMember.id] = familyMember
    }
    
}
