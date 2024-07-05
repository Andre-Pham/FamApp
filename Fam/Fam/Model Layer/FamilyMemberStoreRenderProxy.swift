//
//  FamilyMemberStoreRenderProxy.swift
//  Fam
//
//  Created by Andre Pham on 18/4/2024.
//

import Foundation
import SwiftMath

// TODO: Next:
// Clean up this file
// - [DONE] Remove commented out code
// - [DONE] Combine resolve render conflict functions (there's a lottt of overlap)
// - [DONE] Make offsetIncrement's default value Self.POSITION_PADDING
// - [DONE] Extract rules into functions
// - [DONE] If applicable, extract logic into FamilyMemberStoreUtil (like swapPositions(for proxy1, and proxy2))
// - [DONE] Add comments for clarity
// - [DONE] Clean up in general, like the fact that I keep having to refer to proxy with proxy.position! (extracting stages into functions will help with this)
// - [DONE] Rename variables (extracting stages into functions will help with this)
// - [DONE] After all this, add function headers to all functions (this will help readability, as these will need to be modified when I add ex spouses and stuff)
// TODO: After that:
// - Add basic buttons to create custom family trees and push edge cases
//   (like "add parents", "add son", "add daughter", "add spouse")
// TODO: After that:
// - Start creating the UI! woo hoo

class FamilyMemberStoreRenderProxy {
    
    public static let POSITION_PADDING = 150.0
    public static let COUPLES_PADDING = 100.0
    
    /// A store of all the family members
    private(set) var familyMemberProxiesStore = [UUID: FamilyMemberRenderProxy]()
    private(set) var orderedFamilyMemberProxies = [FamilyMemberRenderProxy]()
    private(set) var coupleConnections = [CoupleConnectionRender]()
    private(set) var childConnections = [ChildConnectionRender]()
    
    init(_ family: FamilyMemberStore, root: FamilyMember) {
        assert(family.contains(familyMember: root), "Family doesn't contain family member")
        self.generateOrderedFamilyMembers(family: family, root: root)
        self.generateFamilyMemberStore()
        self.generatePositions()
        self.generateCoupleConnections()
        self.generateChildConnections()
        self.bringCouplesCloser(by: Self.POSITION_PADDING - Self.COUPLES_PADDING)
    }
    
    /// Uses breadth-first search to generate an order in which the family members should be rendered. Saves family members in this order.
    /// - Parameters:
    ///   - family: The family members to be generated into an order
    ///   - root: The family member to start the breadth first search from
    private func generateOrderedFamilyMembers(family: FamilyMemberStore, root: FamilyMember) {
        var visited = Set<UUID>()
        visited.insert(root.id)
        var queue = [FamilyMember]()
        queue.append(root)
        while !queue.isEmpty {
            let current = queue.removeFirst()
            let proxy = FamilyMemberRenderProxy(current)
            self.orderedFamilyMemberProxies.append(proxy)
            let next = proxy.nextFamilyMembers
            for nextFamilyMember in next {
                if !visited.contains(nextFamilyMember.id) {
                    visited.insert(nextFamilyMember.id)
                    queue.append(nextFamilyMember)
                }
            }
        }
    }
    
    /// Populates the "id to family member" dictionary based on the ordered family members.
    private func generateFamilyMemberStore() {
        for proxy in self.orderedFamilyMemberProxies {
            self.familyMemberProxiesStore[proxy.id] = proxy
        }
    }
    
    /// Generate all the positions of all the proxies.
    /// Assumes all proxies have no position.
    private func generatePositions() {
        guard !self.orderedFamilyMemberProxies.isEmpty else {
            return
        }
        assert(!self.orderedFamilyMemberProxies.contains(where: { $0.hasPosition }), "Algorithm assumes no proxy family members have a position defined")
        let root = self.orderedFamilyMemberProxies.first!
        root.setPosition(to: SMPoint())
        for index in 1..<self.orderedFamilyMemberProxies.count {
            let proxy = self.orderedFamilyMemberProxies[index]
            assert(!proxy.hasPosition, "Failed logic, proxy expected to have no position")
            for previousIndex in stride(from: index - 1, through: 0, by: -1) {
                let proxyIsPositioned = self.positionProxyRelativeToOther(
                    proxy: proxy,
                    otherProxy: self.orderedFamilyMemberProxies[previousIndex]
                )
                guard proxyIsPositioned else {
                    // If the proxy wasn't positioned, continue iterating through previous proxies until there's one relative to the proxy that allows it to be placed
                    continue
                }
                
                // Enforce RULE 1
                self.positionProxyRelativeToChildren(proxy: proxy)
                self.positionProxyRelativeToParents(proxy: proxy)
                
                // Enforce RULE 2
                self.positionProxyAdjacentToSiblings(proxy: proxy)
                
                // Resolve any connection conflicts that occurred
                self.resolveConnectionConflicts(for: proxy)
                
                // Swap spouse positions if applicable
                self.swapCouplePositionsIfApplicable(for: proxy)
                
                assert(proxy.hasPosition)
                break
            }
        }
    }
    
