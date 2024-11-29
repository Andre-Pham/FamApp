//
//  FamScroll.swift
//  Fam
//
//  Created by Andre Pham on 2/2/2024.
//

import Foundation
import UIKit

class FamScroll: FamView {
    
    private let scrollView = UIScrollView()
    public var viewCount: Int {
        return self.scrollView.subviews.count
    }
    
    override func setup() {
        super.setup()
        self.add(self.scrollView)
        self.scrollView
            .useAutoLayout()
            .constrainAllSides(respectSafeArea: false)
    }
    
    @discardableResult
    func append(_ view: UIView, animated: Bool = false) -> Self {
        if animated {
            view.setOpacity(to: 0.0)
            view.setHidden(to: true)
            self.scrollView.add(view)
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 2, options: [.curveEaseOut], animations: {
                view.setOpacity(to: 1.0)
                view.setHidden(to: false)
            })
        } else {
            self.scrollView.add(view)
        }
        return self
    }
    
    @discardableResult
    func insert(_ view: UIView, at position: Int, animated: Bool = false) -> Self {
        let validatedPosition = min(position, self.viewCount)
        if animated {
            view.setOpacity(to: 0.0)
            view.setHidden(to: true)
            self.scrollView.insertSubview(view, at: validatedPosition)
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 2, options: [.curveEaseOut], animations: {
                view.setOpacity(to: 1.0)
                view.setHidden(to: false)
            })
        } else {
            self.scrollView.insertSubview(view, at: validatedPosition)
        }
        return self
    }
    
    @discardableResult
    func appendGap(size: Double, animated: Bool = false) -> Self {
        let gapView = FamView().setHeightConstraint(to: size)
        return self.append(gapView, animated: animated)
    }
    
    @discardableResult
    func insertGap(size: Double, at position: Int, animated: Bool = false) -> Self {
        let gapView = FamView().setHeightConstraint(to: size)
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
        let view = self.scrollView.subviews[position]
        return self.removeAnimated(view)
    }
    
    @discardableResult
    func setVerticalBounce(to state: Bool) -> Self {
        self.scrollView.alwaysBounceVertical = state
        return self
    }
    
    @discardableResult
    func setHorizontalBounce(to state: Bool) -> Self {
        self.scrollView.alwaysBounceHorizontal = state
        return self
    }
    
    @discardableResult
    func scrollToBottom() -> Self {
        let bottomOffset = CGPoint(
            x: 0,
            y: self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.scrollView.contentInset.bottom
        )
        if bottomOffset.y > 0 {
            self.scrollView.setContentOffset(bottomOffset, animated: false)
        }
        return self
    }
    
    @discardableResult
    func scrollToBottomAnimated(withEasing easingOption: UIView.AnimationOptions = .curveEaseInOut, duration: Double = 0.3) -> Self {
        let bottomOffset = CGPoint(
            x: 0,
            y: scrollView.contentSize.height - scrollView.bounds.size.height + scrollView.contentInset.bottom
        )
        if bottomOffset.y > 0 {
            UIView.animate(withDuration: duration, delay: 0, options: easingOption, animations: {
                self.scrollView.contentOffset = bottomOffset
            }, completion: nil)
        }
        return self
    }
    
}
