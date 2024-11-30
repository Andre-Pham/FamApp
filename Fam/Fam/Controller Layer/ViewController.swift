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
        
        self.family = self.createFamily()
        
//        self.renderFamily()
        
        let autoLayoutLayer = FamView()
        self.canvasController.addLayer(autoLayoutLayer)
        autoLayoutLayer.constrainAllSides()
        autoLayoutLayer
            .add(self.testView)
        self.testView
            .setIcon(to: FamIcon.Config(systemName: "scribble.variable"))
            .constrainTop(padding: 200)
            .constrainLeft(padding: 200)
        
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
        
        let connectionLayer = FamView()
            .disableAutoLayout()
            .setFrame(to: self.canvasController.canvasRect.cgRect)
            .setBackgroundColor(to: .white)
        self.canvasController.addLayer(connectionLayer)
        for coupleConnection in render.coupleConnections {
            guard var position1 = coupleConnection.leftPartner.position?.clone(), var position2 = coupleConnection.rightPartner.position?.clone() else {
//                assertionFailure("Missing positions for parents") // NOTE: Commented out for steps
                continue
            }
//            print(coupleConnection.leftPartner.familyMember.firstName)
//            print(coupleConnection.rightPartner.familyMember.firstName)
            position1 += SMPoint(x: self.canvasController.canvasRect.width/2, y: self.canvasController.canvasRect.height/2)
            position2 += SMPoint(x: self.canvasController.canvasRect.width/2, y: self.canvasController.canvasRect.height/2)
//            print("\(position1.toString()) -> \(position2.toString())")
            let view = LineView(startPoint: position1.cgPoint, endPoint: position2.cgPoint).useAutoLayout()
            connectionLayer.add(view)
        }
        
        for childConnection in render.childConnections {
            guard var parentPosition1 = childConnection.parentsConnection.leftPartner.position?.clone(),
                  var parentPosition2 = childConnection.parentsConnection.rightPartner.position?.clone(),
                  var childPosition = childConnection.child.position?.clone() else {
//                assertionFailure("Missing positions for parents") // NOTE: Commented out for steps
                continue
            }
            // TODO: In the future, the connections down from the two parents shouldn't be duplicated
            // TODO: These would be tracked as seperate connections - "parent connections" - and the parent connections would connect to the child connections
            parentPosition1 += SMPoint(x: self.canvasController.canvasRect.width/2, y: self.canvasController.canvasRect.height/2)
            parentPosition2 += SMPoint(x: self.canvasController.canvasRect.width/2, y: self.canvasController.canvasRect.height/2)
            childPosition += SMPoint(x: self.canvasController.canvasRect.width/2, y: self.canvasController.canvasRect.height/2)
            let positionBetweenParents = SMLineSegment(origin: parentPosition1, end: parentPosition2).midPoint
            let line1 = LineView(
              
                startPoint: positionBetweenParents.cgPoint,
                endPoint: (positionBetweenParents + SMPoint(x: 0, y: 50)).cgPoint
            ).useAutoLayout()
            connectionLayer.add(line1)
            let line2 = LineView(
            
                startPoint: (positionBetweenParents + SMPoint(x: 0, y: 50)).cgPoint,
                endPoint: (childPosition - SMPoint(x: 0, y: 40)).cgPoint
            ).useAutoLayout()
            connectionLayer.add(line2)
        }
        
        let drawLayer = FamView()
            .disableAutoLayout()
            .setFrame(to: self.canvasController.canvasRect.cgRect)
        self.canvasController.addLayer(drawLayer)
        for proxy in render.orderedFamilyMemberProxies {
            if let position = proxy.position {
                let view = FamControl().setBackgroundColor(to: .blue).disableAutoLayout()
                let text = FamText().disableAutoLayout().setText(to: proxy.familyMember.firstName + " " + (proxy.position?.toString()  ?? "-")).setTextColor(to: .white)
                drawLayer.addSubview(view)
                view.addSubview(text)
                view.setFrame(to: SMRect(
                    center: position + SMPoint(x: self.canvasController.canvasRect.width/2, y: self.canvasController.canvasRect.height/2),
                    width: 80,
                    height: 80
                ).cgRect)
                view.setOnRelease({
                    self.selected = proxy.familyMember
                    print("SELECTED \(proxy.familyMember.fullName)")
                })
                text.setFrame(to: CGRect(x: 0, y: 0, width: 80, height: 80))
                self.controls.append(view)
            }
        }
    }
    
    func createFamily() -> Family {
        return MockFamilies.standard
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
