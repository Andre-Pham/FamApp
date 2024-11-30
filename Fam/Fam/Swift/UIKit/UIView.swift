//
//  UIView.swift
//  Fam
//
//  Created by Andre Pham on 30/11/2024.
//

import Foundation
import UIKit

extension UIView {
    
    public var opacity: Double {
        return self.alpha
    }
    
    public var layerOpacity: Double {
        return Double(self.layer.opacity)
    }
    
    /// The existing size of the view. Subclasses override this method to return a custom value based on the desired layout of any subviews.
    /// For example, UITextView returns the view size of its text, and UIImageView returns the size of the image it is currently displaying.
    public var contentBasedSize: CGSize {
        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        return self.sizeThatFits(maxSize)
    }
    
    public var widthConstraintConstant: Double {
        self.layoutIfNeeded()
        return self.frame.width
    }
    
    public var heightConstraintConstant: Double {
        self.layoutIfNeeded()
        return self.frame.height
    }
    
    public var hasSuperView: Bool {
        return self.superview != nil
    }
    
    // MARK: - Views
    
    @discardableResult
    func add(_ subview: UIView) -> Self {
        self.addSubview(subview)
        return self
    }
    
    @discardableResult
    func add(_ layer: CALayer) -> Self {
        self.layer.addSublayer(layer)
        return self
    }
    
    @discardableResult
    func remove() -> Self {
        self.removeFromSuperview()
        return self
    }
    
    @discardableResult
    func removeSubviewsAndLayers() -> Self {
        self.subviews.forEach({ $0.remove() })
        self.layer.sublayers?.forEach({ $0.removeFromSuperlayer() })
        return self
    }
    
