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
            guard var position1 = coupleConnection.leftPartner.position?.clone(),
                  var position2 = coupleConnection.rightPartner.position?.clone() else {
                //assertionFailure("Missing positions for parents") // NOTE: Commented out for steps
                continue
            }
            let connectionView = LineView2().setPoints(position1, position2)
            connectionLayer.add(connectionView)
            connectionView
                .constrainLeft(padding: connectionView.boundingBox.minX + self.canvasController.canvasRect.width/2)
                .constrainTop(padding: connectionView.boundingBox.minY + self.canvasController.canvasRect.height/2)
        }
        
        for childConnection in render.childConnections {
            guard var parentPosition1 = childConnection.parentsConnection.leftPartner.position?.clone(),
                  var parentPosition2 = childConnection.parentsConnection.rightPartner.position?.clone(),
                  var childPosition = childConnection.child.position?.clone() else {
                //assertionFailure("Missing positions for parents") // NOTE: Commented out for steps
                continue
            }
            // TODO: In the future, the connections down from the two parents shouldn't be duplicated
            // TODO: These would be tracked as seperate connections - "parent connections" - and the parent connections would connect to the child connections
            let positionBetweenParents = SMLineSegment(origin: parentPosition1, end: parentPosition2).midPoint
            let connectionView1 = LineView2().setPoints(positionBetweenParents, positionBetweenParents + SMPoint(x: 0, y: 100))
            connectionLayer.add(connectionView1)
            connectionView1
                .constrainLeft(padding: connectionView1.boundingBox.minX + self.canvasController.canvasRect.width/2)
                .constrainTop(padding: connectionView1.boundingBox.minY + self.canvasController.canvasRect.height/2)
            let connectionView2 = LineView2().setPoints(positionBetweenParents + SMPoint(x: 0, y: 100), childPosition - SMPoint(x: 0, y: 80))
            connectionLayer.add(connectionView2)
            connectionView2
                .constrainLeft(padding: connectionView2.boundingBox.minX + self.canvasController.canvasRect.width/2)
                .constrainTop(padding: connectionView2.boundingBox.minY + self.canvasController.canvasRect.height/2)
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
        
        let testLine = TestLineView().setPoints()
        familyMemberLayer.add(testLine)
        testLine
            .constrainLeft(padding: testLine.boundingBox.minX + self.canvasController.canvasRect.width/2)
            .constrainTop(padding: testLine.boundingBox.minY + self.canvasController.canvasRect.height/2)
        
        let testLine2 = TestLineView().setPoints([SMPoint(x: 0, y: -200), SMPoint(x: 100, y: -400), SMPoint(x: 200, y: -200)])
        familyMemberLayer.add(testLine2)
        testLine2
            .constrainLeft(padding: testLine2.boundingBox.minX + self.canvasController.canvasRect.width/2)
            .constrainTop(padding: testLine2.boundingBox.minY + self.canvasController.canvasRect.height/2)
        
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
        
//        let test = FamView()
//            .setWidthConstraint(to: 5)
//            .setHeightConstraint(to: 5)
//            .setBackgroundColor(to: .red)
//        familyMemberLayer.addSubview(test)
//        test
//            .constrainCenterLeft(padding: 100)
//            .constrainCenterTop(padding: 100)
    }
    
    func createFamily() -> Family {
        return MockFamilies.standard
    }

}

class LineView2: FamView {
    
    private var startPoint = SMPoint()
    private var endPoint = SMPoint()
    private(set) var boundingBox = SMRect(minX: 0, maxX: 0, minY: 0, maxY: 0)
    
    override func setup() {
        super.setup()
        self.setBackgroundColor(to: .clear)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.beginPath()
        context.move(to: self.startPoint.cgPoint)
        context.addLine(to: self.endPoint.cgPoint)
        context.setStrokeColor(UIColor.green.cgColor)
        context.setLineWidth(4)
        context.strokePath()
    }
    
    @discardableResult
    func setPoints(_ start: SMPoint, _ end: SMPoint) -> Self {
        let boundingBox = SMPointCollection(points: [start, end]).boundingBox!
        boundingBox.expandAllSides(by: 4)
        self.startPoint = start - boundingBox.origin
        self.endPoint = end - boundingBox.origin
        self.boundingBox = boundingBox
        return self
            .removeWidthConstraint()
            .removeHeightConstraint()
            .setWidthConstraint(to: boundingBox.width)
            .setHeightConstraint(to: boundingBox.height)
    }
    
}

class TestLineView: FamView {
    
    private var points = [SMPoint]()
    private(set) var boundingBox = SMRect(minX: 0, maxX: 0, minY: 0, maxY: 0)
    
    override func setup() {
        super.setup()
        self.setBackgroundColor(to: .clear)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let line = SMPolyline(vertices: self.points)
//        let roundedLine = line.roundedCorners(radius: 30, controlPointDistance: 60)
        let roundedLine = line.roundedCorners(pointDistance: 250, controlPointDistance: 200)

        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.addPath(line.cgPath)
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(6)
        context.strokePath()
        
        context.addPath(roundedLine.cgPath)
        context.setStrokeColor(UIColor.green.cgColor)
        context.setLineWidth(8)
        context.strokePath()
        
        for bez in roundedLine.sortedBezierEdges {
            context.addEllipse(in: SMRect(center: bez.origin, width: 20, height: 20).cgRect)
            context.setFillColor(UIColor.purple.cgColor)
            context.fillPath()
            context.addEllipse(in: SMRect(center: bez.originControlPoint, width: 20, height: 20).cgRect)
            context.setFillColor(UIColor.blue.cgColor)
            context.fillPath()
            context.addEllipse(in: SMRect(center: bez.end, width: 20, height: 20).cgRect)
            context.setFillColor(UIColor.red.cgColor)
            context.fillPath()
            context.addEllipse(in: SMRect(center: bez.endControlPoint, width: 20, height: 20).cgRect)
            context.setFillColor(UIColor.orange.cgColor)
            context.fillPath()
        }
        
        let boundingBox = roundedLine.boundingBox
        context.addRect(boundingBox.cgRect)
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(8)
        context.strokePath()
    }
    
    @discardableResult
    func setPoints(_ points: [SMPoint] = [SMPoint(x: 0, y: 0), SMPoint(x: 0, y: 500), SMPoint(x: 500, y: 700), SMPoint(x: 500, y: 1200)]) -> Self {
        let line = SMPolyline(vertices: points)
        let roundedLine = line.roundedCorners(pointDistance: 250, controlPointDistance: 200)
        dump(roundedLine)
        
        let boundingBox = SMPointCollection(points: points).boundingBox!
        // TODO: This is temp
        boundingBox.expandAllSides(by: 50)
        for point in points {
            self.points.append(point - boundingBox.origin)
        }
        self.boundingBox = boundingBox
        return self
            .removeWidthConstraint()
            .removeHeightConstraint()
            .setWidthConstraint(to: boundingBox.width)
            .setHeightConstraint(to: boundingBox.height)
    }
    
}
