//
//  FamView.swift
//  Fam
//
//  Created by Andre Pham on 8/3/2024.
//

import Foundation
import UIKit

class FamView: FamUIView {
    
    public let view: UIView
    
    override init() {
        self.view = UIView()
        super.init()
        self.view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    init(_ view: UIView) {
        self.view = view
    }
    
}
