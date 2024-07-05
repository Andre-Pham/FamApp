//
//  FamilyMemberStoreRenderProxy.swift
//  Fam
//
//  Created by Andre Pham on 18/4/2024.
//

import Foundation
import SwiftMath

class FamilyMemberStoreRenderProxy {
    
    enum HorizontalDirection {
        case right
        case left
    }
    
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
        assert(!self.orderedFamilyMemberProxies.contains(where: { $0.position != nil }), "Algorithm assumes no proxy family members have a position defined")
        let root = self.orderedFamilyMemberProxies.first!
        root.setPosition(to: SMPoint())
        for index in 1..<self.orderedFamilyMemberProxies.count {
            let proxy = self.orderedFamilyMemberProxies[index]
            assert(proxy.position == nil, "Failed logic")
            
            for previousIndex in stride(from: index - 1, through: 0, by: -1) {
                let previous = self.orderedFamilyMemberProxies[previousIndex]
                guard var position = previous.position?.clone() else {
                    continue
                }
                if proxy.familyMember.isSpouse(to: previous.familyMember) {
                    proxy.setPosition(to: position + SMPoint(x: Self.POSITION_PADDING * (proxy.preferredDirection == .left ? -1 : 1), y: 0.0))
                    self.resolveRenderConflicts(direction: proxy.preferredDirection, for: proxy)
                } else if proxy.familyMember.isExSpouse(to: previous.familyMember) {
                    proxy.setPosition(to: position + SMPoint(x: Self.POSITION_PADDING * (proxy.preferredDirection == .left ? -1 : 1), y: 0.0))
                    self.resolveRenderConflicts(direction: proxy.preferredDirection, for: proxy)
                } else if proxy.familyMember.isParent(of: previous.familyMember) {
                    position -= SMPoint(x: 0.0, y: Self.POSITION_PADDING)
                    proxy.setPosition(to: position)
                    self.resolveRenderConflicts(direction: nil, for: proxy)
                } else if proxy.familyMember.isChild(of: previous.familyMember) {
                    position += SMPoint(x: 0.0, y: Self.POSITION_PADDING)
                    proxy.setPosition(to: position)
                    self.resolveRenderConflicts(direction: nil, for: proxy)
                }
                guard let setPosition = proxy.position else {
                    continue
                }
                
                // TODO: Next:
                // Clean up this file
                // - Remove commented out code
                // - Combine resolve render conflict functions (there's a lottt of overlap)
                // - Make offsetIncrement's default value Self.POSITION_PADDING
                // - Extract rules into functions
                // - If applicable, extract logic into FamilyMemberStoreUtil (like swapPositions(for proxy1, and proxy2))
                // - Add comments for clarity
                // - Clean up in general, like the fact that I keep having to refer to proxy with proxy.position! (extracting stages into functions will help with this)
                // - Rename variables (extracting stages into functions will help with this)
                // - After all this, add function headers to all functions (this will help readability, as these will need to be modified when I add ex spouses and stuff)
                // TODO: After that:
                // - Add basic buttons to create custom family trees and push edge cases
                //   (like "add parents", "add son", "add daughter", "add spouse")
                // TODO: After that:
                // - Start creating the UI! woo hoo
                
                // Enforce rule:
                // If you prefer right, both your parents HAVE to be past your right side
                // (AKA if you have a child who prefers right, and your child has kids, you must be to the right of your child)
                // If you prefer left, both your parents HAVE to be past your left side
                // (AKA if you have a child who prefers left, and your child has kids, you must be to the left of your child)
                // Case 1: Proxy is the parent (that needs to move)
                let directChildrenWithRightPreferencePositions = self.getDirectChildrenProxies(
                    for: proxy,
                    directionPreference: .right
                ).compactMap({ $0.position })
                if !directChildrenWithRightPreferencePositions.isEmpty {
                    if let farthestRight = SMPointCollection(points: directChildrenWithRightPreferencePositions).maxX,
                       farthestRight.isGreater(than: setPosition.x) {
                        self.anchorCouple(
                            to: SMPoint(x: farthestRight + Self.POSITION_PADDING, y: setPosition.y),
                            proxy: proxy,
                            anchor: .left,
                            gap: Self.POSITION_PADDING
                        )
                        self.resolveRenderConflicts(direction: .right, for: proxy)
                    }
                }
                let directChildrenWithLeftPreferencePositions = self.getDirectChildrenProxies(
                    for: proxy,
                    directionPreference: .left
                ).compactMap({ $0.position })
                if !directChildrenWithLeftPreferencePositions.isEmpty {
                    if let farthestLeft = SMPointCollection(points: directChildrenWithLeftPreferencePositions).minX,
                       farthestLeft.isLess(than: setPosition.x) {
                        self.anchorCouple(
                            to: SMPoint(x: farthestLeft - Self.POSITION_PADDING, y: setPosition.y),
                            proxy: proxy,
                            anchor: .right,
                            gap: Self.POSITION_PADDING
                        )
                        self.resolveRenderConflicts(direction: .left, for: proxy)
                    }
                }
                
                // Case 2: Proxy is the child (that needs to move)
                if proxy.familyMember.isParent {
                    let rightParentX: Double? = self.getParentProxy(for: proxy, directionPreference: .right)?.position?.x
                    let leftParentX: Double? = self.getParentProxy(for: proxy, directionPreference: .left)?.position?.x
                    if rightParentX != nil || leftParentX != nil {
                        switch proxy.preferredDirection {
                        case .right:
                            // Parent prefers right - proxy must be left
                            let farthestLeft = min(rightParentX ?? leftParentX!, leftParentX ?? rightParentX!)
                            if farthestLeft.isLess(than: setPosition.x) {
                                self.anchorCouple(
                                    to: SMPoint(x: farthestLeft - Self.POSITION_PADDING, y: setPosition.y),
                                    proxy: proxy,
                                    anchor: .right,
                                    gap: Self.POSITION_PADDING
                                )
                                self.resolveRenderConflicts(direction: .left, for: proxy)
                            }
                        case .left:
                            // Parent prefers left - proxy must be right
                            let farthestRight = max(rightParentX ?? leftParentX!, leftParentX ?? rightParentX!)
                            if farthestRight.isGreater(than: setPosition.x) {
                                self.anchorCouple(
                                    to: SMPoint(x: farthestRight + Self.POSITION_PADDING, y: setPosition.y),
                                    proxy: proxy,
                                    anchor: .left,
                                    gap: Self.POSITION_PADDING
                                )
                                self.resolveRenderConflicts(direction: .right, for: proxy)
                            }
                        }
                    }
                }
                
                // Enforce rule:
                // If you have placed siblings, you must be placed adjacent to them or their spouses
                let siblingProxies = self.getSiblingProxies(for: proxy)
                if !siblingProxies.isEmpty {
                    let siblingSpouseProxies = self.getSpouseProxies(for: siblingProxies)
                    let siblingPositions = siblingProxies.compactMap({ $0.position })
                    let siblingSpousePositions = siblingSpouseProxies.compactMap({ $0.position })
                    assert(!siblingPositions.isEmpty, "getSiblingProxies should filter out non-positioned proxies")
                    let anySiblingPosition = siblingPositions.first!
                    let siblingAppearsToTheRight = proxy.position!.x.isLess(than: anySiblingPosition.x)
                    let direction: HorizontalDirection = siblingAppearsToTheRight ? .right : .left
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
                    // After moving the sibling adjacent to their siblings, ensure render conflicts are resolved
                    self.resolveRenderConflicts(direction: direction, for: proxy)
                }
                
                // Resolve any connection conflicts that occurred
                // (When connections cross over one another)
                // 1. Get parents' y
                // 2. Get all people who are parents at the same y
                // 3. If the proxy is past the other parents (placed beyond the parents that aren't theirs), move them (resolve conflicts) in the opposite direction
                for proxyWithPotentialConnectionConflict in [proxy, self.getSpouseProxy(for: proxy)] {
                    guard let proxyWithPotentialConnectionConflict else {
                        continue
                    }
                    if let anyParent = self.getParentProxies(for: proxyWithPotentialConnectionConflict).first,
                       let anyParentPosition = anyParent.position {
                        // Get all the people who are parents at the same y
                        let otherParentsXPositionsSameY = self.getSameLevelProxies(as: anyParent)
                            .filter({ $0.familyMember.isParent && !$0.familyMember.isParent(of: proxyWithPotentialConnectionConflict.familyMember) })
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
                        // If true, proxy further right than the parents closest to the right of proxy's parents
                        let connectionConflictExistsRight = closestOtherParentsToRight != nil && proxyWithPotentialConnectionConflict.position!.x.isGreater(than: closestOtherParentsToRight!)
                        if connectionConflictExistsRight {
                            self.resolveRenderConflicts(
                                conflictCondition: { proxy in
                                    return self.positionConflictExists(for: proxy) || proxy.position!.x.isGreater(than: closestOtherParentsToRight!)
                                },
                                direction: .left,
                                for: proxyWithPotentialConnectionConflict
                            )
                        }
                        // If true, proxy further right than the parents closest to the right of proxy's parents
                        let connectionConflictExistsLeft = closestOtherParentsToLeft != nil && proxyWithPotentialConnectionConflict.position!.x.isLess(than: closestOtherParentsToLeft!)
                        if connectionConflictExistsLeft {
                            self.resolveRenderConflicts(
                                conflictCondition: { proxy in
                                    return self.positionConflictExists(for: proxy) || proxy.position!.x.isLess(than: closestOtherParentsToLeft!)
                                },
                                direction: .right,
                                for: proxyWithPotentialConnectionConflict
                            )
                        }
                    }
                }
                
                // Swap spouse positions if necessary
                if let spouseProxy = self.getSpouseProxy(for: proxy) {
                    let triggerPositionSwap = {
                        let temp = proxy.position
                        proxy.setPosition(to: spouseProxy.position)
                        spouseProxy.setPosition(to: temp)
                        proxy.togglePreferenceDirection()
                        spouseProxy.togglePreferenceDirection()
                    }
                    if let averageParentPosition = self.getParentsPositionsAverage(for: proxy){
                        // 1. get parents position
                        // 2. get the closest proxy
                        // 3. if the closest proxy's preference isn't the direction the parents are in, swap
                        let proxyDistance = proxy.position!.length(to: averageParentPosition)
                        let spouseDistance = spouseProxy.position!.length(to: averageParentPosition)
                        if spouseDistance.isLess(than: proxyDistance) {
                            triggerPositionSwap()
                        }
                    } else if let averageSpouseParentPosition = self.getParentsPositionsAverage(for: spouseProxy) {
                        let proxyDistance = proxy.position!.length(to: averageSpouseParentPosition)
                        let spouseDistance = spouseProxy.position!.length(to: averageSpouseParentPosition)
                        if proxyDistance.isLess(than: spouseDistance) {
                            triggerPositionSwap()
                        }
                    }
                }
                
                assert(proxy.position != nil)
                break
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
