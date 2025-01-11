//
//  ParentsToChildrenConnectionRenderProxy.swift
//  Fam
//
//  Created by Andre Pham on 11/1/2025.
//

import Foundation

class ParentsToChildrenConnectionRenderProxy {
    
    public let parent1: FamilyMemberRenderProxy
    public let parent2: FamilyMemberRenderProxy?
    public let children: [FamilyMemberRenderProxy]
    
    init(parent: FamilyMemberRenderProxy, otherParent: FamilyMemberRenderProxy? = nil, children: [FamilyMemberRenderProxy]) {
        self.children = children
        self.parent1 = parent
        self.parent2 = otherParent
    }
    
}
