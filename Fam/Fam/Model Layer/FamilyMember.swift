//
//  FamilyMember.swift
//  Fam
//
//  Created by Andre Pham on 17/4/2024.
//

import Foundation

class FamilyMember {
    
    public enum Sex {
        case male
        case female
    }
    
    public let id: UUID
    private weak var family: FamilyMemberStore?
    private var motherID: UUID?
    private var fatherID: UUID?
    private var spouseID: UUID?
    private var exSpousesIDs: [UUID]
    private(set) var firstName: String
    private(set) var sex: Sex
    public var mother: FamilyMember? {
        if let motherID {
            return self.family?.getFamilyMember(id: motherID)
        }
        return nil
    }
    public var father: FamilyMember? {
        if let fatherID {
            return self.family?.getFamilyMember(id: fatherID)
        }
        return nil
    }
    public var spouse: FamilyMember? {
        if let spouseID {
            return self.family?.getFamilyMember(id: spouseID)
        }
        return nil
    }
    public var exSpouses: [FamilyMember] {
        return self.exSpousesIDs.compactMap({
            self.family?.getFamilyMember(id: $0)
        })
    }
    public var siblings: [FamilyMember] {
        var siblings = [FamilyMember]()
        let allFamilyMembers = self.family?.getAllFamilyMembers() ?? []
        for familyMember in allFamilyMembers {
            if (familyMember.fatherID == self.fatherID || familyMember.motherID == self.motherID) && familyMember.id != self.id {
                siblings.append(familyMember)
            }
        }
        return siblings
    }
    public var children: [FamilyMember] {
        var children = [FamilyMember]()
        let allFamilyMembers = self.family?.getAllFamilyMembers() ?? []
        for familyMember in allFamilyMembers {
            if familyMember.motherID == self.id || familyMember.fatherID == self.id {
                children.append(familyMember)
            }
        }
        return children
    }
    public var hasNoParents: Bool {
        return self.fatherID == nil && self.motherID == nil
    }
    public var hasAFamily: Bool {
        return self.family != nil
    }
    
    init(firstName: String, sex: Sex, family: FamilyMemberStore) {
        self.id = UUID()
        self.family = family
        self.motherID = nil
        self.fatherID = nil
        self.spouseID = nil
        self.exSpousesIDs = [UUID]()
        self.firstName = firstName
        self.sex = sex
    }
    
    func assignSpouse(_ spouse: FamilyMember) {
        guard self.hasAFamily && self.belongsToSameFamily(as: spouse) else {
            assertionFailure("Members don't have the same family")
            return
        }
        self.spouseID = spouse.id
        spouse.spouseID = self.id
    }
    
    func assignExSpouse(_ ex: FamilyMember) {
        guard self.hasAFamily && self.belongsToSameFamily(as: ex) else {
            assertionFailure("Members don't have the same family")
            return
        }
        self.exSpousesIDs.append(ex.id)
        ex.exSpousesIDs.append(self.id)
    }
    
    func assignChild(_ child: FamilyMember) {
        guard self.hasAFamily && self.belongsToSameFamily(as: child) else {
            assertionFailure("Members don't have the same family")
            return
        }
        switch self.sex {
        case .male:
            child.fatherID = self.id
        case .female:
            child.motherID = self.id
        }
    }
    
    func assignParent(_ parent: FamilyMember) {
        guard self.hasAFamily && self.belongsToSameFamily(as: parent) else {
            assertionFailure("Members don't have the same family")
            return
        }
        switch parent.sex {
        case .male:
            self.fatherID = parent.id
        case .female:
            self.motherID = parent.id
        }
    }
    
    func belongsToSameFamily(as familyMember: FamilyMember) -> Bool {
        if let familyID = self.family?.id, let otherFamilyID = familyMember.family?.id {
            return familyID == otherFamilyID
        }
        return false
    }
    
}
