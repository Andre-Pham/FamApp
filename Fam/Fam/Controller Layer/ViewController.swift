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
        
        let backgroundLayer = FamView()
            .setFrame(to: self.canvasController.canvasBox.cgRect)
            .setBackgroundColor(to: .red.withAlphaComponent(0.2))
        self.canvasController.addLayer(backgroundLayer)
        let box = SMRect(origin: SMPoint(), end: SMPoint(x: 200, y: 200))
        let boxView = FamView()
            .setFrame(to: box.cgRect)
            .setBackgroundColor(to: .blue)
        backgroundLayer.addSubview(boxView)
    }
    
    func createFamily() -> FamilyMemberStore {
        let family = FamilyMemberStore()
        let andre = FamilyMember(firstName: "Andre", sex: .male, family: family)
        let stephanie = FamilyMember(firstName: "Stephanie", sex: .female, family: family)
        let tristan = FamilyMember(firstName: "Tristan", sex: .male, family: family)
        let heather = FamilyMember(firstName: "Heather", sex: .female, family: family)
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
        
        tristan.assignSpouse(heather)
        tristan.assignChildren(andre, stephanie)
        jo.assignSpouse(carolyn)
        jo.assignChildren(heather, ralph, ken)
        ken.assignSpouse(debra)
        ralph.assignSpouse(carol)
        ralph.assignChildren(hugh, conner, anna)
        will.assignSpouse(johanna)
        will.assignChildren(cees, wim, tiela, jo)
        
        return family
    }

}

