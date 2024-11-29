//
//  FamChipMultiState.swift
//  Fam
//
//  Created by Andre Pham on 5/8/2023.
//

import Foundation
import UIKit

class FamChipMultiState<T: Any>: FamView {
    
    private let button = FamControl()
    private let contentStack = FamHStack()
    private let icon = FamIcon()
    public let label = FamText()
    private(set) var values = [T]()
    private var labels = [String]()
    private var iconConfigs = [FamIcon.Config]()
    private(set) var stateIndex = 0
    private var onChange: ((_ value: T) -> Void)? = nil
    private var foregroundColor = FamColors.textSecondaryComponent
    public var activeValue: T {
        return self.values[self.stateIndex]
    }
    private var activeLabel: String? {
        guard self.labels.count - 1 >= self.stateIndex else {
            return nil
        }
        return self.labels[self.stateIndex]
    }
    private var activeIconConfig: FamIcon.Config? {
        guard self.iconConfigs.count - 1 >= self.stateIndex else {
            return nil
        }
        return self.iconConfigs[self.stateIndex]
    }
    
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
                self.onTapCallback()
                self.animateReleaseOpacity()
            })
        
        self.label
            .setFont(to: FamFont(font: FamFonts.Quicksand.SemiBold, size: 20))
            .setTextAlignment(to: .center)
    }
    
    private func refresh() {
        if let config = self.activeIconConfig {
            self.icon.setIcon(to: config)
        }
        if let label = self.activeLabel {
            self.label.setText(to: label)
        }
        if self.activeIconConfig?.color == nil {
            // Only match the icon's color to the foreground color if it isn't already explicitly set
            self.icon.setColor(to: self.foregroundColor)
        }
        self.label.setTextColor(to: self.foregroundColor)
    }
    
    @discardableResult
    func setFixedWidth(width: Double) -> Self {
        self.setWidthConstraint(to: width)
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
    func addState(value: T, label: String? = nil, iconConfig: FamIcon.Config? = nil) -> Self {
        assert(!(label == nil && iconConfig == nil), "Label and icon can't simultaneously be nil for this")
        self.values.append(value)
        if let label {
            self.labels.append(label)
        }
        if let iconConfig {
            self.iconConfigs.append(iconConfig)
        }
        // If we've added state but there's no labels/icons, we assume there are none to come
        if self.labels.isEmpty {
            self.label.remove()
        }
        if self.iconConfigs.isEmpty {
            self.icon.remove()
        }
        self.refresh()
        return self
    }
    
    @discardableResult
    func setColor(to color: UIColor) -> Self {
        self.setBackgroundColor(to: color)
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

