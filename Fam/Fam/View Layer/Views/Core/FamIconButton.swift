//
//  FamIconButton.swift
//  Fam
//
//  Created by Andre Pham on 17/2/2024.
//

import Foundation
import UIKit

class FamIconButton: FamView {
    
    private let button = FamControl()
    private let icon = FamIcon()
    private var onTap: (() -> Void)? = nil
    
    override func setup() {
        super.setup()
        
        self.add(self.button)
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
        
        // Adjust by +8.0 so the button size is slightly larger than the actual icon
        self.matchWidthConstraint(to: self.icon, adjust: 8, respectSafeArea: false)
            .matchHeightConstraint(to: self.icon, adjust: 8, respectSafeArea: false)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setCornerRadius(to: min(self.bounds.width, self.bounds.height)/2.0)
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

