//
//  MockFamilies.swift
//  Fam
//
//  Created by Andre Pham on 12/10/2024.
//

import Foundation

enum MockFamilies {
    
    /// A standard family tree
    public static var standard: Family {
        let family = Family()
        // Direct
        let andre = FamilyMember(firstName: "Andre", sex: .male, family: family)
        let stephanie = FamilyMember(firstName: "Stephanie", sex: .female, family: family)
        let tristan = FamilyMember(firstName: "Tristan", sex: .male, family: family)
        let heather = FamilyMember(firstName: "Heather", sex: .female, family: family)
        // Heather's side
        let jo = FamilyMember(firstName: "Jo", sex: .male, family: family)
        let carolyn = FamilyMember(firstName: "Carolyn", sex: .female, family: family)
        let ralph = FamilyMember(firstName: "Ralph", sex: .male, family: family)
        let carol = FamilyMember(firstName: "Carol", sex: .female, family: family)
        let hugh = FamilyMember(firstName: "Hugh", sex: .male, family: family)
        let conner = FamilyMember(firstName: "Conner", sex: .male, family: family)
        let anna = FamilyMember(firstName: "Anna", sex: .female, family: family)
        let ken = FamilyMember(firstName: "Ken", sex: .male, family: family)
        let debra = FamilyMember(firstName: "Debra", sex: .female, family: family)
        let will = FamilyMember(firstName: "Will", sex: .male, family: family)
        let johanna = FamilyMember(firstName: "Johanna", sex: .female, family: family)
        let cees = FamilyMember(firstName: "Cees", sex: .female, family: family)
        let wim = FamilyMember(firstName: "Wim", sex: .male, family: family)
        let tiela = FamilyMember(firstName: "Tiela", sex: .female, family: family)
        // Tristan's side
        let thanh = FamilyMember(firstName: "Thanh-Lien", sex: .female, family: family)
        let ky = FamilyMember(firstName: "Ky", sex: .male, family: family)
        let dao = FamilyMember(firstName: "Dao", sex: .female, family: family)
        let melanie = FamilyMember(firstName: "Melanie", sex: .female, family: family)
        let kyMother = FamilyMember(firstName: "Ky Mother", sex: .female, family: family)
        let kyFather = FamilyMember(firstName: "Ky Father", sex: .male, family: family)
        let jade = FamilyMember(firstName: "Jade", sex: .female, family: family)
        let jadeHusband = FamilyMember(firstName: "Jade Husband", sex: .male, family: family)
        let khoi = FamilyMember(firstName: "Khoi", sex: .male, family: family)
        let thi = FamilyMember(firstName: "Thi", sex: .male, family: family)
        let gisele = FamilyMember(firstName: "Gisele", sex: .female, family: family)
        let lanVi = FamilyMember(firstName: "Lan Vi", sex: .female, family: family)
        let giseleMother = FamilyMember(firstName: "Gisele Mother", sex: .female, family: family)
        let giseleFather = FamilyMember(firstName: "Gisele Father", sex: .male, family: family)
        let thanhMother = FamilyMember(firstName: "Thahn-Lien Mother", sex: .female, family: family)
        let thanhFather = FamilyMember(firstName: "Thahn-Lien Father", sex: .male, family: family)
        let carolynMother = FamilyMember(firstName: "Carolyn Mother", sex: .female, family: family)
        let carolynFather = FamilyMember(firstName: "Carolyn Father", sex: .male, family: family)
        // Heather's side relationships
        tristan.assignSpouse(heather)
        tristan.assignChildren(andre, stephanie)
        heather.assignChildren(andre, stephanie)
        jo.assignSpouse(carolyn)
        jo.assignChildren(heather, ralph, ken)
        carolyn.assignChildren(heather, ralph, ken)
        ken.assignSpouse(debra)
        ralph.assignSpouse(carol)
        ralph.assignChildren(hugh, conner, anna)
        carol.assignChildren(hugh, conner, anna)
        will.assignSpouse(johanna)
        will.assignChildren(cees, wim, tiela, jo)
        johanna.assignChildren(cees, wim, tiela, jo)
        // Tristan's side relationships
        thanh.assignSpouse(ky)
        thanh.assignChildren(tristan, dao, khoi)
        ky.assignChildren(tristan, dao, khoi)
        dao.assignChild(melanie)
        kyMother.assignSpouse(kyFather)
        kyMother.assignChildren(ky, jade, thi)
        kyFather.assignChildren(ky, jade, thi)
        jade.assignSpouse(jadeHusband)
        thi.assignSpouse(gisele)
        thi.assignChildren(lanVi)
        gisele.assignChild(lanVi)
        giseleMother.assignSpouse(giseleFather)
        giseleMother.assignChildren(gisele)
        giseleFather.assignChildren(gisele)
        thanhMother.assignSpouse(thanhFather)
        thanhMother.assignChildren(thanh)
        thanhFather.assignChildren(thanh)
        carolynMother.assignSpouse(carolynFather)
        carolynMother.assignChildren(carolyn)
        carolynFather.assignChildren(carolyn)
        return family
    }
    
    /// The standard family tree with an inevitable conflict (impossible to avoid)
    public static var standardWithConflict: Family {
        let family = Self.standard
        let clashMother = FamilyMember(firstName: "Clash Mother", sex: .female, family: family)
        let clashFather = FamilyMember(firstName: "Clash Father", sex: .male, family: family)
        let jadeHusband = family.getAllFamilyMembers().first(where: { $0.firstName == "Jade Husband" })!
        clashMother.assignSpouse(clashFather)
        clashMother.assignChildren(jadeHusband)
        clashFather.assignChildren(jadeHusband)
        return family
    }
    
}
