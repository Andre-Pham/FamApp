//
//  ChildConnectionRenderProxy.swift
//  Fam
//
//  Created by Andre Pham on 18/4/2024.
//

import Foundation

class ChildConnectionRenderProxy {
    
    public let parentsConnection: CoupleConnectionRenderProxy
    public let child: FamilyMemberRenderProxy
    
    init(parentsConnection: CoupleConnectionRenderProxy, child: FamilyMemberRenderProxy) {
        self.parentsConnection = parentsConnection
        self.child = child
    }
    
}
