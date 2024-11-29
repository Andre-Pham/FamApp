//
//  FamView.swift
//  Fam
//
//  Created by Andre Pham on 14/6/2023.
//

import Foundation
import UIKit

class FamView: UIView {
    
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
    }
    
}
