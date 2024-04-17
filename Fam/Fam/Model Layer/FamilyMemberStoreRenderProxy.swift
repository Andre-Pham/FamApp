//
//  FamilyMemberStoreRenderProxy.swift
//  Fam
//
//  Created by Andre Pham on 18/4/2024.
//

import Foundation
import SwiftMath

class FamilyMemberStoreRenderProxy {
    
    public static let POSITION_PADDING = 150.0
    
    private(set) var orderedFamilyMemberProxies = [FamilyMemberRenderProxy]()
    private(set) var connections = [SMLine]()
    
    init(_ family: FamilyMemberStore, root: FamilyMember) {
        assert(family.contains(familyMember: root), "Family doesn't contain family member")
        self.generateOrderedFamilyMembers(family: family, root: root)
        self.generatePositions()
    }
    
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
                guard var position = previous.position else {
                    continue
                }
                if proxy.familyMember.isSpouse(to: previous.familyMember) {
                    switch proxy.familyMember.sex {
                    case .male:
                        position -= SMPoint(x: Self.POSITION_PADDING, y: 0.0)
                        proxy.setPosition(to: position)
                        self.resolveRenderConflictsMovingLeft(for: proxy, offsetIncrement: Self.POSITION_PADDING)
                    case .female:
                        position += SMPoint(x: Self.POSITION_PADDING, y: 0.0)
                        proxy.setPosition(to: position)
                        self.resolveRenderConflictsMovingRight(for: proxy, offsetIncrement: Self.POSITION_PADDING)
                    }
                    break
                } else if proxy.familyMember.isExSpouse(to: previous.familyMember) {
                    switch previous.familyMember.sex {
                    case .male:
                        position -= SMPoint(x: Self.POSITION_PADDING, y: 0.0)
                        proxy.setPosition(to: position)
                        self.resolveRenderConflictsMovingLeft(for: proxy, offsetIncrement: Self.POSITION_PADDING)
                    case .female:
                        position += SMPoint(x: Self.POSITION_PADDING, y: 0.0)
                        proxy.setPosition(to: position)
                        self.resolveRenderConflictsMovingRight(for: proxy, offsetIncrement: Self.POSITION_PADDING)
                    }
                    break
                } else if proxy.familyMember.isParent(of: previous.familyMember) {
                    position -= SMPoint(x: 0.0, y: Self.POSITION_PADDING)
                    proxy.setPosition(to: position)
                    self.resolveRenderConflicts(for: proxy, offsetIncrement: Self.POSITION_PADDING)
                    break
                } else if proxy.familyMember.isChild(of: previous.familyMember) {
                    position += SMPoint(x: 0.0, y: Self.POSITION_PADDING)
                    proxy.setPosition(to: position)
                    self.resolveRenderConflicts(for: proxy, offsetIncrement: Self.POSITION_PADDING)
                    break
                }
            }
        }
    }
    
    private func resolveRenderConflicts(for proxy: FamilyMemberRenderProxy, offsetIncrement: Double) {
        guard proxy.position != nil else {
            assertionFailure("Attempting to resolve conflicts for a position that isn't set")
            return
        }
        guard self.positionConflictExists(for: proxy) else {
            return
        }
        var offset = 0.0
        while true {
            offset += offsetIncrement
            let leftPoint = proxy.position! + SMPoint(x: -offset, y: 0.0)
            let leftConflict = self.positionConflictExists(for: leftPoint)
            let rightPoint = proxy.position! + SMPoint(x: offset, y: 0.0)
            let rightConflict = self.positionConflictExists(for: rightPoint)
            if leftConflict && rightConflict {
                continue
            } else if rightConflict {
                // No left conflict
                proxy.setPosition(to: leftPoint)
                return
            } else {
                // No right conflict
                proxy.setPosition(to: rightPoint)
                return
            }
        }
    }
    
    private func resolveRenderConflictsMovingRight(for proxy: FamilyMemberRenderProxy, offsetIncrement: Double) {
        guard proxy.position != nil else {
            assertionFailure("Attempting to resolve conflicts for a position that isn't set")
            return
        }
        guard self.positionConflictExists(for: proxy) else {
            return
        }
        var offset = 0.0
        while true {
            offset += offsetIncrement
            let rightPoint = proxy.position! + SMPoint(x: offset, y: 0.0)
            let rightConflict = self.positionConflictExists(for: rightPoint)
            if rightConflict {
                continue
            } else {
                proxy.setPosition(to: rightPoint)
                return
            }
        }
    }
    
    private func resolveRenderConflictsMovingLeft(for proxy: FamilyMemberRenderProxy, offsetIncrement: Double) {
        guard proxy.position != nil else {
            assertionFailure("Attempting to resolve conflicts for a position that isn't set")
            return
        }
        guard self.positionConflictExists(for: proxy) else {
            return
        }
        var offset = 0.0
        while true {
            offset += offsetIncrement
            let leftPoint = proxy.position! + SMPoint(x: -offset, y: 0.0)
            let leftConflict = self.positionConflictExists(for: leftPoint)
            if leftConflict {
                continue
            } else {
                proxy.setPosition(to: leftPoint)
                return
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
    
}
