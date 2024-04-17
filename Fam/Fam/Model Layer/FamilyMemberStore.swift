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
    
    func contains(familyMember: FamilyMember) -> Bool {
        return self.familyMembers[familyMember.id] != nil
    }
    
    func getFamilyMember(id: UUID) -> FamilyMember? {
        return self.familyMembers[id]
    }
    
    func getAllFamilyMembers() -> [FamilyMember] {
        // Sort for consistent ordering
        return Array(self.familyMembers.values).sorted(by: { $0.firstName < $1.firstName })
    }
    
    func addFamilyMember(_ familyMember: FamilyMember) {
        self.familyMembers[familyMember.id] = familyMember
    }
    
}
