//
//  FamChipToggle.swift
//  Fam
//
//  Created by Andre Pham on 4/8/2023.
//

import Foundation
import UIKit

class FamChipToggle: FamView {
    
    private let button = FamControl()
    private let icon = FamIcon()
    private var activatedIconConfig = FamIcon.Config(color: FamColors.textPrimaryComponent)
    private var deactivatedIconConfig = FamIcon.Config(color: FamColors.textSecondaryComponent)
    private var deactivatedColor = FamColors.secondaryComponentFill
    private var activatedColor = FamColors.primaryComponentFill
    private(set) var isActivated = false
    private var onTap: ((_ isEnabled: Bool) -> Void)? = nil
    public var isDisabled: Bool {
        return self.button.isDisabled
    }
    
    override func setup() {
        super.setup()
        
        self
            .setWidthConstraint(to: 60)
            .setHeightConstraint(to: 48)
            .setBackgroundColor(to: self.deactivatedColor)
            .setCornerRadius(to: FamDimensions.foregroundCornerRadius)
            .add(self.button)
            .add(self.icon)
        
        self.button
            .constrainAllSides(respectSafeArea: false)
            .setOnPress({
                self.animatePressedOpacity()
            })
            .setOnRelease({
                self.onTapCallback()
                self.animateReleaseOpacity()
            })
            .setOnCancel({
                self.animateReleaseOpacity()
            })
        
        self.icon
            .constrainCenter(respectSafeArea: false)
    }
    
    private func refresh() {
        self.setBackgroundColor(to: self.isActivated ? self.activatedColor : self.deactivatedColor)
        self.icon.setIcon(to: self.isActivated ? self.activatedIconConfig : self.deactivatedIconConfig)
    }
    
    @discardableResult
    func setState(activated: Bool, trigger: Bool = false) -> Self {
        self.isActivated = activated
        self.refresh()
        if trigger {
            self.onTap?(self.isActivated)
        }
        return self
    }
    
    @discardableResult
    func setIcon(to activated: FamIcon.Config, deactivated: FamIcon.Config? = nil) -> Self {
        // We want to merge configs here
        // Otherwise the default config settings (e.g. color) gets overridden by just setting new icons
        self.activatedIconConfig = self.activatedIconConfig.merge(activated)
        if let deactivated {
            self.deactivatedIconConfig = self.deactivatedIconConfig.merge(deactivated)
        } else {
            self.deactivatedIconConfig = self.deactivatedIconConfig.merge(activated)
        }
        self.refresh()
        return self
    }
    
    @discardableResult
    func setColor(activated: UIColor, deactivated: UIColor) -> Self {
        self.activatedColor = activated
        self.deactivatedColor = deactivated
        self.refresh()
        return self
    }
    
    @discardableResult
    func setOnTap(_ callback: ((_ isEnabled: Bool) -> Void)?) -> Self {
        self.onTap = callback
        return self
    }
    
    @discardableResult
    func setDisabled(to state: Bool) -> Self {
        self.button.setDisabled(to: state)
        return self
    }
    
    private func onTapCallback() {
        self.isActivated.toggle()
        self.refresh()
        self.onTap?(self.isActivated)
    }
    
}
