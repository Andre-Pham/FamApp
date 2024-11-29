//
//  FamChipTextButton.swift
//  Fam
//
//  Created by Andre Pham on 30/8/2023.
//

import Foundation
import UIKit

class FamChipTextButton: FamView {
    
    private let contentStack = FamHStack()
    private let button = FamControl()
    private let icon = FamIcon()
    private let label = FamText()
    private var onTap: (() -> Void)? = nil
    
    override func setup() {
        super.setup()
        
        self
            .setHeightConstraint(to: 48)
            .setBackgroundColor(to: FamColors.secondaryComponentFill)
            .setCornerRadius(to: FamDimensions.foregroundCornerRadius)
            .add(self.contentStack)
            .add(self.button)
        
        self.contentStack
            .constrainVertical(respectSafeArea: false)
            .constrainHorizontal(padding: 17, respectSafeArea: false)
            .setSpacing(to: 10)
            .append(self.icon)
            .append(self.label)
        
        self.button
            .constrainAllSides(respectSafeArea: false)
            .setOnPress({
                self.animatePressedOpacity()
            })
            .setOnRelease({
                self.onTap?()
                self.animateReleaseOpacity()
            })
        
        self.icon
            .setColor(to: FamColors.textSecondaryComponent)
        
        self.label
            .setFont(to: FamFont(font: FamFonts.Quicksand.SemiBold, size: 20))
            .setTextAlignment(to: .center)
    }
    
    @discardableResult
    func setIcon(to config: FamIcon.Config) -> Self {
        self.icon.setIcon(to: config)
        return self
    }
    
    @discardableResult
    func setLabel(to label: String) -> Self {
        self.label.setText(to: label)
        return self
    }
    
    @discardableResult
    func setLabelSize(to size: CGFloat) -> Self {
        self.label.setSize(to: size)
        return self
    }
    
    @discardableResult
    func setColor(to color: UIColor) -> Self {
        self.setBackgroundColor(to: color)
        return self
    }
    
    @discardableResult
    func setForegroundColor(to color: UIColor) -> Self {
        self.icon.setColor(to: color)
        self.label.setTextColor(to: color)
        return self
    }
    
    @discardableResult
    func setOnTap(_ callback: (() -> Void)?) -> Self {
        self.onTap = callback
        return self
    }
    
}
