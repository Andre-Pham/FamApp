//
//  FamText.swift
//  Fam
//
//  Created by Andre Pham on 8/3/2024.
//

import Foundation
import UIKit

class FamText: FamUIView {
    
    private let label = UILabel()
    public var view: UIView {
        return self.label
    }
    public var text: String {
        return self.label.text ?? ""
    }
    public var font: UIFont {
        return self.label.font
    }
    public var intrinsicContentSize: CGSize {
        return self.label.intrinsicContentSize
    }
    
    override init() {
        super.init()
        self.view.translatesAutoresizingMaskIntoConstraints = true
        self.toggleWordWrapping(to: true)
        self.setText(to: text)
        self.setFont(to: UIFont.boldSystemFont(ofSize: 13.0))
        self.setTextColor(to: FamColors.textDark1)
    }
    
    @discardableResult
    func setText(to text: String?) -> Self {
        self.label.text = text
        return self
    }
    
    @discardableResult
    func toggleWordWrapping(to status: Bool) -> Self {
        if status {
            self.label.numberOfLines = 0
            self.label.lineBreakMode = .byWordWrapping
        } else {
            // Defaults
            self.label.numberOfLines = 1
            self.label.lineBreakMode = .byTruncatingTail
        }
        return self
    }
    
    @discardableResult
    func setFont(to font: UIFont?) -> Self {
        self.label.font = font
        return self
    }
    
    @discardableResult
    func setSize(to size: CGFloat) -> Self {
        self.label.font = self.label.font.withSize(size)
        return self
    }
    
    @discardableResult
    func setTextAlignment(to alignment: NSTextAlignment) -> Self {
        self.label.textAlignment = alignment
        return self
    }
    
    @discardableResult
    func setTextColor(to color: UIColor) -> Self {
        self.label.textColor = color
        return self
    }
    
    @discardableResult
    func setTextOpacity(to opacity: Double) -> Self {
        self.label.textColor = self.label.textColor.withAlphaComponent(opacity)
        return self
    }
    
}
