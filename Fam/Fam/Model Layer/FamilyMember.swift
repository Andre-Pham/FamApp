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
    private(set) var motherID: UUID?
    private(set) var fatherID: UUID?
    private(set) var spouseID: UUID?
    private(set) var exSpousesIDs: [UUID]
    private(set) var firstName: String
    private(set) var sex: Sex
    public var parentIDs: [UUID] {
        return [self.motherID, self.fatherID].compactMap({ $0 })
    }
    public var childrenIDs: [UUID] {
        var ids = [UUID]()
        let allFamilyMembers = self.family?.getAllFamilyMembers() ?? []
        for familyMember in allFamilyMembers {
            if familyMember.motherID == self.id || familyMember.fatherID == self.id {
                ids.append(familyMember.id)
            }
        }
        return ids
    }
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
    public var parents: [FamilyMember] {
        return self.parentIDs.compactMap({ self.family?.getFamilyMember(id: $0) })
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
            if self.isSibling(to: familyMember) {
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
    public var directFamily: [FamilyMember] {
        var directFamily = [FamilyMember]()
        if let spouse = self.spouse {
            directFamily.append(spouse)
        }
        directFamily.append(contentsOf: self.exSpouses)
        if let mother = self.mother {
            directFamily.append(mother)
        }
        if let father = self.father {
            directFamily.append(father)
        }
        directFamily.append(contentsOf: self.children)
        directFamily.append(contentsOf: self.siblings)
        return directFamily
    }
    public var daughters: [FamilyMember] {
        return self.children.filter({ $0.sex == .female })
    }
    public var daughtersWithChildren: [FamilyMember] {
        return self.daughters.filter({ $0.hasChildren })
    }
    public var sons: [FamilyMember] {
        return self.children.filter({ $0.sex == .male })
    }
    public var sonsWithChildren: [FamilyMember] {
        return self.sons.filter({ $0.hasChildren })
    }
    public var hasNoParents: Bool {
        return self.fatherID == nil && self.motherID == nil
    }
    public var hasAFamily: Bool {
        return self.family != nil
    }
    public var childrenCount: Int {
        return self.childrenIDs.count
    }
    public var hasChildren: Bool {
        return self.childrenCount > 0
    }
    public var isParent: Bool {
        return self.hasChildren
    }
    public var isFather: Bool {
        return self.sex == .male && self.hasChildren
    }
    public var isMother: Bool {
        return self.sex == .female && self.hasChildren
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
        
        family.addFamilyMember(self)
    }
    
    func isSpouse(to familyMember: FamilyMember) -> Bool {
        return self.spouseID != nil && self.spouseID == familyMember.id
    }
    
    func isExSpouse(to familyMember: FamilyMember) -> Bool {
        return self.exSpousesIDs.contains(familyMember.id)
    }
    
    func isMother(of familyMember: FamilyMember) -> Bool {
        return familyMember.motherID == self.id
    }
    
    func isFather(of familyMember: FamilyMember) -> Bool {
        return familyMember.fatherID == self.id
    }
    
    func isParent(of familyMember: FamilyMember) -> Bool {
        return self.isMother(of: familyMember) || self.isFather(of: familyMember)
    }
    
    func isSibling(to familyMember: FamilyMember) -> Bool {
        guard self.id != familyMember.id else {
            // Both family members are the same person
            return false
        }
        assert(self.hasAFamily, "Member doesn't belong to a family")
        let sharedFather = self.fatherID != nil && familyMember.fatherID == self.fatherID
        let sharedMother = self.motherID != nil && familyMember.motherID == self.motherID
        return sharedFather || sharedMother
    }
    
    func isChild(of familyMember: FamilyMember) -> Bool {
        return self.motherID == familyMember.id || self.fatherID == familyMember.id
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
    
    func assignChildren(_ children: FamilyMember...) {
        for child in children {
            self.assignChild(child)
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
    
    func assignParents(_ parent1: FamilyMember, _ parent2: FamilyMember) {
        self.assignParent(parent1)
        self.assignParent(parent2)
    }
    
    func belongsToSameFamily(as familyMember: FamilyMember) -> Bool {
        if let familyID = self.family?.id, let otherFamilyID = familyMember.family?.id {
            return familyID == otherFamilyID
        }
        return false
    }
    
}
