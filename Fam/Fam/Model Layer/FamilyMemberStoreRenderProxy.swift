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
//        self.bringCouplesCloser(by: 50)
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
        print(self.orderedFamilyMemberProxies.map({ $0.familyMember.firstName }))
    }
    
    /// Populates the "id to family member" dictionary based on the ordered family members.
    private func generateFamilyMemberStore() {
        for proxy in self.orderedFamilyMemberProxies {
            self.familyMemberProxiesStore[proxy.id] = proxy
        }
    }
    
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
            
            // NOTE:
            // Men go to the LEFT
            // Women go to the RIGHT
            // This needs to be consistent for the rendering to calculate correctly
            
            for previousIndex in stride(from: index - 1, through: 0, by: -1) {
                let previous = self.orderedFamilyMemberProxies[previousIndex]
                guard var position = previous.position?.clone() else {
                    continue
                }
                if proxy.familyMember.isSpouse(to: previous.familyMember) {
                    switch proxy.familyMember.sex {
                    case .male:
                        position -= SMPoint(x: Self.POSITION_PADDING, y: 0.0)
                        proxy.setPosition(to: position)
                        self.resolveRenderConflicts(direction: .left, for: proxy, offsetIncrement: Self.POSITION_PADDING)
                    case .female:
                        position += SMPoint(x: Self.POSITION_PADDING, y: 0.0)
                        proxy.setPosition(to: position)
                        self.resolveRenderConflicts(direction: .right, for: proxy, offsetIncrement: Self.POSITION_PADDING)
                    }
                } else if proxy.familyMember.isExSpouse(to: previous.familyMember) {
                    switch previous.familyMember.sex {
                    case .male:
                        position -= SMPoint(x: Self.POSITION_PADDING, y: 0.0)
                        proxy.setPosition(to: position)
                        self.resolveRenderConflicts(direction: .left, for: proxy, offsetIncrement: Self.POSITION_PADDING)
                    case .female:
                        position += SMPoint(x: Self.POSITION_PADDING, y: 0.0)
                        proxy.setPosition(to: position)
                        self.resolveRenderConflicts(direction: .right, for: proxy, offsetIncrement: Self.POSITION_PADDING)
                    }
                } else if proxy.familyMember.isParent(of: previous.familyMember) {
                    position -= SMPoint(x: 0.0, y: Self.POSITION_PADDING)
                    proxy.setPosition(to: position)
                    self.resolveRenderConflictsAnyDirection(for: proxy, offsetIncrement: Self.POSITION_PADDING)
                } else if proxy.familyMember.isChild(of: previous.familyMember) {
                    position += SMPoint(x: 0.0, y: Self.POSITION_PADDING)
                    proxy.setPosition(to: position)
                    self.resolveRenderConflictsAnyDirection(for: proxy, offsetIncrement: Self.POSITION_PADDING)
                }
                guard let setPosition = proxy.position else {
                    continue
                }
                
                // Enforce rule:
                // If you're a mother, both your parents HAVE to be past your right side
                // (AKA if you have a daughter, and your daughter has kids, you must be to the right side of your daughter)
                // If you're a father, both your parents HAVE to be past your left side
                // (AKA if you have a son, and your son has kids, you must be to the left of your son)
                // Case 1: Proxy is the parent (that needs to move)
                let daughtersWithChildren = proxy.familyMember.daughtersWithChildren
                if !daughtersWithChildren.isEmpty {
                    let daughterProxies = daughtersWithChildren.map({ self.familyMemberProxiesStore[$0.id] })
                    let positions = daughterProxies.compactMap({ $0?.position })
                    if let farthestRight = SMPointCollection(points: positions).maxX,
                       farthestRight.isGreater(than: setPosition.x) {
                        self.anchorCouple(
                            to: SMPoint(x: farthestRight + Self.POSITION_PADDING, y: setPosition.y),
                            memberProxy: proxy,
                            anchor: .left,
                            gap: Self.POSITION_PADDING
                        )
                        self.resolveRenderConflicts(direction: .right, for: proxy, offsetIncrement: Self.POSITION_PADDING)
                    }
                }
                let sonsWithChildren = proxy.familyMember.sonsWithChildren
                if !sonsWithChildren.isEmpty {
                    let sonProxies = sonsWithChildren.map({ self.familyMemberProxiesStore[$0.id] })
                    let positions = sonProxies.compactMap({ $0?.position })
                    if let farthestLeft = SMPointCollection(points: positions).minX,
                       farthestLeft.isLess(than: setPosition.x) {
                        self.anchorCouple(
                            to: SMPoint(x: farthestLeft - Self.POSITION_PADDING, y: setPosition.y),
                            memberProxy: proxy,
                            anchor: .right,
                            gap: Self.POSITION_PADDING
                        )
                        self.resolveRenderConflicts(direction: .left, for: proxy, offsetIncrement: Self.POSITION_PADDING)
                    }
                }
                // Case 2: Proxy is the child (that needs to move)
                if proxy.familyMember.isParent {
                    var motherX: Double? = nil
                    var fatherX: Double? = nil
                    if let motherID = proxy.familyMember.motherID,
                       let motherProxy = self.familyMemberProxiesStore[motherID],
                       let motherPosition = motherProxy.position {
                        motherX = motherPosition.x
                    }
                    if let fatherID = proxy.familyMember.fatherID,
                       let fatherProxy = self.familyMemberProxiesStore[fatherID],
                       let fatherPosition = fatherProxy.position {
                        fatherX = fatherPosition.x
                    }
                    if motherX != nil || fatherX != nil {
                        switch proxy.familyMember.sex {
                        case .male:
                            // Male - must be to right of parents
                            let farthestRight = max(motherX ?? fatherX!, fatherX ?? motherX!)
                            if farthestRight.isGreater(than: setPosition.x) {
                                self.anchorCouple(
                                    to: SMPoint(x: farthestRight + Self.POSITION_PADDING, y: setPosition.y),
                                    memberProxy: proxy,
                                    anchor: .left,
                                    gap: Self.POSITION_PADDING
                                )
                                self.resolveRenderConflicts(direction: .right, for: proxy, offsetIncrement: Self.POSITION_PADDING)
                            }
                        case .female:
                            // Female - must be to left of parents
                            let farthestLeft = min(motherX ?? fatherX!, fatherX ?? motherX!)
                            if farthestLeft.isLess(than: setPosition.x) {
                                self.anchorCouple(
                                    to: SMPoint(x: farthestLeft - Self.POSITION_PADDING, y: setPosition.y),
                                    memberProxy: proxy,
                                    anchor: .right,
                                    gap: Self.POSITION_PADDING
                                )
                                self.resolveRenderConflicts(direction: .left, for: proxy, offsetIncrement: Self.POSITION_PADDING)
                            }
                        }
                    }
                }
                
                // Enforce rule:
                // If you have placed siblings, you must be placed adjacent to them or their spouses
                let siblings = proxy.familyMember.siblings
                if !siblings.isEmpty {
                    let siblingProxies = siblings.compactMap({ self.familyMemberProxiesStore[$0.id] })
                    let siblingSpouseProxies = siblings.compactMap({
                        if let spouseID = $0.spouseID {
                            return self.familyMemberProxiesStore[spouseID]
                        }
                        return nil
                    })
                    let siblingPositions = siblingProxies.compactMap({ $0.position })
                    let siblingSpousePositions = siblingSpouseProxies.compactMap({ $0.position })
                    if !siblingPositions.isEmpty {
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
                            for: proxy,
                            offsetIncrement: Self.POSITION_PADDING
                        )
                        // After moving the sibling adjacent to their siblings, ensure render conflicts are resolved
                        self.resolveRenderConflicts(direction: direction, for: proxy, offsetIncrement: Self.POSITION_PADDING)
                    }
                }
                
                // Resolve any connection conflicts that occurred
                // (When connections cross over one another)
                for proxy in self.familyMemberProxiesStore.values where proxy.position != nil {
                    let anyParentPosition = proxy.familyMember.parentIDs
                        .compactMap({ self.familyMemberProxiesStore[$0] })
                        .compactMap({ $0.position }).first
                    if let anyParentPosition {
                        // Get all the people who are parents at the same y
                        let otherParentsXPositionsSameY = self.familyMemberProxiesStore.values
                            .filter({ $0.position?.y == anyParentPosition.y && $0.familyMember.isParent && !$0.familyMember.isParent(of: proxy.familyMember) })
                            .map({ $0.position!.x })
                        let parentsX = anyParentPosition.x
                        // These "closest" values represent the boundary the proxy should remain in
                        // If the proxy goes past it, a connection conflict occurs, because the
                        // parents' connection crosses over the other parents' connections to reach the proxy
                        let closestOtherParentsToLeft: Double? = otherParentsXPositionsSameY
                            .filter({ $0.isLess(than: parentsX) })
                            .max()
                        let closestOtherParentsToRight: Double? = otherParentsXPositionsSameY
                            .filter({ $0.isGreater(than: parentsX) })
                            .min()
                        // If true, proxy further right than the parents closest to the right of proxy's parents
                        let connectionConflictExistsRight = closestOtherParentsToRight != nil && proxy.position!.x.isGreater(than: closestOtherParentsToRight!)
                        if connectionConflictExistsRight {
                            print("\(proxy.familyMember.firstName) has a conflict to the right")
                            self.resolveRenderConflicts(
                                conflictCondition: { proxy in
                                    return self.positionConflictExists(for: proxy) || proxy.position!.x.isGreater(than: closestOtherParentsToRight!)
                                },
                                direction: .left,
                                for: proxy,
                                offsetIncrement: Self.POSITION_PADDING
                            )
                        }
                        // If true, proxy further right than the parents closest to the right of proxy's parents
                        let connectionConflictExistsLeft = closestOtherParentsToLeft != nil && proxy.position!.x.isLess(than: closestOtherParentsToLeft!)
                        if connectionConflictExistsLeft {
                            print("\(proxy.familyMember.firstName) has a conflict to the left")
                            print("closest other parents to the left: \(closestOtherParentsToLeft!)")
                            print("proxy position: \(proxy.position!.x)")
                            print(self.familyMemberProxiesStore.values.filter({ $0.position?.y == anyParentPosition.y && $0.familyMember.isParent }).map({ $0.familyMember.firstName }))
                            self.resolveRenderConflicts(
                                conflictCondition: { proxy in
                                    return self.positionConflictExists(for: proxy) || proxy.position!.x.isLess(than: closestOtherParentsToLeft!)
                                },
                                direction: .right,
                                for: proxy,
                                offsetIncrement: Self.POSITION_PADDING
                            )
                        }
                    }
                }
                
                assert(proxy.position != nil)
                break
            }
        }
    }
    
    private func bringCouplesCloser(by distance: Double) {
        for coupleConnection in self.coupleConnections {
            if let malePosition = coupleConnection.malePartner.position,
               let femalePosition = coupleConnection.femalePartner.position {
                coupleConnection.malePartner.setPosition(to: malePosition + SMPoint(x: distance/2.0, y: 0))
                coupleConnection.femalePartner.setPosition(to: femalePosition - SMPoint(x: distance/2.0, y: 0))
            }
        }
    }
    
    private func anchorCouple(to position: SMPoint, memberProxy: FamilyMemberRenderProxy, anchor: HorizontalDirection, gap: Double) {
        if let spouseID = memberProxy.familyMember.spouseID,
           let spouseProxy = self.familyMemberProxiesStore[spouseID],
           spouseProxy.position != nil {
            switch anchor {
            case .right:
                let wife = memberProxy.familyMember.sex == .female ? memberProxy : spouseProxy
                let other = memberProxy.familyMember.sex == .female ? spouseProxy : memberProxy
                wife.setPosition(to: position)
                other.setPosition(to: position - SMPoint(x: gap, y: 0))
            case .left:
                let husband = memberProxy.familyMember.sex == .male ? memberProxy : spouseProxy
                let other = memberProxy.familyMember.sex == .male ? spouseProxy : memberProxy
                husband.setPosition(to: position)
                other.setPosition(to: position + SMPoint(x: gap, y: 0))
            }
        } else {
            memberProxy.setPosition(to: position)
        }
    }
    
    private func resolveRenderConflicts(
        conflictCondition: (_ proxy: FamilyMemberRenderProxy) -> Bool,
        direction: HorizontalDirection,
        for proxy: FamilyMemberRenderProxy,
        offsetIncrement: Double,
        groupSpouse: Bool = true
    ) {
        var proxiesToMove = [proxy]
        if let spouseID = proxy.familyMember.spouseID,
           let spouseProxy = self.familyMemberProxiesStore[spouseID],
           groupSpouse {
            proxiesToMove.append(spouseProxy)
            assert(proxy.position != spouseProxy.position || proxy.position == nil, "Duplicate positions are illegal")
        }
        self.resolveGroupRenderConflicts(conflictCondition: conflictCondition, direction: direction, for: proxiesToMove, offsetIncrement: offsetIncrement)
    }
    
    private func resolveGroupRenderConflicts(
        conflictCondition: (_ proxy: FamilyMemberRenderProxy) -> Bool,
        direction: HorizontalDirection,
        for proxies: [FamilyMemberRenderProxy],
        offsetIncrement: Double
    ) {
        let xTranslation = switch direction {
        case .right:
            abs(offsetIncrement)
        case .left:
            -1.0 * abs(offsetIncrement)
        }
        let movableProxies = proxies.filter({ $0.position != nil })
        guard !movableProxies.isEmpty else {
            return
        }
        while movableProxies.contains(where: { conflictCondition($0) }) {
            for proxy in movableProxies {
                proxy.position!.translate(by: SMPoint(x: xTranslation, y: 0))
            }
        }
    }
    
    private func resolveRenderConflictsAnyDirection(
        conflictCondition: (_ proxy: FamilyMemberRenderProxy) -> Bool,
        for proxy: FamilyMemberRenderProxy,
        offsetIncrement: Double,
        groupSpouse: Bool = true
    ) {
        var proxiesToMove = [proxy]
        if let spouseID = proxy.familyMember.spouseID,
           let spouseProxy = self.familyMemberProxiesStore[spouseID],
           groupSpouse {
            proxiesToMove.append(spouseProxy)
            assert(proxy.position != spouseProxy.position || proxy.position == nil, "Duplicate positions are illegal")
        }
        self.resolveGroupRenderConflictsAnyDirection(conflictCondition: conflictCondition, for: proxiesToMove, offsetIncrement: offsetIncrement)
    }
    
    private func resolveGroupRenderConflictsAnyDirection(
        conflictCondition: (_ proxy: FamilyMemberRenderProxy) -> Bool,
        for proxies: [FamilyMemberRenderProxy],
        offsetIncrement: Double
    ) {
        let movableProxies = proxies.filter({ $0.position != nil })
        guard !movableProxies.isEmpty else {
            return
        }
        let startingPositions = movableProxies.map { $0.position! }
        var sign = 1
        var xTranslation = abs(offsetIncrement)
        while movableProxies.contains(where: { conflictCondition($0) }) {
            for proxyIndex in movableProxies.indices {
                let proxy = movableProxies[proxyIndex]
                let startingPosition = startingPositions[proxyIndex]
                proxy.setPosition(to: SMPoint(x: startingPosition.x + Double(sign)*xTranslation, y: startingPosition.y))
            }
            sign *= -1
            if sign == 1 {
                xTranslation += abs(offsetIncrement)
            }
        }
    }
    
    private func resolveRenderConflictsAnyDirection(for proxy: FamilyMemberRenderProxy, offsetIncrement: Double, groupSpouse: Bool = true) {
        var proxiesToMove = [proxy]
        if let spouseID = proxy.familyMember.spouseID,
           let spouseProxy = self.familyMemberProxiesStore[spouseID],
           groupSpouse {
            proxiesToMove.append(spouseProxy)
            assert(proxy.position != spouseProxy.position || proxy.position == nil, "Duplicate positions are illegal")
        }
        self.resolveGroupRenderConflictsAnyDirection(for: proxiesToMove, offsetIncrement: offsetIncrement)
    }
    
    private func resolveGroupRenderConflictsAnyDirection(for proxies: [FamilyMemberRenderProxy], offsetIncrement: Double) {
        let movableProxies = proxies.filter({ $0.position != nil })
        guard !movableProxies.isEmpty else {
            return
        }
        let startingPositions = movableProxies.map { $0.position! }
        var sign = 1
        var xTranslation = abs(offsetIncrement)
        while movableProxies.contains(where: { self.positionConflictExists(for: $0) }) {
            for proxyIndex in movableProxies.indices {
                let proxy = movableProxies[proxyIndex]
                let startingPosition = startingPositions[proxyIndex]
                proxy.setPosition(to: SMPoint(x: startingPosition.x + Double(sign)*xTranslation, y: startingPosition.y))
            }
            sign *= -1
            if sign == 1 {
                xTranslation += abs(offsetIncrement)
            }
        }
    }
    
    private func resolveRenderConflicts(direction: HorizontalDirection, for proxy: FamilyMemberRenderProxy, offsetIncrement: Double, groupSpouse: Bool = true) {
        var proxiesToMove = [proxy]
        if let spouseID = proxy.familyMember.spouseID,
           let spouseProxy = self.familyMemberProxiesStore[spouseID],
           groupSpouse {
            proxiesToMove.append(spouseProxy)
            assert(proxy.position != spouseProxy.position || proxy.position == nil, "Duplicate positions are illegal")
        }
        self.resolveGroupRenderConflicts(direction: direction, for: proxiesToMove, offsetIncrement: offsetIncrement)
    }
    
    private func resolveGroupRenderConflicts(direction: HorizontalDirection, for proxies: [FamilyMemberRenderProxy], offsetIncrement: Double) {
        let xTranslation = switch direction {
        case .right:
            abs(offsetIncrement)
        case .left:
            -1.0 * abs(offsetIncrement)
        }
        let movableProxies = proxies.filter({ $0.position != nil })
        guard !movableProxies.isEmpty else {
            return
        }
        while movableProxies.contains(where: { self.positionConflictExists(for: $0) }) {
            for proxy in movableProxies {
                proxy.position!.translate(by: SMPoint(x: xTranslation, y: 0))
            }
        }
    }
    
    private func positionConflictExists(for proxy: FamilyMemberRenderProxy) -> Bool {
        for otherProxy in self.orderedFamilyMemberProxies {
            if proxy.position == otherProxy.position && proxy.id != otherProxy.id {
                return true
            }
        }
        return false
    }
    
    private func positionConflictExists(for position: SMPoint) -> Bool {
        for proxy in self.orderedFamilyMemberProxies {
            if proxy.position == position {
                return true
            }
        }
        return false
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
            let childrenIDs = coupleConnection.malePartner.familyMember.childrenIDs
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
