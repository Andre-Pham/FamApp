//
//  FamContextMenuView.swift
//  Fam
//
//  Created by Andre Pham on 9/3/2024.
//

import Foundation
import UIKit

class FamContextMenuView: FamUIView {
    
    public let view: UIView
    
    override init() {
        self.view = ContextMenuUIView()
        super.init()
        self.view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    @discardableResult
    func setMenu(to menu: UIMenu?) -> Self {
        (self.view as! ContextMenuUIView).menu = menu
        return self
    }
    
    @discardableResult
    func setOnContextMenuActivation(_ callback: ((_ interaction: UIContextMenuInteraction, _ location: CGPoint) -> Void)?) -> Self {
        (self.view as! ContextMenuUIView).onContextMenuActivation = callback
        return self
    }
    
    @discardableResult
    func setOnContextMenuEnd(_ callback: ((_ interaction: UIContextMenuInteraction, _ configuration: UIContextMenuConfiguration, _ animator: UIContextMenuInteractionAnimating?) -> Void)?) -> Self {
        (self.view as! ContextMenuUIView).onContextMenuEnd = callback
        return self
    }
    
}

fileprivate class ContextMenuUIView: UIView, UIContextMenuInteractionDelegate {
    
    public var menu: UIMenu? = nil
    public var onContextMenuActivation: ((_ interaction: UIContextMenuInteraction, _ location: CGPoint) -> Void)? = nil
    public var onContextMenuEnd: ((_ interaction: UIContextMenuInteraction, _ configuration: UIContextMenuConfiguration, _ animator: UIContextMenuInteractionAnimating?) -> Void)? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let interaction = UIContextMenuInteraction(delegate: self)
        self.addInteraction(interaction)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard self.menu != nil else {
            return nil
        }
        self.onContextMenuActivation?(interaction, location)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions -> UIMenu? in
            self.menu
        }
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        self.onContextMenuEnd?(interaction, configuration, animator)
    }
    
}