    /// Attempt to place a proxy relative to another previously placed proxy based on their relationship.
    /// Assumes the proxy hasn't been placed yet (this acts as its initial placement).
    /// - Parameters:
    ///   - proxy: The proxy to place
    ///   - otherProxy: Another proxy to place the proxy relative to based on their relationship
    /// - Returns: True if the proxy was successfully placed (relative to the other proxy)
    private func positionProxyRelativeToOther(
        proxy: FamilyMemberRenderProxy,
        otherProxy: FamilyMemberRenderProxy
    ) -> Bool {
        assert(!proxy.hasPosition, "Attempting to initially place a proxy when it already has a position")
        guard var relativePosition = otherProxy.position?.clone() else {
            assertionFailure("Attempting to place a proxy relative to a proxy with no position")
            return false
        }
        if proxy.familyMember.isSpouse(to: otherProxy.familyMember) {
            proxy.setPosition(to: relativePosition + SMPoint(x: Self.POSITION_PADDING * (proxy.preferredDirection == .left ? -1 : 1), y: 0.0))
            self.resolveRenderConflicts(direction: proxy.preferredDirection, for: proxy)
            return true
        } else if proxy.familyMember.isExSpouse(to: otherProxy.familyMember) {
            proxy.setPosition(to: relativePosition + SMPoint(x: Self.POSITION_PADDING * (proxy.preferredDirection == .left ? -1 : 1), y: 0.0))
            self.resolveRenderConflicts(direction: proxy.preferredDirection, for: proxy)
            return true
        } else if proxy.familyMember.isParent(of: otherProxy.familyMember) {
            relativePosition -= SMPoint(x: 0.0, y: Self.POSITION_PADDING)
            proxy.setPosition(to: relativePosition)
            self.resolveRenderConflicts(direction: nil, for: proxy)
            return true
        } else if proxy.familyMember.isChild(of: otherProxy.familyMember) {
            relativePosition += SMPoint(x: 0.0, y: Self.POSITION_PADDING)
            proxy.setPosition(to: relativePosition)
            self.resolveRenderConflicts(direction: nil, for: proxy)
            return true
        }
        return false
    }
    
    /// Position a proxy relative to its children (if applicable). Assumes it's already placed to begin with.
    /// Forces the proxy, as a parent (if applicable), to conform to the rule:
    /// # RENDERING RULE 1
    /// If you prefer right, both your parents HAVE to be past your right side.
    /// (AKA if you have a child who prefers right, and your child has kids, you must be to the right of your child)
    /// If you prefer left, both your parents HAVE to be past your left side.
    /// (AKA if you have a child who prefers left, and your child has kids, you must be to the left of your child)
    /// # END OF RENDERING RULE 1
    /// - Parameters:
    ///   - proxy: The proxy to position
    private func positionProxyRelativeToChildren(proxy: FamilyMemberRenderProxy) {
        guard let proxyPosition = proxy.position else {
            assertionFailure("Function assumes proxy's position is already defined")
            return
        }
        guard proxy.familyMember.isParent else {
            return
        }
        let directChildrenWithRightPreferencePositions = self.getDirectChildrenProxies(
            for: proxy,
            directionPreference: .right
        ).compactMap({ $0.position })
        if !directChildrenWithRightPreferencePositions.isEmpty {
            let farthestRight = SMPointCollection(points: directChildrenWithRightPreferencePositions).maxX
            if let farthestRight, farthestRight.isGreater(than: proxyPosition.x) {
                self.anchorCouple(
                    to: SMPoint(x: farthestRight + Self.POSITION_PADDING, y: proxyPosition.y),
                    proxy: proxy,
                    anchor: .left
                )
                self.resolveRenderConflicts(direction: .right, for: proxy)
            }
        }
        let directChildrenWithLeftPreferencePositions = self.getDirectChildrenProxies(
            for: proxy,
            directionPreference: .left
        ).compactMap({ $0.position })
        if !directChildrenWithLeftPreferencePositions.isEmpty {
            let farthestLeft = SMPointCollection(points: directChildrenWithLeftPreferencePositions).minX
            if let farthestLeft, farthestLeft.isLess(than: proxyPosition.x) {
                self.anchorCouple(
                    to: SMPoint(x: farthestLeft - Self.POSITION_PADDING, y: proxyPosition.y),
                    proxy: proxy,
                    anchor: .right
                )
                self.resolveRenderConflicts(direction: .left, for: proxy)
            }
        }
    }
    
