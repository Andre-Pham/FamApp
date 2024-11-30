//
//  PreviewContentView.swift
//  yonder
//
//  Created by Andre Pham on 17/7/2022.
//

import Foundation
import UIKit

class PreviewContentView: FamView {
    
    public enum PreviewMode {
        case horizontal
        case vertical
        case full
        case center
    }
    
    private var preview: UIView?
    
    override func setup() {
        super.setup()
        
        self.setBackgroundColor(to: FamColors.black)
    }
    
    @discardableResult
    func preview(_ view: UIView, mode: PreviewMode = .center) -> Self {
        self.preview = view
        self.add(view)
        switch mode {
        case .horizontal:
            view
                .constrainHorizontal(padding: 50)
                .constrainCenterVertical()
        case .vertical:
            view
                .constrainVertical(padding: 50)
                .constrainCenterHorizontal()
        case .center:
            view
                .constrainCenter()
        case .full:
            view
                .constrainVertical(padding: 50)
                .constrainHorizontal(padding: 50)
        }
        
        return self
    }
    
}

#Preview("Center mode") {
    let demoView = FamView()
        .setHeightConstraint(to: 100)
        .setWidthConstraint(to: 100)
        .setBackgroundColor(to: .red)
    return PreviewContentView()
        .preview(demoView, mode: .center)
}

#Preview("Horizontal mode") {
    let demoView = FamView()
        .setHeightConstraint(to: 100)
        .setBackgroundColor(to: .red)
    return PreviewContentView()
        .preview(demoView, mode: .horizontal)
}

#Preview("Vertical mode") {
    let demoView = FamView()
        .setWidthConstraint(to: 100)
        .setBackgroundColor(to: .red)
    return PreviewContentView()
        .preview(demoView, mode: .vertical)
}

#Preview("Full mode") {
    let demoView = FamView()
        .setBackgroundColor(to: .red)
    return PreviewContentView()
        .preview(demoView, mode: .full)
}
