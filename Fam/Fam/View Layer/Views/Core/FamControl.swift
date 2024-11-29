//
//  FamControl.swift
//  Fam
//
//  Created by Andre Pham on 4/8/2023.
//

import Foundation
import UIKit

class FamControl: UIControl {
    
    private var onPress: (() -> Void)? = nil
    private var onRelease: (() -> Void)? = nil
    public var isDisabled: Bool {
        return !self.isEnabled
    }
    
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
        self.addTarget(self, action: #selector(self.onPressCallback), for: .touchDown)
        self.addTarget(self, action: #selector(self.onReleaseCallback), for: [.touchUpInside, .touchUpOutside])
    }
    
    @discardableResult
    func setOnPress(_ callback: (() -> Void)?) -> Self {
        self.onPress = callback
        return self
    }
    
    @discardableResult
    func setOnRelease(_ callback: (() -> Void)?) -> Self {
        self.onRelease = callback
        return self
    }
    
    @discardableResult
    func setDisabled(to state: Bool) -> Self {
        self.isEnabled = !state
        return self
    }
    
    @objc private func onPressCallback() {
        self.onPress?()
    }
    
    @objc private func onReleaseCallback() {
        self.onRelease?()
    }
    
}