    /// Position a proxy relative to its parents (if applicable). Assumes it's already placed to begin with.
    /// Forces the proxy, as a child (if applicable), to conform to the rule:
    /// # RENDERING RULE 1
    /// If you prefer right, both your parents HAVE to be past your right side.
    /// (AKA if you have a child who prefers right, and your child has kids, you must be to the right of your child)
    /// If you prefer left, both your parents HAVE to be past your left side.
    /// (AKA if you have a child who prefers left, and your child has kids, you must be to the left of your child)
    /// # END OF RENDERING RULE 1
    /// - Parameters:
    ///   - proxy: The proxy to position
    private func positionProxyRelativeToParents(proxy: FamilyMemberRenderProxy) {
        guard let proxyPosition = proxy.position else {
            assertionFailure("Function assumes proxy's position is already defined")
            return
        }
        guard !proxy.familyMember.hasNoParents else {
            return
        }
        let rightParentX: Double? = self.getParentProxy(for: proxy, directionPreference: .right)?.position?.x
        let leftParentX: Double? = self.getParentProxy(for: proxy, directionPreference: .left)?.position?.x
        guard rightParentX != nil || leftParentX != nil else {
            return
        }
        switch proxy.preferredDirection {
        case .right:
            // Proxy prefers right - proxy must be left of parents (moved left)
            let farthestLeftX = min(rightParentX ?? leftParentX!, leftParentX ?? rightParentX!)
            if farthestLeftX.isLess(than: proxyPosition.x) {
                self.anchorCouple(
                    to: SMPoint(x: farthestLeftX - Self.POSITION_PADDING, y: proxyPosition.y),
                    proxy: proxy,
                    anchor: .right
                )
                self.resolveRenderConflicts(direction: .left, for: proxy)
            }
        case .left:
            // Proxy prefers left - proxy must be right of parents (moved right)
            let farthestRightX = max(rightParentX ?? leftParentX!, leftParentX ?? rightParentX!)
            if farthestRightX.isGreater(than: proxyPosition.x) {
                self.anchorCouple(
                    to: SMPoint(x: farthestRightX + Self.POSITION_PADDING, y: proxyPosition.y),
                    proxy: proxy,
                    anchor: .left
                )
                self.resolveRenderConflicts(direction: .right, for: proxy)
            }
        }
    }
    
    /// Position a proxy adjacent to its siblings.
    /// # RENDERING RULE 2
    /// If you have placed siblings, you or your spouse must be placed adjacent to your siblings or your siblings' spouses.
    /// # END OF RENDERING RULE 2
    /// - Parameters:
    ///   - proxy: The proxy to position
    private func positionProxyAdjacentToSiblings(proxy: FamilyMemberRenderProxy) {
        guard let proxyPosition = proxy.position else {
            assertionFailure("Function assumes proxy's position is already defined")
            return
        }
        let siblingProxies = self.getSiblingProxies(for: proxy)
        guard !siblingProxies.isEmpty else {
            return
        }
        let siblingSpouseProxies = self.getSpouseProxies(for: siblingProxies)
        let siblingPositions = siblingProxies.compactMap({ $0.position })
        let siblingSpousePositions = siblingSpouseProxies.compactMap({ $0.position })
        assert(!siblingPositions.isEmpty, "getSiblingProxies should filter out non-positioned proxies")
        // Since all siblings are adjacent (since this rule is applied), we can pick any sibling
        // We use this "any sibling" to pick the direction the proxy must go in to become adjacent
        let anySiblingPosition = siblingPositions.first!
        let siblingAppearsToTheRight = proxyPosition.x.isLess(than: anySiblingPosition.x)
        let direction: HorizontalDirection = siblingAppearsToTheRight ? .right : .left
        // We define a render conflict as when a proxy is not adjacent to a sibling or a sibling's spouse
        // We then move the proxy in the direction of the "any sibling" until this conflict is resolved
        self.resolveRenderConflicts(
            conflictCondition: { proxy in
                // Returns true if the proxy is not adjacent to a sibling or a sibling's spouse
                let pointCollection = SMPointCollection(points: siblingPositions + siblingSpousePositions)
                if let closestPoint = pointCollection.closestPoint(to: proxy.position!) {
                    assert(closestPoint.y.isEqual(to: proxy.position!.y), "Siblings should be rendered at the same y position")
                    let distance = closestPoint.length(to: proxy.position!)
                    return distance.isGreater(than: Self.POSITION_PADDING)
                } else {
                    assertionFailure("Closest point was not defined - logic error")
                    return false
                }
            },
            direction: direction,
            for: proxy
        )
        // After moving the sibling adjacent to their siblings, ensure position conflicts are resolved
        self.resolveRenderConflicts(direction: direction, for: proxy)
    }
    
