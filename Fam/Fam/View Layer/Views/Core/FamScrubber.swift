//
//  FamScrubber.swift
//  Fam
//
//  Created by Andre Pham on 5/8/2023.
//

import Foundation
import UIKit

class FamScrubber: FamView {
    
    private static let SCRUBBER_DIAMETER = 30.0
    
    private let container = FamGesture()
    private let scrubberBackground = FamView()
    private let scrubberLine = FamView()
    private let scrubberControl = FamView()
    private var onStartTracking: (() -> Void)? = nil
    private var onEndTracking: (() -> Void)? = nil
    private var onChange: ((_ proportion: Double) -> Void)? = nil
    private(set) var progressProportion: CGFloat = 0.0 {
        didSet {
            self.updateCirclePosition()
        }
    }
    private(set) var isTracking = false
    private(set) var isDisabled = false
    
    override func setup() {
        super.setup()
        self.add(self.container)
        
        self.container
            .constrainAllSides()
            .add(self.scrubberBackground)
            .add(self.scrubberLine)
            .add(self.scrubberControl)
            .setOnGesture({ gesture in
                self.onDrag(gesture)
            })
        
        self.scrubberBackground
            .setBackgroundColor(to: FamColors.secondaryComponentFill)
            .constrainHorizontal()
            .constrainCenterVertical()
            .setHeightConstraint(to: Self.SCRUBBER_DIAMETER)
            .setCornerRadius(to: Self.SCRUBBER_DIAMETER/2.0)
        
        self.scrubberLine
            .setBackgroundColor(to: .black)
            .setOpacity(to: 0.15)
            .constrainHorizontal(padding: Self.SCRUBBER_DIAMETER/2.0)
            .constrainCenterVertical()
            .setHeightConstraint(to: 5)
            .setCornerRadius(to: 2.5)
        
        self.scrubberControl
            .setBackgroundColor(to: FamColors.accent)
            .setWidthConstraint(to: Self.SCRUBBER_DIAMETER)
            .setHeightConstraint(to: Self.SCRUBBER_DIAMETER)
            .constrainCenterVertical()
            .setCornerRadius(to: Self.SCRUBBER_DIAMETER/2.0)
    }
    
    func setProgress(to proportion: Double) {
        self.progressProportion = min(1.0, max(0.0, proportion))
    }
    
    @discardableResult
    func constrainToViewHeight() -> Self {
        self.setHeightConstraint(to: Self.SCRUBBER_DIAMETER)
        return self
    }
    
    @discardableResult
    func setOnStartTracking(_ callback: (() -> Void)?) -> Self {
        self.onStartTracking = callback
        return self
    }
    
    @discardableResult
    func setOnEndTracking(_ callback: (() -> Void)?) -> Self {
        self.onEndTracking = callback
        return self
    }
    
    @discardableResult
    func setOnChange(_ callback: ((_ proportion: Double) -> Void)?) -> Self {
        self.onChange = callback
        return self
    }
    
    @discardableResult
    func setDisabled(to state: Bool) -> Self {
        self.isDisabled = state
        self.isTracking = false
        return self
    }
    
    private func onDrag(_ gesture: UIPanGestureRecognizer) {
        guard !self.isDisabled else {
            return
        }
        switch gesture.state {
        case .began:
            self.isTracking = true
            self.onStartTracking?()
        case .changed:
            let containerWidth = self.container.frame.width
            let lineWidth = containerWidth - Self.SCRUBBER_DIAMETER
            let positionInContainer = gesture.location(in: self.container).x
            let positionInLine = {
                let clampedPosition = min(containerWidth - Self.SCRUBBER_DIAMETER/2.0, max(Self.SCRUBBER_DIAMETER/2.0, positionInContainer))
                return clampedPosition - Self.SCRUBBER_DIAMETER/2.0
            }()
            let newProgress = positionInLine/lineWidth
            self.progressProportion = min(1.0, max(0.0, newProgress))
            self.onChange?(self.progressProportion)
        case .ended, .cancelled, .failed:
            self.isTracking = false
            self.onEndTracking?()
        default:
            break
        }
    }
    
    private func updateCirclePosition() {
        let timelineWidth = self.container.bounds.width - Self.SCRUBBER_DIAMETER
        let newPosition = progressProportion * timelineWidth + Self.SCRUBBER_DIAMETER / 2
        self.scrubberControl.center.x = newPosition
    }
    
}
