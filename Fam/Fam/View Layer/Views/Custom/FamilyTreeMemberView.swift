//
//  FamilyTreeMemberView.swift
//  Fam
//
//  Created by Andre Pham on 1/12/2024.
//

import Foundation
import UIKit

class FamilyTreeMemberView: FamView {
    
    private let stack = FamVStack()
    private let profileImage = FamImage()
    private let familyMemberNameText = FamText()
    
    override func setup() {
        super.setup()
        
        self
            .setWidthConstraint(to: 140)
            .setBackgroundColor(to: FamColors.foregroundFill)
            .setCornerRadius(to: FamDimensions.foregroundCornerRadius)
            .add(self.stack)
        
        self.stack
            .constrainHorizontal(padding: 16)
            .constrainTop(padding: 30)
            .constrainBottom(padding: 16)
            .append(self.profileImage)
            .appendGap(size: 24)
            .append(self.familyMemberNameText)
        
        self.profileImage
            .setWidthConstraint(to: 80)
            .setHeightConstraint(to: 80)
            .setBackgroundColor(to: FamColors.accent)
            .setCornerRadius(to: 32)
            .setImage(UIImage(imageLiteralResourceName: "frog"))
            .setClipsToBounds(to: true)
        
        self.familyMemberNameText
            .toggleWordWrapping(to: false)
            .setFont(to: FamFont(font: FamFonts.Poppins.SemiBold, size: 16))
            .setTextAlignment(to: .center)
            .constrainHorizontal()
    }
    
    @discardableResult
    func setFamilyMemberName(firstName: String, lastName: String? = nil) -> Self {
        guard let lastName else {
            self.familyMemberNameText.setText(to: firstName)
            return self
        }
        let fullName = "\(firstName) \(lastName)"
        if self.familyMemberNameText.fits(text: fullName) {
            self.familyMemberNameText.setText(to: fullName)
            return self
        }
        let abbreviatedName = "\(firstName) \(lastName.prefix(1))."
        if self.familyMemberNameText.fits(text: abbreviatedName) {
            self.familyMemberNameText.setText(to: abbreviatedName)
            return self
        }
        var truncatedFirstName = firstName
        while !self.familyMemberNameText.fits(text: "\(truncatedFirstName)... \(lastName.prefix(1)).") {
            guard !truncatedFirstName.isEmpty else {
                assertionFailure("First name couldn't even fit a single letter")
                return self
            }
            truncatedFirstName.removeLast()
        }
        self.familyMemberNameText.setText(to: "\(truncatedFirstName)... \(lastName.prefix(1)).")
        return self
    }
    
}

#Preview {
    let view = FamilyTreeMemberView()
        .setFamilyMemberName(firstName: "Andre", lastName: "Pham")
    return PreviewContentView()
        .preview(view)
}

#Preview("Long last name") {
    let view = FamilyTreeMemberView()
        .setFamilyMemberName(firstName: "Andre", lastName: "PhamPhamPham")
    return PreviewContentView()
        .preview(view)
}

#Preview("Long full name") {
    let view = FamilyTreeMemberView()
        .setFamilyMemberName(firstName: "AndreAndreAndre", lastName: "PhamPhamPham")
    return PreviewContentView()
        .preview(view)
}
