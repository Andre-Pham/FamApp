//
//  FamTextField.swift
//  Fam
//
//  Created by Andre Pham on 4/8/2023.
//

import Foundation
import UIKit

class FamTextField: FamView {
    
    private let textInput = TextField()
    private var onSubmit: (() -> Void)? = nil
    private var onFocus: (() -> Void)? = nil
    private var onUnfocus: (() -> Void)? = nil
    public var text: String {
        return self.textInput.text ?? ""
    }
    
    override func setup() {
        super.setup()
        self.add(self.textInput)
        self.textInput
            .useAutoLayout()
            .constrainAllSides(respectSafeArea: false)
        self.setFont(to: FamFont(font: FamFonts.Poppins.Medium, size: 18))
        self.setTextColor(to: FamColors.textDark1)
        self.setBackgroundColor(to: FamColors.secondaryComponentFill)
        self.setCornerRadius(to: FamDimensions.foregroundCornerRadius)
        self.setHeightConstraint(to: 48)
        self.textInput.addTarget(self, action: #selector(self.handleSubmit), for: .editingDidEndOnExit)
        NotificationCenter.default.addObserver(self, selector: #selector(self.textFieldDidBeginEditing), name: UITextField.textDidBeginEditingNotification, object: self.textInput)
        NotificationCenter.default.addObserver(self, selector: #selector(self.textFieldDidEndEditing), name: UITextField.textDidEndEditingNotification, object: self.textInput)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    @objc private func handleSubmit() {
        self.onSubmit?()
    }
    
    @objc private func textFieldDidBeginEditing(notification: NSNotification) {
        self.onFocus?()
    }

    @objc private func textFieldDidEndEditing(notification: NSNotification) {
        self.onUnfocus?()
    }
    
}

fileprivate class TextField: UITextField {
    
    private let padding = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: self.padding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: self.padding)
    }
    
}