    @discardableResult
    func renderToUIImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        self.layer.render(in: context)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return image
    }
    
    /// Checks if this view is within another view's hierarchy of views.
    /// It iterates over the chain of superviews until it matches the target view or there are no more super views to check.
    /// - Parameters:
    ///   - target: The view who's hierarchy is being checked to contain this view
    /// - Returns: True if the target view's tree of subviews contains this view
    func existsWithinHierarchy(of target: UIView) -> Bool {
        var viewToCheck: UIView? = self
        while let view = viewToCheck {
            if view === target {
                return true
            }
            viewToCheck = view.superview
        }
        return false
    }
    
    // MARK: - Frame
    
    @discardableResult
    func useAutoLayout() -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        return self
    }
    
    @discardableResult
    func disableAutoLayout() -> Self {
        self.translatesAutoresizingMaskIntoConstraints = true
        return self
    }
    
    @discardableResult
    func setFrame(to rect: CGRect) -> Self {
        self.frame = rect
        return self
    }
    
    @discardableResult
    func layoutIfNeededAnimated(withDuration: Double = 0.3) -> Self {
        UIView.animate(withDuration: withDuration, animations: {
            self.layoutIfNeeded()
        })
        return self
    }
    
    /// Adjusts a view's frame to be fully inside the screen's window bounds (assuming it's partially or fully off-screen)
    /// - Parameters:
    ///   - animationDuration: The animation duration for moving the view, or `nil` for no animation
    ///   - padding: The padding away from the screen's edges
    ///   - inset: The amount of inset for the screen's edges, e.g. 10 would treat the screen's width to be 20 less
    /// - Returns: An reference to the view's instance
    @discardableResult
    func reframeIntoWindow(animationDuration: Double? = nil, padding: Double = 0.0, inset: Double = 0.0) -> Self {
        guard let window = WindowContext.window else {
            print("Unable to find the key window.")
            return self
        }
        // Ensure the view's layout is up to date.
        self.superview?.layoutIfNeeded()
        // Convert the view's frame to the window's coordinate system to get its position relative to the screen.
        let viewFrameInWindow = self.convert(self.bounds, to: window)
        // Screen bounds considering the safe area.
        let safeAreaInsets = window.safeAreaInsets
        let screenBounds = window.bounds.inset(by: safeAreaInsets)
        var newFrame = self.frame
        // Check and adjust for the right edge.
        if viewFrameInWindow.maxX.isGreater(than: screenBounds.maxX - inset) {
            let offsetX = viewFrameInWindow.maxX - screenBounds.maxX
            newFrame.origin.x -= offsetX
            newFrame.origin.x -= padding
        }
        // Check and adjust for the bottom edge.
        if viewFrameInWindow.maxY.isGreater(than: screenBounds.maxY - inset) {
            let offsetY = viewFrameInWindow.maxY - screenBounds.maxY
            newFrame.origin.y -= offsetY
            newFrame.origin.y -= padding
        }
        // Check and adjust for the left edge.
        if viewFrameInWindow.minX.isLess(than: screenBounds.minX + inset) {
            let offsetX = screenBounds.minX - viewFrameInWindow.minX
            newFrame.origin.x += offsetX
            newFrame.origin.x += padding
        }
        // Check and adjust for the top edge.
        if viewFrameInWindow.minY.isLess(than: screenBounds.minY + inset) {
            let offsetY = screenBounds.minY - viewFrameInWindow.minY
            newFrame.origin.y += offsetY
            newFrame.origin.y += padding
        }
        if let animationDuration {
            UIView.animate(withDuration: animationDuration) {
                self.frame = newFrame
            }
        } else {
            self.frame = newFrame
        }
        return self
    }
    
    // MARK: - Constraints
    
    @discardableResult
    func matchWidthConstraint(to other: UIView? = nil, adjust: CGFloat = 0.0, respectSafeArea: Bool = true) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        guard let target = other ?? self.superview else {
            fatalError("No constraint target found")
        }
        let anchor = respectSafeArea ? target.safeAreaLayoutGuide.widthAnchor : target.widthAnchor
        self.widthAnchor.constraint(equalTo: anchor, constant: adjust).isActive = true
        return self
    }
    
    @discardableResult
    func matchHeightConstraint(to other: UIView? = nil, adjust: CGFloat = 0.0, respectSafeArea: Bool = true) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        guard let target = other ?? self.superview else {
            fatalError("No constraint target found")
        }
        let anchor = respectSafeArea ? target.safeAreaLayoutGuide.heightAnchor : target.heightAnchor
        self.heightAnchor.constraint(equalTo: anchor, constant: adjust).isActive = true
        return self
    }
    
    @discardableResult
    func setHeightConstraint(to height: Double) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        self.heightAnchor.constraint(equalToConstant: height).isActive = true
        return self
    }
    
    @discardableResult
    func setWidthConstraint(to width: Double) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        self.widthAnchor.constraint(equalToConstant: width).isActive = true
        return self
    }
    
    @discardableResult
    func setWidthConstraint(proportion: Double, useParentWidth: Bool = true) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        guard let parentView = self.superview else {
            fatalError("No constraint target found")
        }
        self.widthAnchor.constraint(
            equalTo: useParentWidth ? parentView.widthAnchor : parentView.heightAnchor,
            multiplier: proportion
        ).isActive = true
        return self
    }
    
    @discardableResult
    func setHeightConstraint(proportion: Double, useParentHeight: Bool = true) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        guard let parentView = self.superview else {
            fatalError("No constraint target found")
        }
        self.heightAnchor.constraint(
            equalTo: useParentHeight ? parentView.heightAnchor : parentView.widthAnchor,
            multiplier: proportion
        ).isActive = true
        return self
    }
    
    @discardableResult
    func setMaxHeightConstraint(to height: Double) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        self.heightAnchor.constraint(lessThanOrEqualToConstant: height).isActive = true
        return self
    }
    
    @discardableResult
    func setMaxWidthConstraint(to width: Double) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        self.widthAnchor.constraint(lessThanOrEqualToConstant: width).isActive = true
        return self
    }
    
    @discardableResult
    func constrainLeft(to other: UIView? = nil, padding: CGFloat = 0.0, respectSafeArea: Bool = true, toContentLayoutGuide: Bool = false) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        guard let target = other ?? self.superview else {
            fatalError("No constraint target found")
        }
        let anchor: NSLayoutXAxisAnchor
        if toContentLayoutGuide, let scrollView = target as? UIScrollView {
            anchor = scrollView.contentLayoutGuide.leadingAnchor
        } else {
            anchor = respectSafeArea ? target.safeAreaLayoutGuide.leadingAnchor : target.leadingAnchor
        }
        self.leadingAnchor.constraint(equalTo: anchor, constant: padding).isActive = true
        return self
    }
    
    @discardableResult
    func constrainRight(to other: UIView? = nil, padding: CGFloat = 0.0, respectSafeArea: Bool = true, toContentLayoutGuide: Bool = false) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        guard let target = other ?? self.superview else {
            fatalError("No constraint target found")
        }
        let anchor: NSLayoutXAxisAnchor
        if toContentLayoutGuide, let scrollView = target as? UIScrollView {
            anchor = scrollView.contentLayoutGuide.trailingAnchor
        } else {
            anchor = respectSafeArea ? target.safeAreaLayoutGuide.trailingAnchor : target.trailingAnchor
        }
        self.trailingAnchor.constraint(equalTo: anchor, constant: -padding).isActive = true
        return self
    }
    
    @discardableResult
    func constrainTop(to other: UIView? = nil, padding: CGFloat = 0.0, respectSafeArea: Bool = true, toContentLayoutGuide: Bool = false) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        guard let target = other ?? self.superview else {
            fatalError("No constraint target found")
        }
        let anchor: NSLayoutYAxisAnchor
        if toContentLayoutGuide, let scrollView = target as? UIScrollView {
            anchor = scrollView.contentLayoutGuide.topAnchor
        } else {
            anchor = respectSafeArea ? target.safeAreaLayoutGuide.topAnchor : target.topAnchor
        }
        self.topAnchor.constraint(equalTo: anchor, constant: padding).isActive = true
        return self
    }
    
    @discardableResult
    func constrainBottom(to other: UIView? = nil, padding: CGFloat = 0.0, respectSafeArea: Bool = true, toContentLayoutGuide: Bool = false) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        guard let target = other ?? self.superview else {
            fatalError("No constraint target found")
        }
        let anchor: NSLayoutYAxisAnchor
        if toContentLayoutGuide, let scrollView = target as? UIScrollView {
            anchor = scrollView.contentLayoutGuide.bottomAnchor
        } else {
            anchor = respectSafeArea ? target.safeAreaLayoutGuide.bottomAnchor : target.bottomAnchor
        }
        self.bottomAnchor.constraint(equalTo: anchor, constant: -padding).isActive = true
        return self
    }
    
    @discardableResult
    func constrainHorizontal(to other: UIView? = nil, padding: CGFloat = 0.0, respectSafeArea: Bool = true, toContentLayoutGuide: Bool = false) -> Self {
        self.constrainLeft(to: other, padding: padding, toContentLayoutGuide: toContentLayoutGuide)
        self.constrainRight(to: other, padding: padding, toContentLayoutGuide: toContentLayoutGuide)
        return self
    }
    
    @discardableResult
    func constrainVertical(to other: UIView? = nil, padding: CGFloat = 0.0, respectSafeArea: Bool = true, toContentLayoutGuide: Bool = false) -> Self {
        self.constrainTop(to: other, padding: padding, respectSafeArea: respectSafeArea, toContentLayoutGuide: toContentLayoutGuide)
        self.constrainBottom(to: other, padding: padding, respectSafeArea: respectSafeArea, toContentLayoutGuide: toContentLayoutGuide)
        return self
    }
    
    @discardableResult
    func constrainAllSides(to other: UIView? = nil, padding: CGFloat = 0.0, respectSafeArea: Bool = true, toContentLayoutGuide: Bool = false) -> Self {
        self.constrainHorizontal(to: other, padding: padding, respectSafeArea: respectSafeArea, toContentLayoutGuide: toContentLayoutGuide)
        self.constrainVertical(to: other, padding: padding, respectSafeArea: respectSafeArea, toContentLayoutGuide: toContentLayoutGuide)
        return self
    }
    
    @discardableResult
    func constrainToUnderneath(of other: UIView? = nil, padding: CGFloat = 0.0, respectSafeArea: Bool = true) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        guard let target = other ?? self.superview else {
            fatalError("No constraint target found")
        }
        let anchor = respectSafeArea ? target.safeAreaLayoutGuide.bottomAnchor : target.bottomAnchor
        self.topAnchor.constraint(equalTo: anchor, constant: padding).isActive = true
        return self
    }
    
    @discardableResult
    func constrainToOnTop(of other: UIView? = nil, padding: CGFloat = 0.0, respectSafeArea: Bool = true) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        guard let target = other ?? self.superview else {
            fatalError("No constraint target found")
        }
        let anchor = respectSafeArea ? target.safeAreaLayoutGuide.topAnchor : target.topAnchor
        self.bottomAnchor.constraint(equalTo: anchor, constant: -padding).isActive = true
        return self
    }
    
    @discardableResult
    func constrainToRightSide(of other: UIView? = nil, padding: CGFloat = 0.0, respectSafeArea: Bool = true) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        guard let target = other ?? self.superview else {
            fatalError("No constraint target found")
        }
        let anchor = respectSafeArea ? target.safeAreaLayoutGuide.rightAnchor : target.rightAnchor
        self.leftAnchor.constraint(equalTo: anchor, constant: padding).isActive = true
        return self
    }
    
    @discardableResult
    func constrainToLeftSide(of other: UIView? = nil, padding: CGFloat = 0.0, respectSafeArea: Bool = true) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        guard let target = other ?? self.superview else {
            fatalError("No constraint target found")
        }
        let anchor = respectSafeArea ? target.safeAreaLayoutGuide.leftAnchor : target.leftAnchor
        self.rightAnchor.constraint(equalTo: anchor, constant: -padding).isActive = true
        return self
    }
    
    @discardableResult
    func constrainCenterVertical(to other: UIView? = nil, respectSafeArea: Bool = true) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        guard let target = other ?? self.superview else {
            fatalError("No constraint target found")
        }
        let anchor = respectSafeArea ? target.safeAreaLayoutGuide.centerYAnchor : target.centerYAnchor
        self.centerYAnchor.constraint(equalTo: anchor).isActive = true
        return self
    }
    
    @discardableResult
    func constrainCenterHorizontal(to other: UIView? = nil, respectSafeArea: Bool = true) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        guard let target = other ?? self.superview else {
            fatalError("No constraint target found")
        }
        let anchor = respectSafeArea ? target.safeAreaLayoutGuide.centerXAnchor : target.centerXAnchor
        self.centerXAnchor.constraint(equalTo: anchor).isActive = true
        return self
    }
    
    @discardableResult
    func constrainCenter(to other: UIView? = nil, respectSafeArea: Bool = true) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        self.constrainCenterVertical(to: other, respectSafeArea: respectSafeArea)
        self.constrainCenterHorizontal(to: other, respectSafeArea: respectSafeArea)
        return self
    }
    
    @discardableResult
    func constrainBetweenVertical(
        topView: UIView? = nil,
        isBeneathTopView: Bool = true,
        bottomView: UIView? = nil,
        isAboveBottomView: Bool = true,
        topPadding: Double = 0.0,
        bottomPadding: Double = 0.0,
        respectSafeArea: Bool = true
    ) -> Self {
        guard let topView = topView ?? self.superview else {
            fatalError("No top constraint target found")
        }
        guard let bottomView = bottomView ?? self.superview else {
            fatalError("No bottom constraint target found")
        }
        guard let superview = self.superview else {
            fatalError("No superview found")
        }
        let guide = UIView().useAutoLayout()
        superview.add(guide)
        if isBeneathTopView {
            guide.constrainToUnderneath(of: topView, padding: topPadding, respectSafeArea: respectSafeArea)
        } else {
            guide.constrainTop(to: topView, padding: topPadding, respectSafeArea: respectSafeArea)
        }
        if isAboveBottomView {
            guide.constrainToOnTop(of: bottomView, padding: bottomPadding, respectSafeArea: respectSafeArea)
        } else {
            guide.constrainBottom(to: bottomView, padding: topPadding, respectSafeArea: respectSafeArea)
        }
        self.constrainCenterVertical(to: guide)
        return self
    }
    
    @discardableResult
    func constrainBetweenHorizontal(
        leftView: UIView? = nil,
        isBesideLeftView: Bool = true,
        rightView: UIView? = nil,
        isBesideRightView: Bool = true,
        leftPadding: Double = 0.0,
        rightPadding: Double = 0.0,
        respectSafeArea: Bool = true
    ) -> Self {
        guard let leftView = leftView ?? self.superview else {
            fatalError("No top constraint target found")
        }
        guard let rightView = rightView ?? self.superview else {
            fatalError("No bottom constraint target found")
        }
        guard let superview = self.superview else {
            fatalError("No superview found")
        }
        let guide = UIView().useAutoLayout()
        superview.add(guide)
        if isBesideLeftView {
            guide.constrainToRightSide(of: leftView, padding: leftPadding, respectSafeArea: respectSafeArea)
        } else {
            guide.constrainLeft(to: leftView, padding: leftPadding, respectSafeArea: respectSafeArea)
        }
        if isBesideRightView {
            guide.constrainToLeftSide(of: rightView, padding: rightPadding, respectSafeArea: respectSafeArea)
        } else {
            guide.constrainRight(to: rightView, padding: rightPadding, respectSafeArea: respectSafeArea)
        }
        self.constrainCenterHorizontal(to: guide)
        return self
    }
    
    @discardableResult
    func constrainHorizontalByProportion(to other: UIView? = nil, proportionFromLeft: Double, padding: CGFloat = 0.0, respectsSafeArea: Bool = true) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        guard let target = other ?? self.superview else {
            fatalError("No constraint target found")
        }
        let guide = UIView().useAutoLayout()
        target.add(guide)
        guide
            .constrainLeft()
            .setWidthConstraint(proportion: proportionFromLeft)
        self.constrainToRightSide(of: guide, padding: padding, respectSafeArea: respectsSafeArea)
        return self
    }
    
    @discardableResult
    func constrainVerticalByProportion(to other: UIView? = nil, proportionFromTop: Double, padding: CGFloat = 0.0, respectsSafeArea: Bool = true) -> Self {
        assert(!self.translatesAutoresizingMaskIntoConstraints, "Constraints requirement failed")
        guard let target = other ?? self.superview else {
            fatalError("No constraint target found")
        }
        let guide = UIView().useAutoLayout()
        target.add(guide)
        guide
            .constrainTop()
            .setHeightConstraint(proportion: proportionFromTop)
        self.constrainToUnderneath(of: guide, padding: padding, respectSafeArea: respectsSafeArea)
        return self
    }
    
    @discardableResult
    func setPadding(top: CGFloat? = nil, bottom: CGFloat? = nil, left: CGFloat? = nil, right: CGFloat? = nil) -> Self {
        self.layoutMargins = UIEdgeInsets(
            top: top ?? self.layoutMargins.top,
            left: left ?? self.layoutMargins.left,
            bottom: bottom ?? self.layoutMargins.bottom,
            right: right ?? self.layoutMargins.right
        )
        return self
    }
    
    @discardableResult
    func setPaddingVertical(to padding: CGFloat) -> Self {
        return self.setPadding(top: padding, bottom: padding)
    }
    
    @discardableResult
    func setPaddingHorizontal(to padding: CGFloat) -> Self {
        return self.setPadding(left: padding, right: padding)
    }
    
    @discardableResult
    func setPaddingAllSides(to padding: CGFloat) -> Self {
        self.setPaddingVertical(to: padding)
        self.setPaddingHorizontal(to: padding)
        return self
    }
    
    @discardableResult
    func removeWidthConstraint() -> Self {
        for constraint in self.constraints {
            if constraint.firstAttribute == .width && constraint.firstItem as? UIView == self {
                // Remove any width constraints
                self.removeConstraint(constraint)
            }
        }
        return self
    }
    
    @discardableResult
    func removeHeightConstraint() -> Self {
        for constraint in self.constraints {
            if constraint.firstAttribute == .height && constraint.firstItem as? UIView == self {
                // Remove any height constraints
                self.removeConstraint(constraint)
            }
        }
        return self
    }
    
    // MARK: - Background
    
    @discardableResult
    func setBackgroundColor(to color: UIColor) -> Self {
        self.backgroundColor = color
        return self
    }
    
    @discardableResult
    func setCornerRadius(to radius: Double, corners: CACornerMask? = nil) -> Self {
        self.layer.cornerRadius = radius
        if let corners {
            self.layer.maskedCorners = corners
        }
        return self
    }
    
    @discardableResult
    func addBorder(width: CGFloat = 1.0, color: UIColor = UIColor.red) -> Self {
        self.layer.borderWidth = width
        self.layer.borderColor = color.cgColor
        return self
    }
    
    @discardableResult
    func addSidedBorder(
        width: CGFloat = 1.0,
        color: UIColor = UIColor.red,
        padding: Double = 0.0,
        lengthPadding: Double = 0.0,
        left: Bool = false,
        right: Bool = false,
        top: Bool = false,
        bottom: Bool = false
    ) -> Self {
        if left {
            let borderView = UIView()
            self.add(borderView)
            borderView
                .useAutoLayout()
                .constrainVertical(padding: lengthPadding)
                .constrainToRightSide(padding: padding)
                .setWidthConstraint(to: width)
                .setBackgroundColor(to: color)
        }
        if right {
            let borderView = UIView()
            self.add(borderView)
            borderView
                .useAutoLayout()
                .constrainVertical(padding: lengthPadding)
                .constrainToLeftSide(padding: padding)
                .setWidthConstraint(to: width)
                .setBackgroundColor(to: color)
        }
        if top {
            let borderView = UIView()
            self.add(borderView)
            borderView
                .useAutoLayout()
                .constrainHorizontal(padding: lengthPadding)
                .constrainToOnTop(padding: padding)
                .setHeightConstraint(to: width)
                .setBackgroundColor(to: color)
        }
        if bottom {
            let borderView = UIView()
            self.add(borderView)
            borderView
                .useAutoLayout()
                .constrainHorizontal(padding: lengthPadding)
                .constrainToUnderneath(padding: padding)
                .setHeightConstraint(to: width)
                .setBackgroundColor(to: color)
        }
        return self
    }
    
    @discardableResult
    func addShadow(
        color: UIColor = .black,
        opacity: Float = 0.15,
        offset: CGSize = CGSize(width: 0, height: 2),
        radius: CGFloat = 3
    ) -> Self {
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOpacity = opacity
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = radius
        return self
    }
    
    @discardableResult
    func clearShadow() -> Self {
        self.layer.shadowColor = nil
        self.layer.shadowOpacity = 0.0
        self.layer.shadowOffset = CGSize()
        self.layer.shadowRadius = 0.0
        return self
    }
    
    // MARK: - Visibility
    
    @discardableResult
    func setHidden(to isHidden: Bool) -> Self {
        self.isHidden = isHidden
        return self
    }
    
    @discardableResult
    func setOpacity(to opacity: Double) -> Self {
        self.alpha = opacity
        return self
    }
    
    @discardableResult
    func setLayerOpacity(to opacity: Double) -> Self {
        self.layer.opacity = Float(opacity)
        return self
    }
    
    @discardableResult
    func setDisabledOpacity() -> Self {
        self.alpha = 0.4
        return self
    }
    
    @discardableResult
    func setInteractions(enabled: Bool) -> Self {
        self.isUserInteractionEnabled = enabled
        return self
    }
    
    // MARK: - Animations
    
    @discardableResult
    func animateOpacityInteraction() -> Self {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
            self.alpha = 0.25
        }) { _ in
            UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState], animations: {
                self.alpha = 1.0
            }, completion: nil)
        }
        return self
    }
    
    @discardableResult
    func animatePressedOpacity() -> Self {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
            self.alpha = 0.4
        }, completion: nil)
        return self
    }
    
    @discardableResult
    func animateReleaseOpacity() -> Self {
        // The following is thought out and not the result of a stroke
        // The reason we need two calls of UIView.animate is because UIScrollView has `delaysContentTouches` set to true
        // (This means that when you start a scroll gesture on a button/control, it won't consume the gesture and allow scrolling to occur)
        // (This also means animations get messed up)
        // First - if we just set the alpha without using UIView.animate with zero delay, it straight up won't work most of the time when tapping quickly
        // Second - we can't just set it to 0.4 (what `animatePressedOpacity` sets it to), we have to set it lower, otherwise it won't redraw the view and it will remain visually at 1.0 alpha
        UIView.animate(withDuration: 0.0, delay: 0, options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState], animations: {
            self.alpha = 0.39
        }, completion: { _ in
            UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState], animations: {
                self.alpha = 1.0
            }, completion: nil)
        })
        return self
    }
    
    @discardableResult
    func animateEntrance(duration: Double = 0.2, onCompletion: @escaping () -> Void = {}) -> Self {
        self.setOpacity(to: 0.0)
        self.transform = CGAffineTransform(translationX: 0, y: -10)
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 2, options: [.curveEaseOut, .allowUserInteraction], animations: {
            self.setOpacity(to: 1.0)
            self.transform = CGAffineTransform(translationX: 0, y: 0)
        }) { _ in
            onCompletion()
        }
        return self
    }
    
    @discardableResult
    func animateExit(duration: Double = 0.2, onCompletion: @escaping () -> Void) -> Self {
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 2, options: [.curveEaseOut, .allowUserInteraction], animations: {
            self.setOpacity(to: 0.0)
            self.transform = CGAffineTransform(translationX: 0, y: -10)
        }) { _ in
            onCompletion()
        }
        return self
    }
    
    @discardableResult
    func animateOpacity(to opacity: Double, duration: Double = 0.2, onCompletion: @escaping () -> Void = {}) -> Self {
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 2, options: [.curveEaseOut, .allowUserInteraction], animations: {
            self.setOpacity(to: opacity)
        }) { _ in
            onCompletion()
        }
        return self
    }
    
    // MARK: - Transformations
    
    @discardableResult
    func setTransformation(to transformation: CGAffineTransform) -> Self {
        self.transform = transformation
        return self
    }
    
}
