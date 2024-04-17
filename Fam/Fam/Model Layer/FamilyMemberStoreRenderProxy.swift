//
//  FamilyMemberStoreRenderProxy.swift
//  Fam
//
//  Created by Andre Pham on 18/4/2024.
//

import Foundation
import SwiftMath

class FamilyMemberStoreRenderProxy {
    
    private(set) var orderedFamilyMembers = [FamilyMemberRenderProxy]()
    private(set) var connections = [SMLine]()
    
    init(_ family: FamilyMemberStore, root: FamilyMember) {
        assert(family.contains(familyMember: root), "Family doesn't contain family member")
        self.generateOrderedFamilyMembers(family: family, root: root)
    }
    
    private func generateOrderedFamilyMembers(family: FamilyMemberStore, root: FamilyMember) {
        var visited = Set<UUID>()
        visited.insert(root.id)
        var queue = [FamilyMember]()
        queue.append(root)
        while !queue.isEmpty {
            let current = queue.removeFirst()
            let proxy = FamilyMemberRenderProxy(current)
            self.orderedFamilyMembers.append(proxy)
            let next = proxy.nextFamilyMembers
            for nextFamilyMember in next {
                if !visited.contains(nextFamilyMember.id) {
                    visited.insert(nextFamilyMember.id)
                    queue.append(nextFamilyMember)
                }
            }
        }
    }
    
}
