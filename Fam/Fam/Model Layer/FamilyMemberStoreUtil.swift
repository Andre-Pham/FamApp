//
//  FamilyMemberStoreUtil.swift
//  Fam
//
//  Created by Andre Pham on 1/7/2024.
//

import Foundation
import SwiftMath

extension FamilyMemberStoreRenderProxy {
    
    func getDirectChildrenProxies(
        for proxy: FamilyMemberRenderProxy,
        directionPreference: HorizontalDirection? = nil,
        requirePosition: Bool = true
    ) -> [FamilyMemberRenderProxy] {
        let childrenIDs = proxy.familyMember.childrenIDs
        var childrenProxies = childrenIDs.compactMap({ self.familyMemberProxiesStore[$0] })
        if let directionPreference {
            childrenProxies = childrenProxies.filter({ $0.preferredDirection == directionPreference })
        }
        return requirePosition ? childrenProxies.filter({ $0.position != nil }) : childrenProxies
    }
    
    func getSiblingProxies(
        for proxy: FamilyMemberRenderProxy,
        directionPreference: HorizontalDirection? = nil,
        requirePosition: Bool = true
    ) -> [FamilyMemberRenderProxy] {
        let siblingIDs = proxy.familyMember.siblingIDs
        var siblingProxies = siblingIDs.compactMap({ self.familyMemberProxiesStore[$0] })
        if let directionPreference {
            siblingProxies = siblingProxies.filter({ $0.preferredDirection == directionPreference })
        }
        return requirePosition ? siblingProxies.filter({ $0.position != nil }) : siblingProxies
    }
    
    func getSpouseProxy(
        for proxy: FamilyMemberRenderProxy,
        requirePosition: Bool = true
    ) -> FamilyMemberRenderProxy? {
        guard let spouseID = proxy.familyMember.spouseID,
              let spouseProxy = self.familyMemberProxiesStore[spouseID] else {
            return nil
        }
        return (!requirePosition || spouseProxy.position != nil) ? spouseProxy : nil
    }
    
    func getParentProxy(
        for proxy: FamilyMemberRenderProxy,
        directionPreference: HorizontalDirection,
        requirePosition: Bool = true
    ) -> FamilyMemberRenderProxy? {
        let parentProxies = proxy.familyMember.parentIDs.compactMap({ self.familyMemberProxiesStore[$0] })
        assert(parentProxies.filter({ $0.preferredDirection == directionPreference }).count <= 1, "There should only ever be one parent with the matching direction")
        guard let parentWithDirection = parentProxies.first(where: { $0.preferredDirection == directionPreference }) else {
            return nil
        }
        return (!requirePosition || parentWithDirection.position != nil) ? parentWithDirection : nil
    }
    
    func getParentProxies(
        for proxy: FamilyMemberRenderProxy,
        requirePosition: Bool = true
    ) -> [FamilyMemberRenderProxy] {
        let parentProxies = proxy.familyMember.parentIDs.compactMap({ self.familyMemberProxiesStore[$0] })
        return requirePosition ? parentProxies.filter({ $0.position != nil }) : parentProxies
    }
    
    func getSpouseProxies(
        for proxies: [FamilyMemberRenderProxy],
        requirePosition: Bool = true
    ) -> [FamilyMemberRenderProxy] {
        return proxies.compactMap({
            if let spouseID = $0.familyMember.spouseID {
                let spouseProxy = self.familyMemberProxiesStore[spouseID]
                return (!requirePosition || spouseProxy?.position != nil) ? spouseProxy : nil
            }
            return nil
        })
    }
    
    func getSameLevelProxies(as proxy: FamilyMemberRenderProxy) -> [FamilyMemberRenderProxy] {
        guard let level = proxy.position?.y else {
            assertionFailure("Attempting to get proxies that match the y value of a proxy with no y value")
            return []
        }
        return self.familyMemberProxiesStore.values.filter({ $0.position?.y == level })
    }
    
    func getParentsPositionsAverage(for proxy: FamilyMemberRenderProxy) -> SMPoint? {
        let parentProxyPositions = self.getParentProxies(for: proxy).compactMap({ $0.position })
        return SMPointCollection(points: parentProxyPositions).averagePoint
    }
    
    func swapProxyPositionsAndPreferredDirections(
        _ proxy1: FamilyMemberRenderProxy,
        _ proxy2: FamilyMemberRenderProxy
    ) {
        let tempPosition = proxy1.position
        let tempDirection = proxy1.preferredDirection
        proxy1.setPosition(to: proxy2.position)
        proxy1.setPreferredDirection(to: proxy2.preferredDirection)
        proxy2.setPosition(to: tempPosition)
        proxy2.setPreferredDirection(to: tempDirection)
    }
    
}
