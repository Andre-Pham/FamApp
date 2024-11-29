//
//  FamClearableTextField.swift
//  Fam
//
//  Created by Andre Pham on 29/3/2024.
//

import Foundation
import UIKit

class FamClearableTextField: FamView {
    
    private static let CLEAR_BUTTON_SIZE_FRACTION = 0.56
    private static let CLEAR_BUTTON_ICON_SIZE_FRACTION = 0.56
    private static let TEXT_INPUT_HEIGHT = 48.0
    
    private let stack = FamHStack()
    private let textInput = TextField()
    private let textClearControl = FamControl()
    private let textClearCircle = FamView()
    private let textClearIcon = FamIcon()
    private var onSubmit: (() -> Void)? = nil
    private var onFocus: (() -> Void)? = nil
    private var onUnfocus: (() -> Void)? = nil
    public var text: String {
        return self.textInput.text ?? ""
    }
    
    override func setup() {
        super.setup()
        self.add(self.stack)
        
        self.stack
            .constrainAllSides(respectSafeArea: false)
            .setBackgroundColor(to: FamColors.secondaryComponentFill)
            .setCornerRadius(to: FamDimensions.foregroundCornerRadius)
            .append(self.textInput)
            .append(self.textClearControl)
        
        self.textInput
            .useAutoLayout()
            .setHeightConstraint(to: Self.TEXT_INPUT_HEIGHT)
        
        self.textClearControl
            .setHeightConstraint(to: Self.TEXT_INPUT_HEIGHT)
            .setWidthConstraint(to: Self.TEXT_INPUT_HEIGHT)
            .add(self.textClearCircle)
            .add(self.textClearIcon)
            .setOnRelease({
                self.setText(to: nil)
                self.textInput.becomeFirstResponder()
            })
        
        self.textClearCircle
            .constrainCenter(respectSafeArea: false)
            .setWidthConstraint(to: Self.TEXT_INPUT_HEIGHT*Self.CLEAR_BUTTON_SIZE_FRACTION)
            .setHeightConstraint(to: Self.TEXT_INPUT_HEIGHT*Self.CLEAR_BUTTON_SIZE_FRACTION)
            .setCornerRadius(to: Self.TEXT_INPUT_HEIGHT*Self.CLEAR_BUTTON_SIZE_FRACTION/2.0)
            .setOpacity(to: 0.8) // Not too much contrast desired
            .setBackgroundColor(to: FamColors.textDark3)
            .setInteractions(enabled: false)
        
        self.textClearIcon
            .setSymbol(systemName: "xmark")
            .setWeight(to: .black)
            .constrainCenter(respectSafeArea: false)
            .setSize(to: Self.TEXT_INPUT_HEIGHT*Self.CLEAR_BUTTON_SIZE_FRACTION*Self.CLEAR_BUTTON_ICON_SIZE_FRACTION)
            .setColor(to: FamColors.secondaryComponentFill)
        
        self
            .setFont(to: FamFont(font: FamFonts.Poppins.Medium, size: 18))
            .setTextColor(to: FamColors.textDark1)
        
        self.textInput.addTarget(self, action: #selector(self.handleSubmit), for: .editingDidEndOnExit)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.textFieldDidBeginEditing), name: UITextField.textDidBeginEditingNotification, object: self.textInput)
        NotificationCenter.default.addObserver(self, selector: #selector(self.textFieldDidEndEditing), name: UITextField.textDidEndEditingNotification, object: self.textInput)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleSubmit() {
        self.onSubmit?()
    }
    
    @objc private func textFieldDidBeginEditing(notification: NSNotification) {
        self.onFocus?()
    }

    @objc private func textFieldDidEndEditing(notification: NSNotification) {
        self.onUnfocus?()
    }
    
    @discardableResult
    func setOnSubmit(_ callback: (() -> Void)?) -> Self {
        self.onSubmit = callback
        return self
    }
    
    @discardableResult
    func setOnFocus(_ callback: (() -> Void)?) -> Self {
        self.onFocus = callback
        return self
    }
    
    @discardableResult
    func setOnUnfocus(_ callback: (() -> Void)?) -> Self {
        self.onUnfocus = callback
        return self
    }
    
    @discardableResult
    func setSubmitLabel(to label: UIReturnKeyType) -> Self {
        self.textInput.returnKeyType = label
        return self
    }
    
    @discardableResult
    func setPlaceholder(to text: String?) -> Self {
        self.textInput.placeholder = text
        return self
    }
    
    @discardableResult
    func setText(to text: String?) -> Self {
        self.textInput.text = text
        return self
    }
    
    @discardableResult
    func setTextColor(to color: UIColor) -> Self {
        self.textInput.textColor = color
        return self
    }
    
    @discardableResult
    func setFont(to font: UIFont?) -> Self {
        self.textInput.font = font
        return self
    }
    
    @discardableResult
    func setSize(to size: CGFloat) -> Self {
        self.textInput.font = self.textInput.font?.withSize(size)
        return self
    }
    
    @discardableResult
    func setTextAlignment(to alignment: NSTextAlignment) -> Self {
        self.textInput.textAlignment = alignment
        return self
    }
    
}

fileprivate class TextField: UITextField {
    
    private let padding = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: self.padding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: self.padding)
    }
    
}