    /// Attempts to resolve connection conflicts (When connections cross over one another).
    /// This occurs when some parents (on the same y level as the proxy's parents) are closer to the proxy than the proxy's parents are in that given direction.
    /// ``` A visual diagram:
    ///     [Proxy Parents] [Other Parents]
    ///           ╵---------------|---------[Proxy]
    ///                           ^ Conflict is here!
    /// ```
    /// The solution:
    /// 1. Get parents' y
    /// 2. Get all people who are parents at the same y
    /// 3. If the proxy is past the other parents (placed beyond the parents that aren't theirs), move them (resolve conflicts) in the opposite direction
    /// - Parameters:
    ///   - proxy: The proxy to position
    private func resolveConnectionConflicts(for proxy: FamilyMemberRenderProxy) {
        guard proxy.hasPosition else {
            assertionFailure("Function assumes proxy's position is already defined")
            return
        }
        let proxiesWithPotentialConflicts = [proxy, self.getSpouseProxy(for: proxy)].compactMap({ $0 })
        for proxyBeingResolved in proxiesWithPotentialConflicts {
            guard let proxyBeingResolvedPosition = proxyBeingResolved.position else {
                continue
            }
            guard let anyParent = self.getParentProxies(for: proxyBeingResolved).first,
                  let anyParentPosition = anyParent.position else {
                continue
            }
            // Get all the people who are parents at the same y
            let otherParentsXPositionsSameY = self.getSameLevelProxies(as: anyParent)
                .filter({ $0.familyMember.isParent && !$0.familyMember.isParent(of: proxyBeingResolved.familyMember) })
                .compactMap({ $0.position?.x })
            // These "closest" values represent the boundary the proxy should remain in
            // If the proxy goes past it, a connection conflict occurs, because the
            // parents' connection crosses over the other parents' connections to reach the proxy
            let closestOtherParentsToLeft: Double? = otherParentsXPositionsSameY
                .filter({ $0.isLess(than: anyParentPosition.x) })
                .max()
            let closestOtherParentsToRight: Double? = otherParentsXPositionsSameY
                .filter({ $0.isGreater(than: anyParentPosition.x) })
                .min()
            if let closestOtherParentsToRight,
               proxyBeingResolvedPosition.x.isGreater(than: closestOtherParentsToRight) {
                // A connection conflict exists because the proxy is too far right
                self.resolveRenderConflicts(
                    conflictCondition: { proxy in
                        return (
                            self.positionConflictExists(for: proxy)
                            || proxy.position!.x.isGreater(than: closestOtherParentsToRight)
                        )
                    },
                    direction: .left,
                    for: proxyBeingResolved
                )
            }
            if let closestOtherParentsToLeft,
               proxyBeingResolvedPosition.x.isLess(than: closestOtherParentsToLeft) {
                // A connection conflict exists because the proxy is too far left
                self.resolveRenderConflicts(
                    conflictCondition: { proxy in
                        return (
                            self.positionConflictExists(for: proxy)
                            || proxy.position!.x.isLess(than: closestOtherParentsToLeft)
                        )
                    },
                    direction: .right,
                    for: proxyBeingResolved
                )
            }
        }
    }
    
