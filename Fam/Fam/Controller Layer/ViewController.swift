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
    private var family = Family()
    
    private let buttonStack = FamHStack()
    private let addParentButton = FamButton()
    private let addChildButton = FamButton()
    private let addSpouseButton = FamButton()
    private let renderButton = FamButton()
    private let resetButton = FamButton()
    private let minusStepButton = FamButton()
    private let stepText = FamText()
    private let plusStepButton = FamButton()
    private var controls = [FamControl]()
    private var selected: FamilyMember? = nil
    private var step = 0
    
    let testView = FamChipToggle()
    let textTest = FamText()
    let familyMemberView = FamilyTreeMemberView()

    override func viewDidLoad() {
        super.viewDidLoad()
        let canvasView = self.canvasController.mount(to: self)
        self.view.add(canvasView)
        canvasView.constrainAllSides(padding: 50)
        
        self.canvasController.setCanvasBackgroundColor(to: .lightGray)
        
        self.family = self.createFamily()
        
        self.renderFamily()
        
//        let autoLayoutLayer = self.canvasController.addLayer()
//        autoLayoutLayer
//            .add(self.testView)
//        self.testView
//            .setIcon(to: FamIcon.Config(systemName: "scribble.variable"))
//            .constrainTop(padding: 200)
//            .constrainLeft(padding: 200)
//        
//        autoLayoutLayer
//            .add(self.textTest)
//        self.textTest
//            .setFont(to: FamFont(font: FamFonts.Quicksand.SemiBold, size: 100))
//            .setText(to: "Hello World")
        
//        autoLayoutLayer
//            .add(self.familyMemberView)
//        self.familyMemberView
//            .constrainTop(padding: 500)
//            .constrainLeft(padding: 500)
//            .setFamilyMemberName(firstName: "Andre", lastName: "Pham")
        
        self.view
            .add(self.buttonStack)
        self.buttonStack
            .setSpacing(to: 10)
            .append(self.addChildButton)
            .append(self.addParentButton)
            .append(self.addSpouseButton)
            .append(self.renderButton)
            .append(self.resetButton)
            .append(self.minusStepButton)
            .append(self.stepText)
            .append(self.plusStepButton)
            .constrainCenterHorizontal()
            .constrainBottom(padding: 100)
        self.addChildButton
            .setLabel(to: "Add Child")
            .setOnTap({
                guard let selected = self.selected else {
                    return
                }
                let newMemberSex: FamilyMember.Sex = Int.random(in: 1...2) == 1 ? .male : .female
                let newMemberSexLetter = newMemberSex == .female ? "(F)" : "(M)"
                let newMember = FamilyMember(firstName: "\(selected.firstName)'s Child \(newMemberSexLetter)", sex: newMemberSex, family: self.family)
                selected.assignChild(newMember)
                if let selectedSpouse = selected.spouse {
                    selectedSpouse.assignChild(newMember)
                }
                self.renderFamily()
            })
        self.addParentButton
            .setLabel(to: "Add Parents")
            .setOnTap({
                guard let selected = self.selected else {
                    return
                }
                if selected.hasNoParents {
                    let father = FamilyMember(firstName: "\(selected.firstName)'s Father", sex: .male, family: self.family)
                    let mother = FamilyMember(firstName: "\(selected.firstName)'s Mother", sex: .female, family: self.family)
                    father.assignSpouse(mother)
                    selected.assignParents(father, mother)
                    self.renderFamily()
                }
            })
        self.addSpouseButton
            .setLabel(to: "Add Spouse")
            .setOnTap({
                guard let selected = self.selected else {
                    return
                }
                if !selected.hasSpouse {
                    let newMember = FamilyMember(firstName: "\(selected.firstName)'s Spouse", sex: Int.random(in: 1...2) == 1 ? .male : .female, family: self.family)
                    selected.assignSpouse(newMember)
                    self.renderFamily()
                }
            })
        self.renderButton
            .setLabel(to: "Render")
            .setOnTap({
                self.renderFamily()
            })
        self.resetButton
            .setLabel(to: "Reset")
            .setOnTap({
                self.family = self.createFamily()
                self.selected = nil
                self.renderFamily()
            })
        self.minusStepButton
            .setLabel(to: "-")
            .setOnTap({
                self.step = max(0, self.step - 1)
                self.stepText.setText(to: String(self.step))
                self.renderFamily()
            })
        self.stepText
            .setText(to: String(self.step))
        self.plusStepButton
            .setLabel(to: "+")
            .setOnTap({
                self.step += 1
                self.stepText.setText(to: String(self.step))
                self.renderFamily()
            })
    }
    
    func renderFamily() {
        let render = FamilyRenderProxy(self.family, stopAtStep: self.step == 0 ? nil : self.step)
        print(render.generateTraceStack())
        
        let connectionLayer = self.canvasController.addLayer()
            .setBackgroundColor(to: .blue.withAlphaComponent(0.2))
        let familyMemberLayer = self.canvasController.addLayer()
        
        for coupleConnection in render.coupleConnections {
            guard let position1 = coupleConnection.leftPartner.position,
                  let position2 = coupleConnection.rightPartner.position else {
                //assertionFailure("Missing positions for parents") // NOTE: Commented out for steps
                continue
            }
            let lineSegment = SMLineSegment(origin: position1, end: position2) + SMPoint(x: self.canvasController.canvasRect.width/2, y: self.canvasController.canvasRect.height/2)
            let connectionView = LineSegmentView()
                .setLineSegment(lineSegment)
            connectionLayer.add(connectionView)
            connectionView.constrainToPosition()
        }
        
        for childConnection in render.childConnections {
            guard let parentPosition1 = childConnection.parentsConnection.leftPartner.position,
                  let parentPosition2 = childConnection.parentsConnection.rightPartner.position,
                  let childPosition = childConnection.child.position else {
                //assertionFailure("Missing positions for parents") // NOTE: Commented out for steps
                continue
            }
            // TODO: In the future, the connections down from the two parents shouldn't be duplicated
            // TODO: These would be tracked as seperate connections - "parent connections" - and the parent connections would connect to the child connections
            let positionBetweenParents = SMLineSegment(origin: parentPosition1, end: parentPosition2).midPoint
            let connectionLineSegment = SMLineSegment(origin: positionBetweenParents, end: positionBetweenParents + SMPoint(x: 0, y: 100))
                .translated(x: self.canvasController.canvasRect.width/2, y: self.canvasController.canvasRect.height/2)
            let connectionView1 = LineSegmentView()
                .setLineSegment(connectionLineSegment)
            connectionLayer.add(connectionView1)
            connectionView1.constrainToPosition()
            let connectionLineSegment2 = SMLineSegment(origin: positionBetweenParents + SMPoint(x: 0, y: 100), end: childPosition - SMPoint(x: 0, y: 80))
                .translated(x: self.canvasController.canvasRect.width/2, y: self.canvasController.canvasRect.height/2)
            let connectionView2 = LineSegmentView()
                .setLineSegment(connectionLineSegment2)
            connectionLayer.add(connectionView2)
            connectionView2.constrainToPosition()
        }
    
        for proxy in render.orderedFamilyMemberProxies {
            guard let position = proxy.position else {
                continue
            }
            let familyMemberView = FamilyTreeMemberView()
                .setFamilyMemberName(firstName: proxy.familyMember.firstName, lastName: proxy.familyMember.lastName)
            familyMemberLayer.add(familyMemberView)
            familyMemberView
                .constrainCenterLeft(padding: position.x + self.canvasController.canvasRect.width/2)
                .constrainCenterTop(padding: position.y + self.canvasController.canvasRect.height/2)
        }
        
        let testGeometry = SMPolyline(vertices: [SMPoint(x: 0, y: 0), SMPoint(x: 0, y: 500), SMPoint(x: 500, y: 700), SMPoint(x: 500, y: 1200)])
            .translated(x: self.canvasController.canvasRect.width/2, y: self.canvasController.canvasRect.height/2)
        let testLine = CurvilinearEdgesView()
            .setCurvilinearEdges(testGeometry.roundedCorners(pointDistance: 250, controlPointDistance: 200))
            .setLineWidth(to: 10)
            .addBorder()
        familyMemberLayer.add(testLine)
        testLine.constrainToPosition()
        
        let testGeometry2 = SMPolyline(vertices: [SMPoint(x: 0, y: -200), SMPoint(x: 100, y: -400), SMPoint(x: 200, y: -200)])
            .translated(x: self.canvasController.canvasRect.width/2, y: self.canvasController.canvasRect.height/2)
        let testLine2 = CurvilinearEdgesView()
            .setCurvilinearEdges(testGeometry2.roundedCorners(pointDistance: 250, controlPointDistance: 200))
            .addBorder()
        familyMemberLayer.add(testLine2)
        testLine2.constrainToPosition()
        
        let testLine3 = LineSegmentView()
            .setLineSegment(SMLineSegment(origin: SMPoint(x: 100, y: 100), end: SMPoint(x: 500, y: 750)))
            .setLineWidth(to: 50)
            .setLineCap(to: .round)
            .addBorder()
        familyMemberLayer.add(testLine3)
        testLine3
            .constrainToPosition()
        
        let testLine4 = LineSegmentView()
            .setLineSegment(SMLineSegment(origin: SMPoint(x: 600, y: 100), end: SMPoint(x: 1000, y: 100)))
            .setLineCap(to: .square)
        familyMemberLayer.add(testLine4)
        testLine4
            .constrainToPosition()
    }
    
    func createFamily() -> Family {
        return MockFamilies.standard
    }

}
