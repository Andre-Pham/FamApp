//
//  FamHStack.swift
//  Fam
//
//  Created by Andre Pham on 30/6/2023.
//

import Foundation
import UIKit

class FamHStack: FamView {
    
    private let stack = UIStackView()
    public var viewCount: Int {
        return self.stack.arrangedSubviews.count
    }
    private var horizontalSpacer: UIView {
        let spacerView = UIView()
        spacerView.useAutoLayout()
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return spacerView
    }
    
    override func setup() {
        super.setup()
        self.add(self.stack)
        self.stack
            .useAutoLayout()
            .constrainAllSides(respectSafeArea: false)
        self.stack.axis = .horizontal
        self.stack.alignment = .center
        self.stack.isLayoutMarginsRelativeArrangement = false
    }
    
    @discardableResult
    func append(_ view: UIView, animated: Bool = false) -> Self {
        if animated {
            view.setOpacity(to: 0.0)
            view.setHidden(to: true)
            self.stack.addArrangedSubview(view)
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 2, options: [.curveEaseOut], animations: {
                view.setOpacity(to: 1.0)
                view.setHidden(to: false)
            })
        } else {
            self.stack.addArrangedSubview(view)
        }
        return self
    }
    
    @discardableResult
    func insert(_ view: UIView, at position: Int, animated: Bool = false) -> Self {
        let validatedPosition = min(position, self.stack.arrangedSubviews.count)
        if animated {
            view.setOpacity(to: 0.0)
            view.setHidden(to: true)
            self.stack.insertArrangedSubview(view, at: validatedPosition)
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 2, options: [.curveEaseOut], animations: {
                view.setOpacity(to: 1.0)
                view.setHidden(to: false)
            })
        } else {
            self.stack.insertArrangedSubview(view, at: validatedPosition)
        }
        return self
    }
    
    @discardableResult
    func appendSpacer(animated: Bool = false) -> Self {
        return self.append(self.horizontalSpacer, animated: animated)
    }
    
    @discardableResult
    func insertSpacer(at position: Int, animated: Bool = false) -> Self {
        return self.insert(self.horizontalSpacer, at: position, animated: animated)
    }
    
    @discardableResult
    func appendGap(size: Double, animated: Bool = false) -> Self {
        let gapView = FamView().setWidthConstraint(to: size)
        return self.append(gapView, animated: animated)
    }
    
    @discardableResult
    func insertGap(size: Double, at position: Int, animated: Bool = false) -> Self {
        let gapView = FamView().setWidthConstraint(to: size)
        return self.insert(gapView, at: position, animated: animated)
    }
  
    @discardableResult
    func removeAnimated(_ view: UIView) -> Self {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 2, options: [.curveEaseOut], animations: {
            view.setOpacity(to: 0.0)
            view.setHidden(to: true)
        }) { _ in
            view.remove()
            view.setOpacity(to: 1.0)
            view.setHidden(to: false)
        }
        return self
    }
    
    @discardableResult
    func removeAnimated(position: Int) -> Self {
        guard position >= 0, self.viewCount > position else {
            return self
        }
        let view = self.stack.arrangedSubviews[position]
        return self.removeAnimated(view)
    }
    
    @discardableResult
    func setSpacing(to spacing: CGFloat) -> Self {
        self.stack.spacing = spacing
        return self
    }
    
    @discardableResult
    func setDistribution(to distribution: UIStackView.Distribution) -> Self {
        self.stack.distribution = distribution
        return self
    }
    
    @discardableResult
    func setAlignment(to alignment: UIStackView.Alignment) -> Self {
        self.stack.alignment = alignment
        return self
    }
    
}
