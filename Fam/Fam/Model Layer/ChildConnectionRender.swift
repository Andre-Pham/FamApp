//
//  ChildConnectionRender.swift
//  Fam
//
//  Created by Andre Pham on 18/4/2024.
//

import Foundation

class ChildConnectionRender {
    
    public let parentsConnection: CoupleConnectionRender
    public let child: FamilyMemberRenderProxy
    
    init(parentsConnection: CoupleConnectionRender, child: FamilyMemberRenderProxy) {
        self.parentsConnection = parentsConnection
        self.child = child
    }
    
}
