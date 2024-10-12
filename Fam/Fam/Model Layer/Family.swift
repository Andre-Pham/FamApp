//
//  Family.swift
//  Fam
//
//  Created by Andre Pham on 17/4/2024.
//

import Foundation

class Family {
    
    public let id = UUID()
    private var familyMembers = [UUID: FamilyMember]()
    public var familyMembersCount: Int {
        return self.familyMembers.count
    }
    
    init() { }
    
    func contains(familyMember: FamilyMember) -> Bool {
        return self.familyMembers[familyMember.id] != nil
    }
    
    func getFamilyMember(id: UUID) -> FamilyMember? {
        return self.familyMembers[id]
    }
    
    func getAllFamilyMembers() -> [FamilyMember] {
        return Array(self.familyMembers.values).sorted(by: { $0.consistentSortingID < $1.consistentSortingID })
    }
    
    func addFamilyMember(_ familyMember: FamilyMember) {
        self.familyMembers[familyMember.id] = familyMember
    }
    
}
