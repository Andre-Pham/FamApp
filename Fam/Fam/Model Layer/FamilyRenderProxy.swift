//
//  FamilyRenderProxy.swift
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
// - [DONE] Add basic buttons to create custom family trees and push edge cases
//   (like "add parents", "add son", "add daughter", "add spouse")
// - Fix bugs:
// - [DONE] Give Carolyn parents. There's no reason Carolyn and Joe shouldn't switch positions, but they don't.
// - Give Cees a spouse and a child. They should be moved to the end of their siblings. The rule is, in a row of siblings, those with parents should be on the ends.
// - [DONE] Give Thahn-Lien parents. Her parents' positions should be swapped with Will and Johanna. Why are they over to the right. And why is Andre all the way to the right too.
// - [DONE] Give Jade Husband 3 children.
// - [DONE] Give Thahn-Lien parents. Then give Carolyn parents. Stop at step 20.
// - [DONE] Give Thahn-Lien parents. Then give Carolyn parents. Then stop at step 25.
// - [DONE] Give Thahn-Lien parents. Then give Carolyn parents. This creates a conflict that doesn't need to exist. Carolyn and above would need to swap with will + children... Tricky..
// - Give Jade Husband 3 children. Give give Andre a spouse, then lots of children. There's a gap!
// TODO: After that:
// - Generate an algorithm to automatically pick the root - refer to my reminders app
// - Write a billion tests to make sure this algorithm stays in tact
// - Write up a proper steps implementation - save stopAtStep as a variable and uncomment the assertions and all that, stopAtStep is not temp
// - Write a proper implementation for tracing - save an array of traces (strings) and have an option to print out or log them or whatever, they're super helpful for debugging
// TODO: After that:
// - Start creating the UI! woo hoo

class FamilyRenderProxy {
    
    public static let POSITION_PADDING = 150.0
    public static let COUPLES_PADDING = 100.0
    
    /// A store of all the family members
    private(set) var familyMemberProxiesStore = [UUID: FamilyMemberRenderProxy]()
    private(set) var orderedFamilyMemberProxies = [FamilyMemberRenderProxy]()
    private(set) var coupleConnections = [CoupleConnectionRenderProxy]()
    private(set) var childConnections = [ChildConnectionRenderProxy]()
    
    init(_ family: Family, root: FamilyMember, stopAtStep: Int?) {
        print("--------------------------------------------------------------")
        print("STARTING RENDER (step: \(stopAtStep ?? 0))")
        print("--------------------------------------------------------------")
        assert(family.contains(familyMember: root), "Family doesn't contain family member")
        self.generateOrderedFamilyMembers(family: family, root: root)
        self.generateFamilyMemberStore()
        self.generatePositions(stopAtStep: stopAtStep)
        self.generateCoupleConnections()
        self.generateChildConnections()
        self.bringCouplesCloser(by: Self.POSITION_PADDING - Self.COUPLES_PADDING)
        print("--------------------------------------------------------------")
        print("COMPLETED RENDER (step: \(stopAtStep ?? 0))")
        print("--------------------------------------------------------------")
    }
    
    func countConnectionConflicts() -> Int {
        var connections = [SMLineSegment]()
        for childConnection in self.childConnections {
            guard let parentPosition1 = childConnection.parentsConnection.leftPartner.position?.clone(),
                  let parentPosition2 = childConnection.parentsConnection.rightPartner.position?.clone(),
                  let childPosition = childConnection.child.position?.clone() else {
//                assertionFailure("Missing positions for parents") // NOTE: Commented out for steps
                continue
            }
            let positionBetweenParents = SMLineSegment(origin: parentPosition1, end: parentPosition2).midPoint
            let connection = SMLineSegment(origin: positionBetweenParents, end: childPosition)
            connections.append(connection)
        }
        var conflictsCount = 0
        // For every connection, check against every connection after it
        // If they have an intersection that isn't their vertices, there's a conflict
        for (index, connection) in connections.dropLast().enumerated() {
            for index in (index + 1)..<connections.count {
                let otherConnection = connections[index]
                if let intersection = connection.intersection(with: otherConnection) {
                    if !SMPointCollection(points: connection.vertices + otherConnection.vertices).containsPoint(intersection) {
                        conflictsCount += 1
                    }
                }
            }
        }
        return conflictsCount
    }
    
    func countPositionConflicts() -> Int {
        let allPoints = self.familyMemberProxiesStore.values.compactMap({ $0.position })
        return SMPointCollection(points: allPoints).countDuplicatedPoints()
    }
    
