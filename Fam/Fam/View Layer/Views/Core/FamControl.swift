//
//  FamControl.swift
//  Fam
//
//  Created by Andre Pham on 8/3/2024.
//

import Foundation
import UIKit

class FamControl: FamUIView {
    
    private let control = UIControl()
    private var onPress: (() -> Void)? = nil
    private var onRelease: (() -> Void)? = nil
    public var isDisabled: Bool {
        return !self.control.isEnabled
    }
    public var view: UIView {
        return self.control
    }
    
    override init() {
        super.init()
        
        self.control.addTarget(self, action: #selector(self.onPressCallback), for: .touchDown)
        self.control.addTarget(self, action: #selector(self.onReleaseCallback), for: [.touchUpInside, .touchUpOutside])
        self.control.translatesAutoresizingMaskIntoConstraints = false
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
        self.control.isEnabled = !state
        return self
    }
    
    @objc private func onPressCallback() {
        self.onPress?()
    }
    
    @objc private func onReleaseCallback() {
        self.onRelease?()
    }
    
}
