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
    private var orderedFamilyMembersCache: [FamilyMember]? = nil
    /// True if the cache is still valid. Default is false because there is no cache.
    private(set) var cacheIsValid = false
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
        if let orderedFamilyMembersCache {
            return orderedFamilyMembersCache
        }
        return Array(self.familyMembers.values).sorted(by: { $0.consistentSortingID < $1.consistentSortingID })
    }
    
    func addFamilyMember(_ familyMember: FamilyMember) {
        self.familyMembers[familyMember.id] = familyMember
        // Adding a family member invalidates cache
        self.cacheIsValid = false
    }
    
    func getFamilyMemberWithMostAncestors() -> FamilyMember? {
        assert(self.cacheIsValid, "Expected to have valid cache before calling this")
        let familyMembers = self.getAllFamilyMembers()
        guard !familyMembers.isEmpty else {
            return nil
        }
        guard familyMembers.count > 1 else {
            return familyMembers[0]
        }
        var result = familyMembers[0]
        var resultAncestorCount = {
            var count = 0
            for familyMember in familyMembers {
                if result.isDescendant(of: familyMember) {
                    count += 1
                }
            }
            return count
        }()
        for familyMember in familyMembers {
            var count = 0
            for otherFamilyMember in familyMembers {
                if familyMember.isDescendant(of: otherFamilyMember) {
                    count += 1
                }
            }
            if count > resultAncestorCount {
                result = familyMember
                resultAncestorCount = count
            }
        }
        return result
    }
    
    func generateCache() {
        // Make sure to invalidate cache first (cache -> nil), otherwise cache is assigned to cache
        self.orderedFamilyMembersCache = nil
        self.orderedFamilyMembersCache = self.getAllFamilyMembers()
        for familyMember in self.familyMembers.values {
            familyMember.generateCache()
        }
        self.cacheIsValid = true
    }
    
}
