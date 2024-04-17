//
//  FamLabelledTextInput.swift
//  Fam
//
//  Created by Andre Pham on 8/3/2024.
//

import Foundation
import UIKit

class FamLabelledTextInput: FamUIView {
    
    private let label = FamText()
    private let stack = FamVStack()
    private let textInput = PaddedTextField()
    private var onSubmit: (() -> Void)? = nil
    private var onEdit: (() -> Void)? = nil
    private var onFocus: (() -> Void)? = nil
    private var onUnfocus: (() -> Void)? = nil
    public var view: UIView {
        return self.stack.view
    }
    public var text: String {
        return self.textInput.text ?? ""
    }
    
    override init() {
        super.init()
        self.textInput.translatesAutoresizingMaskIntoConstraints = false
        self.setFont(to: FamFont(font: FamFonts.Poppins.Medium, size: 16))
        self.setTextColor(to: FamColors.textDark1)
        self.setCornerRadius(to: 12)
        self.setBackgroundColor(to: FamColors.secondaryComponentFill)
        self.setHeightConstraint(to: 72)
        
        self.stack
            .addGap(size: 12)
            .addView(self.label)
            .addSpacer()
            .addView(FamView(self.textInput))
            .addGap(size: 12)
        
        FamView(self.textInput)
            .constrainHorizontal()
        
        self.label
            .constrainHorizontal(padding: 14)
            .setFont(to: FamFont(font: FamFonts.Poppins.Medium, size: 14))
            .setTextColor(to: FamColors.textDark3)
        
        self.textInput.addTarget(self, action: #selector(self.handleSubmit), for: .editingDidEndOnExit)
        self.textInput.addTarget(self, action: #selector(self.handleEdit), for: .editingChanged)
        NotificationCenter.default.addObserver(self, selector: #selector(self.textFieldDidBeginEditing), name: UITextField.textDidBeginEditingNotification, object: self.textInput)
        NotificationCenter.default.addObserver(self, selector: #selector(self.textFieldDidEndEditing), name: UITextField.textDidEndEditingNotification, object: self.textInput)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onTap))
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func onTap() {
        self.textInput.becomeFirstResponder()
    }
    
    @objc private func handleSubmit() {
        self.onSubmit?()
    }
    
    @objc private func handleEdit() {
        self.onEdit?()
    }
    
    @objc func textFieldDidBeginEditing(notification: NSNotification) {
        self.stack.addBorder(width: 2.0, color: FamColors.textDark1)
        self.onFocus?()
    }

    @objc func textFieldDidEndEditing(notification: NSNotification) {
        self.stack.removeBorder()
        self.onUnfocus?()
    }
    
    @discardableResult
    func setOnSubmit(_ callback: (() -> Void)?) -> Self {
        self.onSubmit = callback
        return self
    }
    
    @discardableResult
    func setOnEdit(_ callback: (() -> Void)?) -> Self {
        self.onEdit = callback
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
    
    @discardableResult
    func setLabel(to label: String) -> Self {
        self.label.setText(to: label)
        return self
    }
    
}

fileprivate class PaddedTextField: UITextField {
    
    private let padding = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: self.padding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: self.padding)
    }
    
}
