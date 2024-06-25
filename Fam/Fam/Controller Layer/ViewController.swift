//
//  ViewController.swift
//  Fam
//
//  Created by Andre Pham on 17/4/2024.
//

import UIKit
import SwiftMath

class ViewController: UIViewController {
    
    private let canvasController = CanvasController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Step 1: Add the Child View Controller to the Parent
        addChild(self.canvasController)
        
        // Step 2: Set Up the Child View Controller’s View
        view.addSubview(self.canvasController.view)
        self.canvasController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Step 3: Apply Auto Layout Constraints
        NSLayoutConstraint.activate([
            self.canvasController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            self.canvasController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            self.canvasController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 64),
            self.canvasController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -48)
        ])
        
        // Step 4: Notify the Child View Controller
        self.canvasController.didMove(toParent: self)
        
        self.canvasController.setCanvasBackgroundColor(to: .lightGray)
        
//        let backgroundLayer = FamView()
//            .setFrame(to: self.canvasController.canvasRect.cgRect)
//            .setBackgroundColor(to: .red.withAlphaComponent(0.2))
//        self.canvasController.addLayer(backgroundLayer)
//        let box = SMRect(origin: SMPoint(), end: SMPoint(x: 200, y: 200))
//        let boxView = FamView()
//            .setFrame(to: box.cgRect)
//            .setBackgroundColor(to: .blue)
//        backgroundLayer.addSubview(boxView)
        
        let family = self.createFamily()
        let root = family.getAllFamilyMembers().first(where: { $0.firstName == "Andre" })!
        (FamilyMemberStoreRenderProxy(family, root: root).orderedFamilyMemberProxies.forEach({ print($0.familyMember.firstName) }))
        
        let render = FamilyMemberStoreRenderProxy(family, root: root)
        
        let connectionLayer = FamView()
            .setFrame(to: self.canvasController.canvasRect.cgRect)
            .setBackgroundColor(to: .white)
        self.canvasController.addLayer(connectionLayer)
        for coupleConnection in render.coupleConnections {
            guard var position1 = coupleConnection.malePartner.position?.clone(), var position2 = coupleConnection.femalePartner.position?.clone() else {
                assertionFailure("Missing positions for parents")
                continue
            }
            print(coupleConnection.malePartner.familyMember.firstName)
            print(coupleConnection.femalePartner.familyMember.firstName)
            position1 += SMPoint(x: self.canvasController.canvasRect.width/2, y: self.canvasController.canvasRect.height/2)
            position2 += SMPoint(x: self.canvasController.canvasRect.width/2, y: self.canvasController.canvasRect.height/2)
            print("\(position1.toString()) -> \(position2.toString())")
            let view = FamView(LineView(startPoint: position1.cgPoint, endPoint: position2.cgPoint))
            view.view.translatesAutoresizingMaskIntoConstraints = false
            connectionLayer.addSubview(view)
        }
        
        for childConnection in render.childConnections {
            guard var parentPosition1 = childConnection.parentsConnection.malePartner.position?.clone(),
                  var parentPosition2 = childConnection.parentsConnection.femalePartner.position?.clone(),
                  var childPosition = childConnection.child.position?.clone() else {
                assertionFailure("Missing positions for parents")
                continue
            }
            // TODO: In the future, the connections down from the two parents shouldn't be duplicated
            // TODO: These would be tracked as seperate connections - "parent connections" - and the parent connections would connect to the child connections
            parentPosition1 += SMPoint(x: self.canvasController.canvasRect.width/2, y: self.canvasController.canvasRect.height/2)
            parentPosition2 += SMPoint(x: self.canvasController.canvasRect.width/2, y: self.canvasController.canvasRect.height/2)
            childPosition += SMPoint(x: self.canvasController.canvasRect.width/2, y: self.canvasController.canvasRect.height/2)
            let positionBetweenParents = SMLineSegment(origin: parentPosition1, end: parentPosition2).midPoint
            let line1 = FamView(LineView(
              
                startPoint: positionBetweenParents.cgPoint,
                endPoint: (positionBetweenParents + SMPoint(x: 0, y: 50)).cgPoint
            ))
            line1.view.translatesAutoresizingMaskIntoConstraints = false
            connectionLayer.addSubview(line1)
            let line2 = FamView(LineView(
            
                startPoint: (positionBetweenParents + SMPoint(x: 0, y: 50)).cgPoint,
                endPoint: (childPosition - SMPoint(x: 0, y: 40)).cgPoint
            ))
            line2.view.translatesAutoresizingMaskIntoConstraints = false
            connectionLayer.addSubview(line2)
            print("Line drawn")
        }
        
        let drawLayer = FamView()
            .setFrame(to: self.canvasController.canvasRect.cgRect)
        self.canvasController.addLayer(drawLayer)
        for proxy in render.orderedFamilyMemberProxies {
            if let position = proxy.position {
                let view = FamView().setBackgroundColor(to: .blue)
                let text = FamText().setText(to: proxy.familyMember.firstName + " " + (proxy.position?.toString()  ?? "-")).setTextColor(to: .white)
                drawLayer.addSubview(view)
                view.addSubview(text)
                view.setFrame(to: SMRect(
                    center: position + SMPoint(x: self.canvasController.canvasRect.width/2, y: self.canvasController.canvasRect.height/2),
                    width: 80,
                    height: 80
                ).cgRect)
                text.setFrame(to: CGRect(x: 0, y: 0, width: 80, height: 80))
            }
        }
        
    }
    
    func createFamily() -> FamilyMemberStore {
        let family = FamilyMemberStore()
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
        
        return family
    }

}

class LineView: UIView {
    var startPoint: CGPoint
    var endPoint: CGPoint

    init(startPoint: CGPoint, endPoint: CGPoint) {
        let boundingBox = SMPointCollection(points: [SMPoint(startPoint), SMPoint(endPoint)]).boundingBox!
        let expansion = 4.0
        boundingBox.expandAllSides(by: expansion)
        self.startPoint = (SMPoint(startPoint) - boundingBox.origin).cgPoint
        self.endPoint = (SMPoint(endPoint) - boundingBox.origin).cgPoint
        super.init(frame: boundingBox.cgRect)
        self.backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.beginPath()
        context.move(to: self.startPoint)
        context.addLine(to: self.endPoint)
        context.setStrokeColor(UIColor.green.cgColor)
        context.setLineWidth(4)
        context.strokePath()
    }
}