    /// Uses breadth-first search to generate an order in which the family members should be rendered. Saves family members in this order.
    /// - Parameters:
    ///   - family: The family members to be generated into an order
    ///   - root: The family member to start the breadth first search from
    private func generateOrderedFamilyMembers(family: Family, root: FamilyMember) {
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
//        for a in self.orderedFamilyMemberProxies {
//            print(a.familyMember.fullName)
//        }
    }
    
    /// Populates the "id to family member" dictionary based on the ordered family members.
    private func generateFamilyMemberStore() {
        for proxy in self.orderedFamilyMemberProxies {
            self.familyMemberProxiesStore[proxy.id] = proxy
        }
    }
    
    /// Generate all the positions of all the proxies.
    /// Assumes all proxies have no position.
    private func generatePositions(stopAtStep: Int?) {
        guard !self.orderedFamilyMemberProxies.isEmpty else {
            return
        }
        assert(!self.orderedFamilyMemberProxies.contains(where: { $0.hasPosition }), "Algorithm assumes no proxy family members have a position defined")
        let root = self.orderedFamilyMemberProxies.first!
        root.setPosition(to: SMPoint())
        for index in 1..<self.orderedFamilyMemberProxies.count {
            if let stopAtStep, index > stopAtStep {
                return
            }
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
                
                // Resolve any conflicts that can be resolved by swapping parents
                self.resolveConnectionConflictsBySwappingCouples(for: proxy)
                
                // - Give Thahn-Lien parents. Then give Carolyn parents. Then stop at step 25.
                // TODO: Swap sibling positions if applicable
                // Check if this proxy's parents are causing a conflict.
                // If so, shift this proxy's position (and spouse if applicable) with every one of their siblings to see if it fixes the conflict.
                // If fixed - good. Otherwise, revert.
                // Swapping (shifting) should always be valid and never cause conflict because the net room will be the same. THIS ASSUMES NO GAPS BETWEEN SIBLINGS SO STILL CHECK.
                // E.g. swapping proxy with couple 1
                // [couple1 husband] [couple1 wife] [proxy] -> [proxy] [couple1 husband] [couple1 wife]
                // [couple1 husband] [couple1 wife] [proxy] [couple2 husband] [couple2 wife] -> [proxy] [couple1 husband] [couple1 wife] [couple2 husband] [couple2 wife]
                // [couple1 husband] [couple1 wife] [proxy] [proxy wife] -> [proxy] [proxy wife] [couple1 husband] [couple1 wife]
                self.resolveConnectionConflictsBySwappingSiblings(for: proxy)
                
                // Resolve any connection conflicts that occurred
                self.resolveConnectionConflicts(for: proxy)
                
                // Swap spouse positions if applicable
                self.swapCouplePositionsIfApplicable(for: proxy)
                
                for anyProxy in self.orderedFamilyMemberProxies where anyProxy.hasPosition {
                    self.resolveConnectionConflictsBySwappingCouples(for: anyProxy)
                }
                
                // TODO: - Cleanup routine
                // Here, run a cleanup routine on ALL placed proxies.
                // Anyone in a weird position where they can be placed in a much more reasonable position should be done so.
                // Like if a child is placed super far away from their parents, and there's a space right under the parents with
                // no conflicts, it's a no brainer.
                // I should only implement this after the actual algorithm places everyone with conflicts.
                // It's just to make it look nicer.
                // Test thoroughly for situations that cause functional but spaced-weird positions, and fix them here.
                //
                // The current idea is:
                // 1. Find the ideal position for a proxy (or a couple, whatever)
                // 2. Move the proxy to the closest free position to that ideal position, given the space between that new position and the proxy's old position are empty
                // An easy example is placing parents closer between their children (in the middle of them)
                
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
            proxy.setPosition(to: relativePosition + SMPoint(x: Self.POSITION_PADDING*proxy.preferredDirection.directionMultiplier, y: 0.0))
            print("[TRACE] \(proxy.familyMember.fullName) initially placed: \(proxy.position?.toString() ?? "nil")")
            // No direction preference - you're being placed relative to your spouse which already has a position
            self.resolveRenderConflicts(direction: nil, for: proxy)
            print("[TRACE] \(proxy.familyMember.fullName) placed relative to spouse: \(proxy.position?.toString() ?? "nil")")
            return true
        } else if proxy.familyMember.isExSpouse(to: otherProxy.familyMember) {
            proxy.setPosition(to: relativePosition + SMPoint(x: Self.POSITION_PADDING*proxy.preferredDirection.directionMultiplier, y: 0.0))
            print("[TRACE] \(proxy.familyMember.fullName) initially placed: \(proxy.position?.toString() ?? "nil")")
            self.resolveRenderConflicts(direction: proxy.preferredDirection, for: proxy)
            print("[TRACE] \(proxy.familyMember.fullName) placed relative to ex spouse: \(proxy.position?.toString() ?? "nil")")
            return true
        } else if proxy.familyMember.isParent(of: otherProxy.familyMember) {
            relativePosition -= SMPoint(x: 0.0, y: Self.POSITION_PADDING)
            proxy.setPosition(to: relativePosition)
            print("[TRACE] \(proxy.familyMember.fullName) initially placed: \(proxy.position?.toString() ?? "nil")")
            self.resolveRenderConflicts(direction: nil, for: proxy)
            print("[TRACE] \(proxy.familyMember.fullName) placed relative to child: \(proxy.position?.toString() ?? "nil")")
            return true
        } else if proxy.familyMember.isChild(of: otherProxy.familyMember) {
            relativePosition += SMPoint(x: 0.0, y: Self.POSITION_PADDING)
            proxy.setPosition(to: relativePosition)
            print("[TRACE] \(proxy.familyMember.fullName) initially placed: \(proxy.position?.toString() ?? "nil")")
            self.resolveRenderConflicts(direction: nil, for: proxy)
            print("[TRACE] \(proxy.familyMember.fullName) placed relative to parent: \(proxy.position?.toString() ?? "nil")")
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
            // Move proxy right of children who prefers right and has kids
            let farthestRight = SMPointCollection(points: directChildrenWithRightPreferencePositions).maxX
            if let farthestRight, farthestRight.isGreater(than: proxyPosition.x) {
                self.anchorCouple(
                    to: SMPoint(x: farthestRight, y: proxyPosition.y),
                    proxy: proxy,
                    anchor: .left
                )
                self.resolveRenderConflicts(direction: .right, for: proxy)
                print("[TRACE] {positionProxyRelativeToChildren} \(proxy.familyMember.fullName) moved right of children who prefer right and have kids: \(proxy.position?.toString() ?? "nil")")
            }
        }
        let directChildrenWithLeftPreferencePositions = self.getDirectChildrenProxies(
            for: proxy,
            directionPreference: .left
        ).compactMap({ $0.position })
        if !directChildrenWithLeftPreferencePositions.isEmpty {
            // Move proxy left of children who prefers left and has kids
            let farthestLeft = SMPointCollection(points: directChildrenWithLeftPreferencePositions).minX
            if let farthestLeft, farthestLeft.isLess(than: proxyPosition.x) {
                self.anchorCouple(
                    to: SMPoint(x: farthestLeft, y: proxyPosition.y),
                    proxy: proxy,
                    anchor: .right
                )
                self.resolveRenderConflicts(direction: .left, for: proxy)
                print("[TRACE] {positionProxyRelativeToChildren} \(proxy.familyMember.fullName) moved left of children who prefer left and have kids: \(proxy.position?.toString() ?? "nil")")
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
                print("[TRACE] {positionProxyRelativeToParents} \(proxy.familyMember.fullName) moved left of parents: \(proxy.position?.toString() ?? "nil")")
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
                print("[TRACE] {positionProxyRelativeToParents} \(proxy.familyMember.fullName) moved right of parents: \(proxy.position?.toString() ?? "nil")")
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
        print("[TRACE] {positionProxyAdjacentToSiblings} \(proxy.familyMember.fullName) moved adjacent to siblings: \(proxy.position?.toString() ?? "nil")")
    }
    
    /// Attempts to resolve connection conflicts by:
    /// 1. Getting this proxy
    /// 2. Checking every other couple's position relative to them to see if they create a connection conflict
    /// 3. If they do, and swapping their positions resolves the conflict, swap them and return
    private func resolveConnectionConflictsBySwappingCouples(for proxy: FamilyMemberRenderProxy) {
        guard proxy.familyMember.isParent else {
            return
        }
        let otherProxies = self.getSameLevelProxies(as: proxy, includeProxy: false, includeProxySpouse: false)
        for otherProxy in otherProxies {
            guard self.connectionConflictCreatedBy(proxy, otherProxy) else {
                continue
            }
            // Now we know at this point - a connection conflict occurs
            guard let revert = self.swapCouplesPositionsIfPossible(proxy, otherProxy) else {
                // If revert isn't defined, the swap wasn't possible - continue
                continue
            }
            if self.connectionConflictCreatedBy(proxy, otherProxy) {
                // Conflict still exists - revert
                revert()
                continue
            } else {
                // Success - the two proxy couples created a conflict, swapping them removed the conflict without any position conflicts created
                print("[TRACE] {resolveConnectionConflictsBySwappingCouples} Swapped: \(proxy.familyMember.fullName) \(proxy.position?.toString() ?? "nil") and \(otherProxy.familyMember.fullName) \(otherProxy.position?.toString() ?? "nil")")
                return
            }
        }
    }
    
    private func resolveConnectionConflictsBySwappingSiblings(for proxy: FamilyMemberRenderProxy) {
        guard !proxy.familyMember.hasNoParents else {
            return
        }
        let siblingProxies = self.getSiblingProxies(for: proxy)
        guard !siblingProxies.isEmpty else {
            return
        }
        let parentProxy = self.getParentProxies(for: proxy).first!
        // First make sure parents are actually causing a conflict
        guard self.connectionConflictCreatedBy(parentProxy: parentProxy) else {
            return
        }
        for siblingProxy in siblingProxies {
            guard let revert = self.swapSiblingPositionsIfPossible(proxy, siblingProxy) else {
                // If revert isn't defined, the swap wasn't possible - continue
                continue
            }
            if self.connectionConflictCreatedBy(parentProxy: parentProxy) {
                // Conflict still exists - revert
                revert()
                continue
            } else {
                // Success - the two proxy siblings created a conflict, swapping them removed the conflict without any position conflicts created
                print("[TRACE] {resolveConnectionConflictsBySwappingSiblings} Swapped: \(proxy.familyMember.fullName) \(proxy.position?.toString() ?? "nil") and \(siblingProxy.familyMember.fullName) \(siblingProxy.position?.toString() ?? "nil")")
                return
            }
        }
    }
    
    private func connectionConflictCreatedBy(parentProxy: FamilyMemberRenderProxy) -> Bool {
        guard parentProxy.familyMember.isParent && parentProxy.hasPosition else {
            assertionFailure("Invalid proxy passed - expected a parent proxy with a position")
            return false
        }
        let otherParentsSameLevel = self.getSameLevelProxies(as: parentProxy, includeProxy: false, includeProxySpouse: false)
            .filter({ $0.familyMember.isParent })
        for otherParent in otherParentsSameLevel {
            if self.connectionConflictCreatedBy(parentProxy, otherParent) {
                return true
            }
        }
        return false
    }
    
    /// Checks if two parents create a connection conflict.
    /// - Parameters:
    ///   - parent1: A parent (if part of a couple, either is fine)
    ///   - parent2: Another parent (either single or from a DIFFERENT couple)
    /// - Returns: True if the parents from different families create a connection conflict
    private func connectionConflictCreatedBy(_ parent1: FamilyMemberRenderProxy, _ parent2: FamilyMemberRenderProxy) -> Bool {
        guard parent1.hasPosition, parent2.hasPosition else {
            assertionFailure("Checking if proxies create a connection conflict when they don't even have positions")
            return false
        }
        guard parent1.familyMember.isParent, parent2.familyMember.isParent else {
            return false
        }
        guard let parent1To2Direction = self.getTheDirection(from: parent1.position!, to: parent2.position!) else {
            assertionFailure("Both proxies share the same position")
            return false
        }
        let children1 = self.getDirectChildrenProxies(for: parent1)
        let children2 = self.getDirectChildrenProxies(for: parent2)
        switch parent1To2Direction {
        case .right:
            guard let children1FurthestRightX = children1.compactMap({ $0.position?.x }).max(),
                  let children2FurthestLeftX = children2.compactMap({ $0.position?.x }).min() else {
                // Children on both sides are required for a conflict
                return false
            }
            if children1FurthestRightX.isGreater(than: children2FurthestLeftX) {
                return true
            }
        case .left:
            guard let children1FurthestLeftX = children1.compactMap({ $0.position?.x }).min(),
                  let children2FurthestRightX = children2.compactMap({ $0.position?.x }).max() else {
                // Children on both sides are required for a conflict
                return false
            }
            if children1FurthestLeftX.isLess(than: children2FurthestRightX) {
                return true
            }
        }
        return false
    }
    
    /// Swaps two sibling's positions, if possible (including spouses).
    /// If successful, returns revert function.
    /// If unsuccessful, returns nil.
    private func swapSiblingPositionsIfPossible(
        _ sibling1Proxy: FamilyMemberRenderProxy,
        _ sibling2Proxy: FamilyMemberRenderProxy
    ) -> (() -> Void)? {
        return self.swapCouplesPositionsIfPossible(sibling1Proxy, sibling2Proxy)
    }
    
    /// Swaps two couple's positions, if possible.
    /// If successful, returns revert function.
    /// If unsuccessful, returns nil.
    private func swapCouplesPositionsIfPossible(
        _ couple1Proxy: FamilyMemberRenderProxy,
        _ couple2Proxy: FamilyMemberRenderProxy
    ) -> (() -> Void)? {
        let couple1Spouse = self.getSpouseProxy(for: couple1Proxy)
        let couple2Spouse = self.getSpouseProxy(for: couple2Proxy)
        // Check that each "couple" at least has one person, and that person has a position
        guard couple1Proxy.hasPosition || couple1Spouse?.hasPosition ?? false else {
            return nil
        }
        guard couple2Proxy.hasPosition || couple2Spouse?.hasPosition ?? false else {
            return nil
        }
        // Couples, by left/right preference
        let couple1Left = couple1Proxy.preferredDirection == .left ? couple1Proxy : couple1Spouse
        let couple1Right = couple1Proxy.preferredDirection == .right ? couple1Proxy : couple1Spouse
        let couple2Left = couple2Proxy.preferredDirection == .left ? couple2Proxy : couple2Spouse
        let couple2Right = couple2Proxy.preferredDirection == .right ? couple2Proxy : couple2Spouse
        // Original positions
        let couple1LeftStartPosition = couple1Left?.position?.clone()
        let couple1RightStartPosition = couple1Right?.position?.clone()
        let couple2LeftStartPosition = couple2Left?.position?.clone()
        let couple2RightStartPosition = couple2Right?.position?.clone()
        let revert = {
            couple1Left?.setPosition(to: couple1LeftStartPosition)
            couple1Right?.setPosition(to: couple1RightStartPosition)
            couple2Left?.setPosition(to: couple2LeftStartPosition)
            couple2Right?.setPosition(to: couple2RightStartPosition)
        }
        // First attempt to shuffle couples
        // This only works if they are adjacent to each other
        // It's good to try this first otherwise adjacent couples can run into position conflicts with the below algorithm
        // E.g. try the situation - [couple1Left] [couple1Right] [couple2Right] (Which you'd want to end with [couple2Right] [couple1Left] [couple1Right])
        let couplesAreAdjacent = self.checkProxiesAreAdjacent(
            [couple1Left, couple1Right, couple2Left, couple2Right].compactMap({ $0 }),
            spacing: Self.POSITION_PADDING
        )
        if couplesAreAdjacent {
            let couple1Count = [couple1Left, couple1Right].filter({ $0 != nil }).count
            let couple2Count = [couple2Left, couple2Right].filter({ $0 != nil }).count
            let couple1ShuffleDistance = Self.POSITION_PADDING*Double(couple2Count)
            let couple2ShuffleDistance = Self.POSITION_PADDING*Double(couple1Count)
            let couple1MovesRight = self.getTheDirection(
                from: couple1LeftStartPosition ?? couple1RightStartPosition!,
                to: couple2LeftStartPosition ?? couple2RightStartPosition!
            ) == .right
            let couple1DirectionSign: Double = couple1MovesRight ? 1 : -1
            let couple2DirectionSign: Double = couple1MovesRight ? -1 : 1
            couple1Left?.position?.translateX(couple1ShuffleDistance * couple1DirectionSign)
            couple1Right?.position?.translateX(couple1ShuffleDistance * couple1DirectionSign)
            couple2Left?.position?.translateX(couple2ShuffleDistance * couple2DirectionSign)
            couple2Right?.position?.translateX(couple2ShuffleDistance * couple2DirectionSign)
            return revert
        }
        // We can't shuffle them around because they're not adjacent - move each proxy
        if let couple1Left, couple1Left.hasPosition {
            if let couple2LeftStartPosition {
                couple1Left.setPosition(to: couple2LeftStartPosition)
            } else if let couple2RightStartPosition {
                if couple1Right == nil {
                    couple1Left.setPosition(to: couple2RightStartPosition)
                } else {
                    couple1Left.setPosition(to: couple2RightStartPosition - SMPoint(x: Self.POSITION_PADDING, y: 0))
                }
            } else {
                assertionFailure("Error in logic - at least couple2Left or couple2Right must have a position")
            }
        }
        if let couple1Right, couple1Right.hasPosition {
            if let couple2RightStartPosition {
                couple1Right.setPosition(to: couple2RightStartPosition)
            } else if let couple2LeftStartPosition {
                if couple1Left == nil {
                    couple1Right.setPosition(to: couple2LeftStartPosition)
                } else {
                    couple1Right.setPosition(to: couple2LeftStartPosition + SMPoint(x: Self.POSITION_PADDING, y: 0))
                }
            } else {
                assertionFailure("Error in logic - at least couple2Left or couple2Right must have a position")
            }
        }
        if let couple2Left, couple2Left.hasPosition {
            if let couple1LeftStartPosition {
                couple2Left.setPosition(to: couple1LeftStartPosition)
            } else if let couple1RightStartPosition {
                if couple2Right == nil {
                    couple2Left.setPosition(to: couple1RightStartPosition)
                } else {
                    couple2Left.setPosition(to: couple1RightStartPosition - SMPoint(x: Self.POSITION_PADDING, y: 0))
                }
            } else {
                assertionFailure("Error in logic - at least couple1Left or couple1Right must have a position")
            }
        }
        if let couple2Right, couple2Right.hasPosition {
            if let couple1RightStartPosition {
                couple2Right.setPosition(to: couple1RightStartPosition)
            } else if let couple1LeftStartPosition {
                if couple2Left == nil {
                    couple2Right.setPosition(to: couple1LeftStartPosition)
                } else {
                    couple2Right.setPosition(to: couple1LeftStartPosition + SMPoint(x: Self.POSITION_PADDING, y: 0))
                }
            } else {
                assertionFailure("Error in logic - at least couple1Left or couple1Right must have a position")
            }
        }
        // Check for any conflicts created
        // This must be done after moving all (potential) four proxies - otherwise they conflict with each other
        if let couple1Left, self.positionConflictExists(for: couple1Left) {
            revert()
            return nil
        }
        if let couple1Right, self.positionConflictExists(for: couple1Right) {
            revert()
            return nil
        }
        if let couple2Left, self.positionConflictExists(for: couple2Left) {
            revert()
            return nil
        }
        if let couple2Right, self.positionConflictExists(for: couple2Right) {
            revert()
            return nil
        }
        return revert
    }
    
    /// Attempts to resolve connection conflicts (When connections cross over one another).
    /// This occurs when some parents (on the same y level as the proxy's parents) are closer to the proxy than the proxy's parents are in that given direction.
    /// ``` A visual diagram:
    ///     [Proxy Parents] [Other Parents]
    ///           ╵---------------|------------------------┐
    ///                           ^ Conflict is here!   [Proxy]
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
            guard proxyBeingResolved.hasPosition else {
                continue
            }
            guard let anyParent = self.getParentProxies(for: proxyBeingResolved).first,
                  let anyParentPosition = anyParent.position else {
                continue
            }
            // Get all the other parents at the same y
            let otherParentsSameLevel = self.getSameLevelProxies(as: anyParent, includeProxy: false, includeProxySpouse: false)
                .filter({ $0.familyMember.isParent })
            // These "closest" values represent the boundary the proxy should remain in
            // If the proxy goes past it, a connection conflict occurs, because the
            // parents' connection crosses over the other parents' connections to reach the proxy
            let closestOtherParentToLeft: FamilyMemberRenderProxy? = otherParentsSameLevel
                .filter({ $0.position!.x.isLess(than: anyParentPosition.x) })
                .max(by: { $0.position!.x < $1.position!.x })
            let closestOtherParentToRight: FamilyMemberRenderProxy? = otherParentsSameLevel
                .filter({ $0.position!.x.isGreater(than: anyParentPosition.x) })
                .min(by: { $0.position!.x > $1.position!.x })
            if let closestOtherParentToRight,
               let closestOtherParentToRightX = closestOtherParentToRight.position?.x,
               let proxyBeingResolvedPosition = proxyBeingResolved.position,
               proxyBeingResolvedPosition.x.isGreater(than: closestOtherParentToRightX),
               self.connectionConflictCreatedBy(anyParent, closestOtherParentToRight) {
                // A connection conflict exists because the proxy is too far right
                self.resolveRenderConflicts(
                    conflictCondition: { proxy in
                        let positionConflictExists = self.positionConflictExists(for: proxy)
                        let connectionConflictExists = self.connectionConflictCreatedBy(anyParent, closestOtherParentToRight)
                        if !positionConflictExists && !connectionConflictExists {
                            return false
                        }
                        return (
                            positionConflictExists
                            || proxy.position!.x.isGreater(than: closestOtherParentToRightX)
                        )
                    },
                    direction: .left,
                    for: proxyBeingResolved
                )
                print("[TRACE] {resolveConnectionConflicts} \(proxy.familyMember.fullName) resolved connection conflicts by moving left: \(proxy.position?.toString() ?? "nil")")
            }
            if let closestOtherParentToLeft,
               let closestOtherParentToLeftX = closestOtherParentToLeft.position?.x,
               let proxyBeingResolvedPosition = proxyBeingResolved.position,
               proxyBeingResolvedPosition.x.isLess(than: closestOtherParentToLeftX),
               self.connectionConflictCreatedBy(anyParent, closestOtherParentToLeft) {
                // A connection conflict exists because the proxy is too far left
                self.resolveRenderConflicts(
                    conflictCondition: { proxy in
                        let positionConflictExists = self.positionConflictExists(for: proxy)
                        let connectionConflictExists = self.connectionConflictCreatedBy(anyParent, closestOtherParentToLeft)
                        if !positionConflictExists && !connectionConflictExists {
                            return false
                        }
                        return (
                            positionConflictExists
                            || proxy.position!.x.isLess(than: closestOtherParentToLeftX)
                        )
                    },
                    direction: .right,
                    for: proxyBeingResolved
                )
                print("[TRACE] {resolveConnectionConflicts} \(proxy.familyMember.fullName) resolved connection conflicts by moving right: \(proxy.position?.toString() ?? "nil")")
            }
            if let closestOtherParentToLeft,
               let closestOtherParentToRight,
               let closestOtherParentToLeftX = closestOtherParentToLeft.position?.x,
               let closestOtherParentToRightX = closestOtherParentToRight.position?.x,
               let proxyBeingResolvedPosition = proxyBeingResolved.position,
               (proxyBeingResolvedPosition.x.isGreater(than: closestOtherParentToRightX)
                || proxyBeingResolvedPosition.x.isLess(than: closestOtherParentToLeftX)),
               (self.connectionConflictCreatedBy(anyParent, closestOtherParentToRight)
                || self.connectionConflictCreatedBy(anyParent, closestOtherParentToLeft)
               ) {
                // If we reach here, it's really bad
                // It means there's no room for the child under the parents
                // BUT ALSO, moving the child left/right results in a connection conflict
                // There's only one thing left to do!
                // Make room.
                // 1. Place the proxy under any of the parents (move their spouse with them)
                self.anchorCouple(
                    to: anyParentPosition + SMPoint(x: 0, y: Self.POSITION_PADDING),
                    proxy: proxyBeingResolved,
                    anchor: proxyBeingResolved.preferredDirection
                )
                // 2. Position it to the first spot that isn't a sibling or a sibling's spouse
                let siblingProxies = self.getSiblingProxies(for: proxyBeingResolved)
                let siblingSpouseProxies = self.getSpouseProxies(for: siblingProxies)
                let siblingAndSiblingSpouseProxies = siblingProxies + siblingSpouseProxies
                self.resolveRenderConflicts(
                    conflictCondition: { proxy in
                        return self.positionConflictExistsBetween(proxy, and: siblingAndSiblingSpouseProxies)
                    },
                    direction: nil,
                    for: proxyBeingResolved
                )
                guard self.positionConflictExists(for: proxyBeingResolved) else {
                    // If at this stage there are no conflicts, then there's no problem
                    print("[TRACE] {resolveConnectionConflicts} \(proxy.familyMember.fullName) resolved connection conflicts by resetting position: \(proxy.position?.toString() ?? "nil")")
                    return
                }
                // 3. Resolve position render conflicts for everyone that isn't them or their spouse or their parents
                //    that is equal or further than their x position.
                //    But further... right or left?
                var directionOfEveryoneToMove: HorizontalDirection? = nil
                // Get the average parent position. Whatever direction they're in, move everyone else in the opposite direction.
                if let averageParentsPosition = self.getParentsPositionsAverage(for: proxyBeingResolved),
                   let proxyBeingResolvedPosition = proxyBeingResolved.position,
                   let directionParentsAreIn = self.getTheDirection(from: proxyBeingResolvedPosition, to: averageParentsPosition) {
                    directionOfEveryoneToMove = directionParentsAreIn.oppositeDirection
                } 
                // If the proxy has a single parent right above them, this doesn't work.
                // Next, we try another condition that must work given the first condition failed.
                // We get the proxy that matches its position, get the first "next" family member proxy from that conflicting proxy
                // that has a different y, and move everyone in that direction.
                else if let conflictingProxy = self.getFirstProxyConflictingWith(proxyBeingResolved),
                        let proxyBeingResolvedPosition = proxyBeingResolved.position {
                    let directFamilyMemberIDs = conflictingProxy.nextFamilyMembers.map({ $0.id })
                    for directID in directFamilyMemberIDs {
                        if let directFamilyMemberProxy = self.familyMemberProxiesStore[directID],
                           let directFamilyMemberProxyPosition = directFamilyMemberProxy.position,
                           let directionDirectFamilyMemberIsIn = self.getTheDirection(from: proxyBeingResolvedPosition, to: directFamilyMemberProxyPosition) {
                            directionOfEveryoneToMove = directionDirectFamilyMemberIsIn
                            break
                        }
                    }
                }
                guard let directionOfEveryoneToMove,
                      let proxyBeingResolvedPosition = proxyBeingResolved.position else {
                    assertionFailure("Should be impossible")
                    return
                }
                // Now we can finally collect everyone that isn't the proxy or their spouse or their parents
                // that is equal or further than their x position
                var proxiesToMove = [UUID: FamilyMemberRenderProxy]()
                for potentialProxy in self.familyMemberProxiesStore.values {
                    guard let potentialPosition = potentialProxy.position else {
                        continue
                    }
                    let direction = self.getTheDirection(from: proxyBeingResolvedPosition, to: potentialPosition)
                    if (direction == nil || direction == directionOfEveryoneToMove)
                        && !potentialProxy.familyMember.isPerson(proxyBeingResolved.familyMember)
                        && !potentialProxy.familyMember.isSpouse(to: proxyBeingResolved.familyMember)
                        && !potentialProxy.familyMember.isParent(of: proxyBeingResolved.familyMember) {
                        proxiesToMove[potentialProxy.id] = potentialProxy
                    }
                }
                // (Don't forget the proxies to move spouses)
                for spouseProxy in self.getSpouseProxies(for: Array(proxiesToMove.values)) {
                    proxiesToMove[spouseProxy.id] = spouseProxy
                }
                for proxyToMove in proxiesToMove.values {
                    proxyToMove.position?.translate(by: SMPoint(x: Self.POSITION_PADDING*directionOfEveryoneToMove.directionMultiplier, y: 0))
                }
                print("[TRACE] {resolveConnectionConflicts} \(proxy.familyMember.fullName) resolved connection conflicts by moving everyone else: \(proxy.position?.toString() ?? "nil")")
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
        gap: Double = FamilyRenderProxy.POSITION_PADDING
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
        offsetIncrement: Double = FamilyRenderProxy.POSITION_PADDING,
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
            let xTranslation = abs(offsetIncrement)*direction.directionMultiplier
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
    
    /// Checks if a proxy shares its position with any of the other provided proxies.
    /// - Parameters:
    ///   - proxy: The proxy to check if it has any position conflicts
    ///   - otherProxies: The proxies to check against
    /// - Returns: True if the provided proxy shares its position with any of the other provided proxies
    private func positionConflictExistsBetween(_ proxy: FamilyMemberRenderProxy, and otherProxies: [FamilyMemberRenderProxy]) -> Bool {
        guard proxy.hasPosition else {
            assertionFailure("Checking if proxy with no position shares its (non-existent) position with any other proxies")
            return false
        }
        for otherProxy in otherProxies {
            if proxy.position == otherProxy.position && proxy.id != otherProxy.id {
                return true
            }
        }
        return false
    }
    
    private func getFirstProxyConflictingWith(_ proxy: FamilyMemberRenderProxy) -> FamilyMemberRenderProxy? {
        guard proxy.hasPosition else {
            assertionFailure("Checking if proxy with no position shares its (non-existent) position with any other proxies")
            return nil
        }
        for otherProxy in self.orderedFamilyMemberProxies {
            if proxy.position == otherProxy.position && proxy.id != otherProxy.id {
                return otherProxy
            }
        }
        return nil
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
                self.coupleConnections.append(CoupleConnectionRenderProxy(
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
                self.childConnections.append(ChildConnectionRenderProxy(
                    parentsConnection: coupleConnection,
                    child: childProxy
                ))
            }
        }
    }
    
}
