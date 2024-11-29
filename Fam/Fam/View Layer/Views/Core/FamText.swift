//
//  FamText.swift
//  Fam
//
//  Created by Andre Pham on 14/6/2023.
//

import Foundation

import Foundation
import UIKit

class FamText: UILabel {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    func setup() {
        self.useAutoLayout()
            .toggleWordWrapping(to: true)
            .setFont(to: UIFont.boldSystemFont(ofSize: 13.0))
            .setTextColor(to: FamColors.textDark1)
    }
    
    @discardableResult
    func setText(to text: String?) -> Self {
        self.text = text
        return self
    }
    
    @discardableResult
    func toggleWordWrapping(to status: Bool) -> Self {
        if status {
            self.numberOfLines = 0
            self.lineBreakMode = .byWordWrapping
        } else {
            // Defaults
            self.numberOfLines = 1
            self.lineBreakMode = .byTruncatingTail
        }
        return self
    }
    
    @discardableResult
    func setFont(to font: UIFont?) -> Self {
        self.font = font
        return self
    }
    
    @discardableResult
    func setSize(to size: CGFloat) -> Self {
        self.font = self.font.withSize(size)
        return self
    }
    
    @discardableResult
    func setTextAlignment(to alignment: NSTextAlignment) -> Self {
        self.textAlignment = alignment
        return self
    }
    
    @discardableResult
    func setTextColor(to color: UIColor) -> Self {
        self.textColor = color
        return self
    }
    
    @discardableResult
    func setTextOpacity(to opacity: Double) -> Self {
        self.textColor = self.textColor.withAlphaComponent(opacity)
        return self
    }
    
}
