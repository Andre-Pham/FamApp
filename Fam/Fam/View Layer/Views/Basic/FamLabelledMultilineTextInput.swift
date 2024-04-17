//
//  FamLabelledMultilineTextInput.swift
//  Fam
//
//  Created by Andre Pham on 11/3/2024.
//

import Foundation
import UIKit

class FamLabelledMultilineTextInput: FamUIView {
    
    private let label = FamText()
    private let stack = FamVStack()
    private let textInput = PaddedTextView()
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
        self.setHeightConstraint(to: 120)
        
        self.stack
            .addGap(size: 12)
            .addView(self.label)
            .addGap(size: 2)
            .addSpacer()
            .addView(FamView(self.textInput))
            .addGap(size: 12)
        
        FamView(self.textInput)
            .constrainHorizontal()
            .setBackgroundColor(to: FamColors.secondaryComponentFill)
        
        self.label
            .constrainHorizontal(padding: 14)
            .setFont(to: FamFont(font: FamFonts.Poppins.Medium, size: 14))
            .setTextColor(to: FamColors.textDark3)
        
        self.textInput.onEdit = {
            self.onEdit?()
        }
        self.textInput.onFocus = {
            self.stack.addBorder(width: 2.0, color: FamColors.textDark1)
            self.onFocus?()
        }
        self.textInput.onUnfocus = {
            self.stack.removeBorder()
            self.onUnfocus?()
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onTap))
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func onTap() {
        self.textInput.becomeFirstResponder()
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

fileprivate class PaddedTextView: UITextView, UITextViewDelegate {
    
    let padding = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
    public var onFocus: (() -> Void)? = nil
    public var onUnfocus: (() -> Void)? = nil
    public var onEdit: (() -> Void)? = nil

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.textContainerInset = padding
        self.textContainer.lineFragmentPadding = 0
        self.delegate = self
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.onFocus?()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        self.onUnfocus?()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.onEdit?()
    }
    
}