    /// Swaps the positions of a proxy and their spouse if beneficial.
    /// There's two reasons to do this.
    /// The most important one is if the left partner's parents are on the right, and the right partner's parents are on the left, it's a conflict that can easily be fixed by swapping the positions of the couple.
    /// The other scenario is, even if only partner has parents, it still looks nicer (and is more efficient for space) to have them closer to their own parents. Doing this pre-emptively fights against the first scenario.
    /// - Parameters:
    ///   - proxy: The proxy to position
    private func swapCouplePositionsIfApplicable(for proxy: FamilyMemberRenderProxy) {
        guard let proxyPosition = proxy.position else {
            assertionFailure("Function assumes proxy's position is already defined")
            return
        }
        guard let spouseProxy = self.getSpouseProxy(for: proxy),
              let spouseProxyPosition = spouseProxy.position else {
            return
        }
        if let averageParentPosition = self.getParentsPositionsAverage(for: proxy) {
            // 1. Get parents position
            // 2. Get the closest proxy
            // 3. If the closest proxy's preference isn't the direction the parents are in, swap
            let proxyDistance = proxyPosition.length(to: averageParentPosition)
            let spouseDistance = spouseProxyPosition.length(to: averageParentPosition)
            if spouseDistance.isLess(than: proxyDistance) {
                self.swapProxyPositionsAndPreferredDirections(proxy, spouseProxy)
            }
        } else if let averageSpouseParentPosition = self.getParentsPositionsAverage(for: spouseProxy) {
            let proxyDistance = proxyPosition.length(to: averageSpouseParentPosition)
            let spouseDistance = spouseProxyPosition.length(to: averageSpouseParentPosition)
            if proxyDistance.isLess(than: spouseDistance) {
                self.swapProxyPositionsAndPreferredDirections(proxy, spouseProxy)
            }
        }
    }
    
    /// Position a proxy (and their spouse, if available) at the position provided.
    /// If anchored right, the proxy and their spouse are positioned on the position and left of the position.
    /// If anchored left, the proxy and their spouse are positioned on the position and right of the position.
    /// The ordering of the proxy and their spouse (who goes on the position and who goes left/right) is determined by their direction preference.
    /// - Parameters:
    ///   - position: The position to anchor to (the position the proxy/spouse is set to)
    ///   - proxy: The proxy who's position and their spouse's position to set
    ///   - anchor: The direction of the partner who's position is set to the `position` parameter
    ///   - gap: The gap to set between the couple
    private func anchorCouple(
        to position: SMPoint,
        proxy: FamilyMemberRenderProxy,
        anchor: HorizontalDirection,
        gap: Double = FamilyMemberStoreRenderProxy.POSITION_PADDING
    ) {
        if let spouseProxy = self.getSpouseProxy(for: proxy) {
            let rightPreference = proxy.preferredDirection == .right ? proxy : spouseProxy
            let leftPreference = proxy.preferredDirection == .right ? spouseProxy : proxy
            switch anchor {
            case .right:
                rightPreference.setPosition(to: position)
                leftPreference.setPosition(to: position - SMPoint(x: gap, y: 0))
            case .left:
                leftPreference.setPosition(to: position)
                rightPreference.setPosition(to: position + SMPoint(x: gap, y: 0))
            }
        } else {
            proxy.setPosition(to: position)
        }
    }
    
