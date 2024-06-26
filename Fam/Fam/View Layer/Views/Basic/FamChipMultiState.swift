//
//  FamChipMultiState.swift
//  Fam
//
//  Created by Andre Pham on 8/3/2024.
//

import Foundation
import UIKit

class FamChipMultiState<T: Any>: FamUIView {
    
    private let container = FamView()
    private let button = FamControl()
    private let contentStack = FamHStack()
    private let imageView = FamImage()
    public let label = FamText()
    private(set) var values = [T]()
    private var labels = [String]()
    private var icons = [UIImage]()
    private(set) var stateIndex = 0
    private var onChange: ((_ value: T) -> Void)? = nil
    private var foregroundColor = FamColors.textSecondaryComponent
    public var view: UIView {
        return self.container.view
    }
    public var activeValue: T {
        return self.values[self.stateIndex]
    }
    private var activeLabel: String? {
        guard self.labels.count - 1 >= self.stateIndex else {
            return nil
        }
        return self.labels[self.stateIndex]
    }
    private var activeIcon: UIImage? {
        guard self.icons.count - 1 >= self.stateIndex else {
            return nil
        }
        return self.icons[self.stateIndex]
    }
    
    override init() {
        super.init()
        
        self.container
            .setHeightConstraint(to: FamDimensions.chipHeight)
            .setBackgroundColor(to: FamColors.secondaryComponentFill)
            .setCornerRadius(to: FamDimensions.foregroundCornerRadius)
            .addSubview(self.contentStack)
            .addSubview(self.button)
        
        self.contentStack
            .constrainVertical()
            .constrainHorizontal(padding: FamDimensions.chipPaddingHorizontal)
            .setSpacing(to: 10)
            .addView(self.imageView)
            .addView(self.label)
        
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
            .setWidthConstraint(to: 30)
            .setColor(to: FamColors.textSecondaryComponent)
        
        self.label
            .setFont(to: FamFont(font: FamFonts.Quicksand.SemiBold, size: 20))
            .setTextAlignment(to: .center)
    }
    
    private func refresh() {
        if let icon = self.activeIcon {
            self.imageView.setImage(icon)
        }
        if let label = self.activeLabel {
            self.label.setText(to: label)
        }
        self.imageView.setColor(to: self.foregroundColor)
        self.label.setTextColor(to: self.foregroundColor)
    }
    
    @discardableResult
    func setFixedWidth(width: Double) -> Self {
        self.container.setWidthConstraint(to: width)
        self.contentStack.view.removeConstraints(self.contentStack.view.constraints)
        self.contentStack.constrainVertical()
        return self
    }
    
    @discardableResult
    func setState(state: Int, trigger: Bool = false) -> Self {
        self.stateIndex = state
        self.refresh()
        if trigger {
            self.onChange?(self.activeValue)
        }
        return self
    }
    
    @discardableResult
    func addState(value: T, label: String? = nil, icon: String? = nil) -> Self {
        assert(!(label == nil && icon == nil), "Label and icon can't simultaneously be nil for this")
        self.values.append(value)
        if let label {
            self.labels.append(label)
        }
        if let icon {
            if let image = UIImage(named: icon) {
                self.icons.append(image)
            } else if let image = UIImage(systemName: icon) {
                self.icons.append(image)
            } else {
                assertionFailure("Invalid icon provided")
                self.icons.append(UIImage(systemName: "questionmark.circle.fill")!)
            }
        }
        // If we've added state but there's no labels/icons, we assume there are none to come
        if self.labels.isEmpty {
            self.label.removeFromSuperView()
        }
        if self.icons.isEmpty {
            self.imageView.removeFromSuperView()
        }
        self.refresh()
        return self
    }
    
    @discardableResult
    func setColor(to color: UIColor) -> Self {
        self.container.setBackgroundColor(to: color)
        return self
    }
    
    @discardableResult
    func setForegroundColor(to color: UIColor) -> Self {
        self.foregroundColor = color
        self.refresh()
        return self
    }
    
    @discardableResult
    func setOnChange(_ callback: ((_ value: T) -> Void)?) -> Self {
        self.onChange = callback
        return self
    }
    
    private func onTapCallback() {
        self.stateIndex = (self.stateIndex + 1)%self.values.count
        self.refresh()
        self.onChange?(self.activeValue)
    }
    
}

