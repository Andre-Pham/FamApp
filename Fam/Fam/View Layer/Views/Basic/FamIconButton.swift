//
//  FamIconButton.swift
//  Fam
//
//  Created by Andre Pham on 8/3/2024.
//

import Foundation
import UIKit

class FamIconButton: FamUIView {
    
    private let container = FamView()
    private let button = FamControl()
    private let imageView = FamImage()
    private var onTap: (() -> Void)? = nil
    private var imageHorizontalPadding = 4.0
    private var imageVerticalPadding = 4.0
    public var view: UIView {
        return self.container.view
    }
    
    override init() {
        super.init()
        
        self.container
            .setWidthConstraint(to: 38.0)
            .setHeightConstraint(to: 38.0)
            .setBackgroundColor(to: .clear)
            .setCornerRadius(to: 38.0/2.0)
            .addSubview(self.button)
            .addSubview(self.imageView)
        
        self.button
            .constrainAllSides()
            .setOnPress({
                self.container.animatePressedOpacity()
            })
            .setOnRelease({
                self.onTapCallback()
                self.container.animateReleaseOpacity()
            })
        
        self.imageView
            .constrainHorizontal(padding: self.imageHorizontalPadding)
            .constrainVertical(padding: self.imageVerticalPadding)
            .setColor(to: FamColors.accent)
    }
    
    @discardableResult
    func setIcon(to icon: String) -> Self {
        if let image = UIImage(named: icon) {
            self.imageView.setImage(image)
        } else if let image = UIImage(systemName: icon) {
            self.imageView.setImage(image)
        }
        return self
    }
    
    @discardableResult
    func setColor(to color: UIColor) -> Self {
        self.container.setBackgroundColor(to: color)
        return self
    }
    
    @discardableResult
    func setIconColor(to color: UIColor) -> Self {
        self.imageView.setColor(to: color)
        return self
    }
    
    @discardableResult
    func setOnTap(_ callback: (() -> Void)?) -> Self {
        self.onTap = callback
        return self
    }
    
    @discardableResult
    func overrideWidthConstraint(to width: Double) -> Self {
        assert(width.isGreater(than: self.imageHorizontalPadding*2), "New width doesn't fit subview padding")
        self.container.removeWidthConstraint()
        self.container.setWidthConstraint(to: width)
        return self
    }
    
    @discardableResult
    func overrideHeightConstraint(to height: Double) -> Self {
        assert(height.isGreater(than: self.imageVerticalPadding*2), "New width doesn't fit subview padding")
        self.container.removeHeightConstraint()
        self.container.setHeightConstraint(to: height)
        return self
    }
    
    @discardableResult
    func applySquareAspectRatio(useLongestSide: Bool = true) -> Self {
        let height = self.heightConstraintConstant
        let width = self.widthConstraintConstant
        let newLength = useLongestSide ? max(height, width) : min(height, width)
        self.overrideWidthConstraint(to: newLength)
        self.overrideHeightConstraint(to: newLength)
        return self
    }
    
    @discardableResult
    func overrideIconHorizontalPadding(to padding: Double) -> Self {
        assert(self.widthConstraintConstant.isGreater(than: padding*2), "Padding doesn't fit in view bounds")
        self.imageView.removeFromSuperView()
        self.container.addSubview(self.imageView)
        self.imageHorizontalPadding = padding
        self.imageView.constrainVertical(padding: self.imageVerticalPadding)
        self.imageView.constrainHorizontal(padding: self.imageHorizontalPadding)
        return self
    }
    
    @discardableResult
    func overrideIconVerticalPadding(to padding: Double) -> Self {
        assert(self.heightConstraintConstant.isGreater(than: padding*2), "Padding doesn't fit in view bounds")
        self.imageView.removeFromSuperView()
        self.container.addSubview(self.imageView)
        self.imageVerticalPadding = padding
        self.imageView.constrainVertical(padding: self.imageVerticalPadding)
        self.imageView.constrainHorizontal(padding: self.imageHorizontalPadding)
        return self
    }
    
    @discardableResult
    func overrideCornerRadius(to radius: Double) -> Self {
        self.container.setCornerRadius(to: radius)
        return self
    }
    
    private func onTapCallback() {
        self.onTap?()
    }
    
}