    /// Resolves render conflicts for a family member render proxies.
    /// The condition for what is a "render conflict" is provided as an argument.
    /// Works by checking if any of the proxies meet the condition for the render conflict, then moving all the proxies in one direction, then repeating until non meet the condition.
    /// Note, this means if only one has a conflict, this still all move.
    /// - Parameters:
    ///   - conflictCondition: A callback iteratively triggered on every proxy provided to see if they (as a group) need to continue being moved; by default, a position conflict
    ///   - direction: The direction to move all the proxies (to solve the render conflicts); nil for any direction
    ///   - proxies: The proxies to move to resolve conflicts for
    ///   - offsetIncrement: The distance the proxies are moved each iteration (after checking at least one has a render conflict)
    ///   - groupSpouse: If true, the spouses of all the provided proxies are grouped in and also moved
    private func resolveRenderConflicts(
        conflictCondition: ((_ proxy: FamilyMemberRenderProxy) -> Bool)? = nil,
        direction: HorizontalDirection?,
        for proxies: FamilyMemberRenderProxy...,
        offsetIncrement: Double = FamilyMemberStoreRenderProxy.POSITION_PADDING,
        groupSpouse: Bool = true
    ) {
        let resolvedConflictCondition = conflictCondition ?? self.positionConflictExists(for:)
        var proxiesToMove = [UUID: FamilyMemberRenderProxy]()
        for startingProxy in proxies {
            if startingProxy.hasPosition {
                proxiesToMove[startingProxy.id] = startingProxy
                if let spouseProxy = self.getSpouseProxy(for: startingProxy), groupSpouse {
                    proxiesToMove[spouseProxy.id] = spouseProxy
                }
            } else {
                assertionFailure("Attempting to resolve render conflicts for a proxy with no position")
            }
        }
        guard !proxiesToMove.isEmpty else {
            return
        }
        for proxy in proxiesToMove.values {
            guard let proxyPosition = proxy.position else {
                assertionFailure("Logic error - all proxies must have a position")
                return
            }
            if proxiesToMove.values.contains(where: { proxy.id != $0.id && proxyPosition == $0.position }) {
                assertionFailure("Illegal - two proxies resolving conflicts together may not share the same position")
                return
            }
        }
        if let direction {
            let xTranslation = switch direction {
            case .right:
                abs(offsetIncrement)
            case .left:
                -1.0 * abs(offsetIncrement)
            }
            while proxiesToMove.values.contains(where: { resolvedConflictCondition($0) }) {
                for proxy in proxiesToMove.values {
                    proxy.position?.translate(by: SMPoint(x: xTranslation, y: 0))
                }
            }
        } else {
            let orderedProxies = Array(proxiesToMove.values)
            let startingPositions = orderedProxies.compactMap({ $0.position })
            guard orderedProxies.count == startingPositions.count else {
                assertionFailure("Logic error - all proxies must have a position")
                return
            }
            var sign = 1
            var xTranslation = abs(offsetIncrement)
            while orderedProxies.contains(where: { resolvedConflictCondition($0) }) {
                for proxyIndex in orderedProxies.indices {
                    let proxy = orderedProxies[proxyIndex]
                    let startingPosition = startingPositions[proxyIndex]
                    proxy.setPosition(to: SMPoint(x: startingPosition.x + Double(sign)*xTranslation, y: startingPosition.y))
                }
                sign *= -1
                if sign == 1 {
                    xTranslation += abs(offsetIncrement)
                }
            }
        }
    }
    
    /// Checks if a proxy shares its position with any other proxies.
    /// - Parameters:
    ///   - proxy: The proxy to check if it has any position conflicts
    /// - Returns: True if the provided proxy shares its position with another proxy
    private func positionConflictExists(for proxy: FamilyMemberRenderProxy) -> Bool {
        guard proxy.hasPosition else {
            assertionFailure("Checking if proxy with no position shares its (non-existent) position with any other proxies")
            return false
        }
        for otherProxy in self.orderedFamilyMemberProxies {
            if proxy.position == otherProxy.position && proxy.id != otherProxy.id {
                return true
            }
        }
        return false
    }
    
    /// Bring couples closer together so that the distance between them is reduced by a provided amount.
    /// - Parameters:
    ///   - distance: The distance to bring the couple closer by
    private func bringCouplesCloser(by distance: Double) {
        for coupleConnection in self.coupleConnections {
            if let leftPosition = coupleConnection.leftPartner.position,
               let rightPosition = coupleConnection.rightPartner.position {
                coupleConnection.leftPartner.setPosition(to: leftPosition + SMPoint(x: distance/2.0, y: 0))
                coupleConnection.rightPartner.setPosition(to: rightPosition - SMPoint(x: distance/2.0, y: 0))
            }
        }
    }
    
    private func generateCoupleConnections() {
        var connectedCouples = [UUID: UUID]()
        for proxy in self.orderedFamilyMemberProxies {
            if let spouseID = proxy.familyMember.spouseID, let spouseProxy = self.familyMemberProxiesStore[spouseID] {
                guard connectedCouples[proxy.id] == nil && connectedCouples[spouseID] == nil else {
                    continue
                }
                connectedCouples[proxy.id] = spouseID
                self.coupleConnections.append(CoupleConnectionRender(
                    partner1: proxy,
                    partner2: spouseProxy
                ))
            }
        }
    }
    
    private func generateChildConnections() {
        for coupleConnection in self.coupleConnections {
            let childrenIDs = coupleConnection.leftPartner.familyMember.childrenIDs
            guard childrenIDs.count > 0 else {
                continue
            }
            for childID in childrenIDs {
                guard let childProxy = self.familyMemberProxiesStore[childID] else {
                    assertionFailure("Could not find child when it should exist")
                    continue
                }
                self.childConnections.append(ChildConnectionRender(
                    parentsConnection: coupleConnection,
                    child: childProxy
                ))
            }
        }
    }
    
}
