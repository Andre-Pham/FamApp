//
//  FamGesture.swift
//  Fam
//
//  Created by Andre Pham on 5/8/2023.
//

import Foundation
import UIKit

class FamGesture: FamView {
    
    private var onGesture: ((_ gesture: UIPanGestureRecognizer) -> Void)? = nil
    
    override func setup() {
        super.setup()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(_:)))
        self.addGestureRecognizer(panGesture)
    }
    
    @discardableResult
    func setOnGesture(_ callback: ((_ gesture: UIPanGestureRecognizer) -> Void)?) -> Self {
        self.onGesture = callback
        return self
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        self.onGesture?(gesture)
    }
    
}
