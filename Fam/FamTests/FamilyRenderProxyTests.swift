//
//  FamilyRenderProxyTests.swift
//  FamTests
//
//  Created by Andre Pham on 12/10/2024.
//

import XCTest
@testable import Fam

final class FamilyRenderProxyTests: XCTestCase {

    // Test a family tree that should have no conflicts doesn't render any conflicts
    func testNoUnexpectedConflicts() throws {
        let family = MockFamilies.standard
        let root = family.getAllFamilyMembers().first(where: { $0.firstName == "Andre" })!
        let render = FamilyRenderProxy(family, root: root, stopAtStep: nil)
        XCTAssertEqual(render.countPositionConflicts(), 0, "Found unexpected position conflicts in family tree render, expected 0")
        XCTAssertEqual(render.countConnectionConflicts(), 0, "Found unexpected connection conflicts in family tree render, expected 0")
    }
    
    // Test for every additional member in the family tree, there should be no render conflicts
    func testNoUnexpectedConflictsEveryStep() throws {
        let family = MockFamilies.standard
        let root = family.getAllFamilyMembers().first(where: { $0.firstName == "Andre" })!
        for step in 1...family.familyMembersCount {
            let render = FamilyRenderProxy(family, root: root, stopAtStep: step)
            XCTAssertEqual(render.countPositionConflicts(), 0, "Found unexpected position conflicts in family tree render at step \(step), expected 0")
            XCTAssertEqual(render.countConnectionConflicts(), 0, "Found unexpected connection conflicts in family tree render at step \(step), expected 0")
        }
    }
    
    // Test a family tree that is guaranteed to have one connection conflict (logically inevitable) doesn't cause additional conflicts to occur
    func testNoAdditionalConflicts() throws {
        let family = MockFamilies.standardWithConflict
        let root = family.getAllFamilyMembers().first(where: { $0.firstName == "Andre" })!
        let render = FamilyRenderProxy(family, root: root, stopAtStep: nil)
        XCTAssertEqual(render.countPositionConflicts(), 0, "Found unexpected position conflicts in family tree render, expected 0")
        XCTAssertEqual(render.countConnectionConflicts(), 1, "Found unexpected connection conflicts in family tree render, expected 1")
    }
    
    // Test all family members are given a position - none are left out
    func testAllFamilyMembersPositioned() throws {
        let family = MockFamilies.standard
        let root = family.getAllFamilyMembers().first(where: { $0.firstName == "Andre" })!
        let render = FamilyRenderProxy(family, root: root, stopAtStep: nil)
        let hasPositions = render.orderedFamilyMemberProxies.map({ $0.hasPosition })
        XCTAssertEqual(family.getAllFamilyMembers().count, hasPositions.count, "One or more family members weren't included in the render at all")
        XCTAssert(hasPositions.allSatisfy({ $0 }), "One or more family members weren't rendered with a position")
    }
    
    // Test that between renders, the family tree is rendered in exactly the same way every time (shouldn't change between renders)
    func testConsistentPositions() throws {
        let referenceFamily = MockFamilies.standard
        let referenceRoot = referenceFamily.getAllFamilyMembers().first(where: { $0.firstName == "Andre" })!
        let referenceRender = FamilyRenderProxy(referenceFamily, root: referenceRoot, stopAtStep: nil)
        let referencePositions = referenceRender.orderedFamilyMemberProxies.compactMap({ $0.position?.clone() })
        let referenceNames = referenceRender.orderedFamilyMemberProxies.compactMap({ $0.familyMember.fullName })
        // Render 25 times, make sure all 25 times match the original render
        for _ in 0..<25 {
            let family = MockFamilies.standard
            XCTAssertNotEqual(family.id, referenceFamily.id, "Comparing family to itself, should be comparing different families")
            let root = family.getAllFamilyMembers().first(where: { $0.firstName == "Andre" })!
            let render = FamilyRenderProxy(family, root: root, stopAtStep: nil)
            let positions = render.orderedFamilyMemberProxies.compactMap({ $0.position?.clone() })
            let names = render.orderedFamilyMemberProxies.compactMap({ $0.familyMember.fullName })
            XCTAssertEqual(positions, referencePositions, "Unexpected differences in positions between renders, expected identical")
            XCTAssertEqual(names, referenceNames, "Unexpected different family member ordering between renders, expected identical")
        }
    }
    
    // Test all spouses were positioned adjacent (next) to each other, and towards their "preferred direction"
    func testSpousesPositionedAdjacent() throws {
        let family = MockFamilies.standardWithConflict
        let root = family.getAllFamilyMembers().first(where: { $0.firstName == "Andre" })!
        let render = FamilyRenderProxy(family, root: root, stopAtStep: nil)
        let proxies = render.orderedFamilyMemberProxies
        for proxy in proxies {
            guard let spouseProxy = render.getSpouseProxy(for: proxy) else {
                continue
            }
            XCTAssertNotEqual(proxy.preferredDirection, spouseProxy.preferredDirection, "Spouse proxies should have opposite preferred directions")
            XCTAssert(proxy.hasPosition, "All rendered proxies must have a position")
            XCTAssert(spouseProxy.hasPosition, "All rendered proxies must have a position")
            XCTAssert(proxy.position!.y.isEqual(to: spouseProxy.position!.y), "Spouse proxies should be at the same level")
            XCTAssert(render.checkProxiesAreAdjacent([proxy, spouseProxy], spacing: FamilyRenderProxy.COUPLES_PADDING), "Spouse proxies must be adjacent")
            switch proxy.preferredDirection {
            case .right:
                XCTAssertEqual(proxy.position!.x - FamilyRenderProxy.COUPLES_PADDING, spouseProxy.position!.x, "Right preferring partner must to the right")
            case .left:
                XCTAssertEqual(proxy.position!.x + FamilyRenderProxy.COUPLES_PADDING, spouseProxy.position!.x, "Left preferring partner must to the left")
            }
        }
    }
    
    // Test all siblings are placed at the same level (y)
    func testSiblingsPositionedSameLevel() throws {
        let family = MockFamilies.standard
        let root = family.getAllFamilyMembers().first(where: { $0.firstName == "Andre" })!
        let render = FamilyRenderProxy(family, root: root, stopAtStep: nil)
        let proxies = render.orderedFamilyMemberProxies
        for proxy in proxies {
            let siblings = render.getSiblingProxies(for: proxy)
            let siblingsIsSameLevel = siblings.map({ $0.position!.y.isEqual(to: proxy.position!.y) })
            XCTAssert(siblingsIsSameLevel.allSatisfy({ $0 }), "Not all siblings were positioned at the same level")
        }
    }
    
    // Test all parents are placed the level above their children
    func testParentsPositionedLevelAboveChildren() throws {
        let family = MockFamilies.standard
        let root = family.getAllFamilyMembers().first(where: { $0.firstName == "Andre" })!
        let render = FamilyRenderProxy(family, root: root, stopAtStep: nil)
        let proxies = render.orderedFamilyMemberProxies
        for parent in proxies where parent.familyMember.isParent {
            let children = render.getDirectChildrenProxies(for: parent)
            let childrenIsLevelBelow = children.map({ ($0.position!.y - FamilyRenderProxy.POSITION_PADDING).isEqual(to: parent.position!.y) })
            XCTAssert(childrenIsLevelBelow.allSatisfy({ $0 }), "Not all parents were positioned above their children")
        }
    }

}
