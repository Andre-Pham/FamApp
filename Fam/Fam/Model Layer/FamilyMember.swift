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
        
        public var oppositeSex: Sex {
            return self == .male ? .female : .male
        }
    }
    
    public let id: UUID
    private weak var family: Family?
    private(set) var parentIDs: [UUID]
    private(set) var spouseID: UUID?
    private(set) var exSpousesIDs: [UUID]
    private(set) var firstName: String
    private(set) var lastName: String?
    private(set) var sex: Sex
    public var fullName: String {
        if let lastName {
            return "\(self.firstName) \(lastName)"
        }
        return self.firstName
    }
    /// An id that is used for sorting that attempts to return a consistent ordering of family members despite being random
    /// `.sorted(by: { $0.consistentSortingID < $1.consistentSortingID })`
    public var consistentSortingID: String {
        // Use name first for consistency between non-persistent renders and deleting then re-adding family members
        // Append id so if their names are the same, there's consistency between persistent renders
        return self.fullName + self.id.uuidString
    }
    private var childrenIDsCache: [UUID]? = nil
    public var childrenIDs: [UUID] {
        if let childrenIDsCache {
            return childrenIDsCache
        }
        var ids = [UUID]()
        let allFamilyMembers = self.family?.getAllFamilyMembers() ?? []
        for familyMember in allFamilyMembers {
            if familyMember.parentIDs.contains(self.id) {
                ids.append(familyMember.id)
            }
        }
        return ids
    }
    private var siblingIDsCache: [UUID]? = nil
    public var siblingIDs: [UUID] {
        if let siblingIDsCache {
            return siblingIDsCache
        }
        var ids = [UUID]()
        let allFamilyMembers = self.family?.getAllFamilyMembers() ?? []
        for familyMember in allFamilyMembers {
            if self.isSibling(to: familyMember) {
                ids.append(familyMember.id)
            }
        }
        return ids
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
    public var children: [FamilyMember] {
        return self.childrenIDs.compactMap({ self.family?.getFamilyMember(id: $0) })
    }
    public var siblings: [FamilyMember] {
        return self.siblingIDs.compactMap({ self.family?.getFamilyMember(id: $0) })
    }
    public var directFamily: [FamilyMember] {
        var directFamily = [FamilyMember]()
        if let spouse = self.spouse {
            directFamily.append(spouse)
        }
        directFamily.append(contentsOf: self.exSpouses)
        directFamily.append(contentsOf: self.parents)
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
        return self.parentIDs.count == 0
    }
    public var hasBothParents: Bool {
        return self.parentIDs.count == 2
    }
    public var hasSingleParent: Bool {
        return self.parentIDs.count == 1
    }
    public var hasSpouse: Bool {
        return self.spouseID != nil
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
    
    init(firstName: String, lastName: String? = nil, sex: Sex, family: Family) {
        self.id = UUID()
        self.family = family
        self.parentIDs = [UUID]()
        self.spouseID = nil
        self.exSpousesIDs = [UUID]()
        self.firstName = firstName
        self.lastName = lastName
        self.sex = sex
        
        family.addFamilyMember(self)
    }
    
    func generateCache() {
        // Make sure to invalidate cache first (cache -> nil), otherwise cache is assigned to cache
        self.siblingIDsCache = nil
        self.siblingIDsCache = self.siblingIDs
        self.childrenIDsCache = nil
        self.childrenIDsCache = self.childrenIDs
    }
    
    func isPerson(_ familyMember: FamilyMember) -> Bool {
        return self.id == familyMember.id
    }
    
    func isSpouse(to familyMember: FamilyMember) -> Bool {
        return self.spouseID != nil && self.spouseID == familyMember.id
    }
    
    func isExSpouse(to familyMember: FamilyMember) -> Bool {
        return self.exSpousesIDs.contains(familyMember.id)
    }
    
    func isMother(of familyMember: FamilyMember) -> Bool {
        return self.sex == .female && familyMember.parentIDs.contains(self.id)
    }
    
    func isFather(of familyMember: FamilyMember) -> Bool {
        return self.sex == .male && familyMember.parentIDs.contains(self.id)
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
        for parentID in self.parentIDs {
            if familyMember.parentIDs.contains(parentID) {
                return true
            }
        }
        return false
    }
    
    func isChild(of familyMember: FamilyMember) -> Bool {
        return self.parentIDs.contains(familyMember.id)
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
        guard child.parentIDs.count < 2 else {
            assertionFailure("Family members cannot have more than two parents")
            return
        }
        child.parentIDs.append(self.id)
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
        guard self.parentIDs.count < 2 else {
            assertionFailure("Family members cannot have more than two parents")
            return
        }
        self.parentIDs.append(parent.id)
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
    
    func isDescendant(of familyMember: FamilyMember) -> Bool {
        return familyMember.isAncestor(of: self)
    }
    
    func isAncestor(of familyMember: FamilyMember) -> Bool {
        if self.id == familyMember.id {
            return true
        }
        // Depth-first search through the parents of the familyMember
        for parent in familyMember.parents {
            if self.isAncestor(of: parent) {
                return true
            }
        }
        // If no parents are ancestors, return false
        return false
    }
    
}
