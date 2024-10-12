//
//  FamilyMemberStoreUtil.swift
//  Fam
//
//  Created by Andre Pham on 1/7/2024.
//

import Foundation
import SwiftMath

extension FamilyRenderProxy {
    
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
    
    /// Get all the proxies with a y position equal to the passed proxy.
    /// - Parameters:
    ///   - proxy: The proxy whose y position will be used
    ///   - includeProxy: True to include the passed proxy in the results (default is true)
    /// - Returns: Proxies that have the same y position as the passed proxy
    func getSameLevelProxies(
        as proxy: FamilyMemberRenderProxy,
        includeProxy: Bool = true,
        includeProxySpouse: Bool = true
    ) -> [FamilyMemberRenderProxy] {
        guard let level = proxy.position?.y else {
            assertionFailure("Attempting to get proxies that match the y value of a proxy with no y value")
            return []
        }
        var levelProxies = self.familyMemberProxiesStore.values
            .filter({ $0.position?.y == level })
            .sorted(by: { $0.consistentSortingID < $1.consistentSortingID })
        if !includeProxy {
            levelProxies.removeAll(where: { $0.id == proxy.id })
        }
        if !includeProxySpouse, let proxySpouse = self.getSpouseProxy(for: proxy) {
            levelProxies.removeAll(where: { $0.id == proxySpouse.id })
        }
        return levelProxies
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
    
    func getTheDirection(from fromPosition: SMPoint, to toPosition: SMPoint) -> HorizontalDirection? {
        guard !fromPosition.x.isEqual(to: toPosition.x) else {
            return nil
        }
        return fromPosition.x.isLess(than: toPosition.x) ? .right : .left
    }
    
    func checkProxiesAreAdjacent(_ proxies: [FamilyMemberRenderProxy], spacing: Double) -> Bool {
        guard !proxies.isEmpty else {
            assertionFailure("Checking proxies are adjacent when no proxies were passed in")
            return false
        }
        guard proxies.allSatisfy({ $0.hasPosition }) else {
            assertionFailure("Checking proxies are adjacent when they don't even have a position")
            return false
        }
        guard proxies.allSatisfy({ $0.position!.y == proxies[0].position!.y }) else {
            assertionFailure("Checking proxies are adjacent when they're not even on the same level")
            return false
        }
        guard proxies.count > 1 else {
            assertionFailure("Requires minimum two proxies to check if they're adjacent")
            return true
        }
        guard spacing.isGreaterThanZero() else {
            assertionFailure("Spacing between proxies must be a positive distance")
            return false
        }
        let proxyXPositionsSorted = proxies.map({ $0.position!.x }).sorted()
        for (index, proxyXPosition) in proxyXPositionsSorted.enumerated() {
            let firstProxy = proxyXPositionsSorted[0]
            let expectedDistanceToFirstProxy = spacing*Double(index)
            let isExpectedDistance = (proxyXPosition - expectedDistanceToFirstProxy).isEqual(to: firstProxy)
            if !isExpectedDistance {
                return false
            }
        }
        return true
    }
    
}
