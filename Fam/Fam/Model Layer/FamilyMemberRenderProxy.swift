//
//  FamilyMemberRenderProxy.swift
//  Fam
//
//  Created by Andre Pham on 18/4/2024.
//

import Foundation
import SwiftMath

class FamilyMemberRenderProxy {
    
    public let familyMember: FamilyMember
    private(set) var position: SMPoint? = nil
    private(set) var preferredDirection: HorizontalDirection
    public var id: UUID {
        return self.familyMember.id
    }
    public var hasPosition: Bool {
        return self.position != nil
    }
    public var nextFamilyMembers: [FamilyMember] {
        var next = [FamilyMember]()
        if let spouse = self.familyMember.spouse {
            next.append(spouse)
        }
        next.append(contentsOf: self.familyMember.exSpouses)
        let parents = self.familyMember.parents.sorted(by: {
            // Sort by id, then by sex (sex takes precedence over id)
            if $0.sex == $1.sex {
                return $0.id < $1.id
            } else {
                return $0.sex == self.familyMember.sex.oppositeSex && $1.sex == self.familyMember.sex
            }
        })
        for parent in parents {
            next.append(parent)
            if let parentSpouse = parent.spouse, !self.familyMember.parentIDs.contains(parentSpouse.id) {
                next.append(parentSpouse)
            }
        }
        for child in self.familyMember.children {
            next.append(child)
            if let childInLaw = child.spouse {
                next.append(childInLaw)
            }
        }
        return next
    }
    
    init(_ familyMember: FamilyMember) {
        self.familyMember = familyMember
        // By default, males render left and females render right
        // For same sex couples, left goes to the one who sorts first
        if let spouse = familyMember.spouse, spouse.sex == familyMember.sex {
            let couple = [familyMember, spouse].sorted(by: { $0.consistentSortingID < $1.consistentSortingID })
            self.preferredDirection = couple.first!.isPerson(familyMember) ? .left : .right
        } else {
            self.preferredDirection = switch familyMember.sex {
            case .male: .left
            case .female: .right
            }
        }
    }
    
    func setPosition(to position: SMPoint?) {
        self.position = position
    }
    
    func setPreferredDirection(to direction: HorizontalDirection) {
        self.preferredDirection = direction
    }
    
    func togglePreferenceDirection() {
        self.preferredDirection = switch self.preferredDirection {
        case .right: .left
        case .left: .right
        }
    }
    
}
