//
//  FamChipButton.swift
//  Fam
//
//  Created by Andre Pham on 4/8/2023.
//

import Foundation
import UIKit

class FamChipButton: FamView {
    
    private let button = FamControl()
    private let icon = FamIcon()
    private var onTap: (() -> Void)? = nil

    override func setup() {
        super.setup()
        
        self
            .setWidthConstraint(to: 60)
            .setHeightConstraint(to: 48)
            .setBackgroundColor(to: FamColors.secondaryComponentFill)
            .setCornerRadius(to: FamDimensions.foregroundCornerRadius)
            .add(self.button)
            .add(self.icon)
        
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
            .constrainCenter(respectSafeArea: false)
            .setColor(to: FamColors.textSecondaryComponent)
    }
    
    @discardableResult
    func setIcon(to config: FamIcon.Config) -> Self {
        self.icon.setIcon(to: config)
        return self
    }
    
    @discardableResult
    func setColor(to color: UIColor) -> Self {
        self.setBackgroundColor(to: color)
        return self
    }
    
    @discardableResult
    func setOnTap(_ callback: (() -> Void)?) -> Self {
        self.onTap = callback
        return self
    }
    
}
