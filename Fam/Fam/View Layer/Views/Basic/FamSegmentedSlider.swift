//
//  FamSegmentedSlider.swift
//  Fam
//
//  Created by Andre Pham on 8/3/2024.
//

import Foundation
import UIKit

class FamSegmentedSlider<T: Any>: FamUIView {
    
    private static var SCRUBBER_DIAMETER: Double { 30.0 }
    private static var DEFAULT_LABEL_WIDTH: Double { 50.0 }
    private static var DEFAULT_LABEL_HEIGHT: Double { 35.0 }
    private static var LABEL_CORNER_RADIUS_HEIGHT_MULTIPLIER: Double { 0.45 }
    
    private let container = FamGestureView()
    private let scrubberBackground = FamView()
    private let scrubberLine = FamView()
    private var scrubberLineSegmentIndicators = [FamView]()
    private let scrubberControl = FamView()
    private let scrubberLabel = FamView()
    public let scrubberLabelText = FamText()
    private(set) var segmentIndex = 0
    private(set) var values = [T]()
    private var labels = [String]()
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    private(set) var animationDuration: Double? = 0.05
    public var activeValue: T {
        return self.values[self.segmentIndex]
    }
    private var activeLabel: String? {
        guard self.labels.count - 1 >= self.segmentIndex else {
            return nil
        }
        return self.labels[self.segmentIndex]
    }
    private var activeValueProgressProportion: CGFloat {
        guard !self.values.isEmpty else {
            return 0.0
        }
        return CGFloat(self.segmentIndex)/CGFloat(self.values.count - 1)
    }
    public var view: UIView {
        return self.container.view
    }
    
    private var onStartTracking: (() -> Void)? = nil
    private var onEndTracking: ((_ value: T) -> Void)? = nil
    private var onChange: ((_ value: T) -> Void)? = nil
    private var progressProportion: CGFloat = 0.0 {
        didSet {
            self.updateCirclePosition()
        }
    }
    private(set) var isTracking: Bool = false
    
    override init() {
        super.init()
        
        self.container
            .addSubview(self.scrubberBackground)
            .addSubview(self.scrubberLine)
            .addSubview(self.scrubberControl)
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
            .setHeightConstraint(to: 5.0)
            .setCornerRadius(to: 2.5)
        
        self.scrubberControl
            .setBackgroundColor(to: FamColors.accent)
            .setWidthConstraint(to: Self.SCRUBBER_DIAMETER)
            .setHeightConstraint(to: Self.SCRUBBER_DIAMETER)
            .constrainCenterVertical()
            .setCornerRadius(to: Self.SCRUBBER_DIAMETER/2.0)
            .addSubview(self.scrubberLabel)
        
        self.scrubberLabel
            .constrainCenterHorizontal()
            .constrainToOnTop(padding: 10.0)
            .setWidthConstraint(to: Self.DEFAULT_LABEL_WIDTH)
            .setHeightConstraint(to: Self.DEFAULT_LABEL_HEIGHT)
            .setCornerRadius(to: Self.DEFAULT_LABEL_HEIGHT*Self.LABEL_CORNER_RADIUS_HEIGHT_MULTIPLIER)
            .setBackgroundColor(to: FamColors.foregroundFill)
            .addShadow()
            .addSubview(self.scrubberLabelText)
        
        self.scrubberLabelText
            .constrainCenterVertical()
            .constrainCenterHorizontal()
            .setFont(to: FamFont(font: FamFonts.Quicksand.Bold, size: 16))
            .setTextColor(to: FamColors.textDark1)
        
        self.disableScrubberLabel()
    }
    
    @discardableResult
    func constrainToViewHeight() -> Self {
        self.setHeightConstraint(to: Self.SCRUBBER_DIAMETER)
        return self
    }
    
    @discardableResult
    func setSegment(index: Int, trigger: Bool = false, useHaptics: Bool = true, isStartingValue: Bool = false) -> Self {
        let animationRestoration = self.animationDuration
        if isStartingValue {
            self.disableAnimation()
        }
        let triggerHaptics = useHaptics && index != self.segmentIndex
        self.segmentIndex = index
        self.setProgress(to: self.activeValueProgressProportion)
        if trigger {
            self.onChange?(self.activeValue)
        }
        if triggerHaptics {
            self.hapticFeedback.impactOccurred()
        }
        if isStartingValue, let animationRestoration {
            self.setAnimation(duration: animationRestoration)
            let timelineWidth = self.container.widthConstraintConstant - Self.SCRUBBER_DIAMETER
            let newPosition = self.progressProportion * timelineWidth + Self.SCRUBBER_DIAMETER / 2
            self.scrubberControl.view.center.x = newPosition
        }
        return self
    }
    
    @discardableResult
    func addSegment(value: T, label: String) -> Self {
        self.values.append(value)
        self.labels.append(label)
        self.redrawIndicators()
        return self
    }
    
    @discardableResult
    func setOnStartTracking(_ callback: (() -> Void)?) -> Self {
        self.onStartTracking = callback
        return self
    }
    
    @discardableResult
    func setOnEndTracking(_ callback: ((_ value: T) -> Void)?) -> Self {
        self.onEndTracking = callback
        return self
    }
    
    @discardableResult
    func setOnChange(_ callback: ((_ value: T) -> Void)?) -> Self {
        self.onChange = callback
        return self
    }
    
    @discardableResult
    func disableAnimation() -> Self {
        self.animationDuration = nil
        return self
    }
    
    @discardableResult
    func setAnimation(duration: Double) -> Self {
        self.animationDuration = duration
        return self
    }
    
    private func redrawScrubberLabel() {
        guard let labelText = self.activeLabel else {
            assertionFailure("Failed to retrieve label - something has gone very wrong")
            return
        }
        self.scrubberLabelText.setText(to: labelText)
        self.scrubberLabel
            .removeWidthConstraint()
            .removeHeightConstraint()
        let textSize = self.scrubberLabelText.contentBasedSize
        let horizontalPadding = 12.0
        let verticalPadding = 10.0
        let fittedWidth = textSize.width + horizontalPadding*2
        let fittedHeight = textSize.height + verticalPadding*2
        if fittedWidth.isGreater(than: Self.DEFAULT_LABEL_WIDTH) {
            self.scrubberLabel.setWidthConstraint(to: fittedWidth)
        } else {
            self.scrubberLabel.setWidthConstraint(to: Self.DEFAULT_LABEL_WIDTH)
        }
        if fittedHeight.isGreater(than: Self.DEFAULT_LABEL_HEIGHT) {
            self.scrubberLabel
                .setHeightConstraint(to: fittedHeight)
                .setCornerRadius(to: fittedHeight*Self.LABEL_CORNER_RADIUS_HEIGHT_MULTIPLIER)
        } else {
            self.scrubberLabel
                .setHeightConstraint(to: Self.DEFAULT_LABEL_HEIGHT)
                .setCornerRadius(to: Self.DEFAULT_LABEL_HEIGHT*Self.LABEL_CORNER_RADIUS_HEIGHT_MULTIPLIER)
        }
        self.scrubberLabel.reframeIntoWindow(
            padding: FamDimensions.screenContentPaddingHorizontal/2.0,
            inset: FamDimensions.screenContentPaddingHorizontal/2.0
        )
    }
    
    private func activateScrubberLabel() {
        self.scrubberLabel.setHidden(to: false)
    }
    
    private func disableScrubberLabel() {
        self.scrubberLabel.setHidden(to: true)
    }
    
    private func redrawIndicators() {
        self.scrubberLineSegmentIndicators.forEach({ $0.removeFromSuperView() })
        self.scrubberLineSegmentIndicators.removeAll()
        for indicatorIndex in self.values.indices {
            let indicator = FamView()
            self.scrubberLineSegmentIndicators.append(indicator)
            self.scrubberLine.addSubview(indicator)
            let height = Self.SCRUBBER_DIAMETER*0.4
            let width = Self.SCRUBBER_DIAMETER*0.4
            let cornerRadius = width/2.0
            indicator
                .constrainCenterVertical()
                .constrainHorizontalByProportion(
                    proportionFromLeft: Double(indicatorIndex)/Double(self.values.count == 1 ? 1 : self.values.count - 1),
                    padding: -width/2.0
                )
                .setBackgroundColor(to: .black)
                .setHeightConstraint(to: height)
                .setWidthConstraint(to: width)
                .setCornerRadius(to: cornerRadius)
        }
    }
    
    private func setProgress(to proportion: Double) {
        self.progressProportion = min(1.0, max(0.0, proportion))
    }
    
    private func onDrag(_ gesture: UIPanGestureRecognizer) {
        guard !self.values.isEmpty else {
            return
        }
        switch gesture.state {
        case .began:
            self.isTracking = true
            self.redrawScrubberLabel()
            self.activateScrubberLabel()
            self.onStartTracking?()
        case .changed:
            // Calculate the drag position (disregarding segments)
            let containerWidth = self.container.frame.width
            let lineWidth = containerWidth - Self.SCRUBBER_DIAMETER
            let positionInContainer = gesture.location(in: self.container.view).x
            let positionInLine = {
                let clampedPosition = min(containerWidth - Self.SCRUBBER_DIAMETER/2.0, max(Self.SCRUBBER_DIAMETER/2.0, positionInContainer))
                return clampedPosition - Self.SCRUBBER_DIAMETER/2.0
            }()
            let newProgress = min(1.0, max(0.0, positionInLine/lineWidth))
            // Calculate the segment that corresponds to that position
            var candidateState = 0
            var finalState = 0
            var finalDistance: Double? = nil
            while candidateState < self.values.endIndex {
                let candidateStateTargetProportion = Double(candidateState)/Double(self.values.count - 1)
                let candidateDifference = abs(newProgress - candidateStateTargetProportion)
                if finalDistance == nil || candidateDifference.isLess(than: finalDistance!) {
                    finalDistance = candidateDifference
                    finalState = candidateState
                } else {
                    break
                }
                candidateState += 1
            }
            self.setSegment(index: finalState, trigger: true)
            // Show label of segment
            self.redrawScrubberLabel()
        case .ended, .cancelled, .failed:
            self.isTracking = false
            self.disableScrubberLabel()
            self.onEndTracking?(self.activeValue)
        default:
            break
        }
    }
    
    private func updateCirclePosition() {
        let timelineWidth = self.container.view.bounds.width - Self.SCRUBBER_DIAMETER
        let newPosition = self.progressProportion * timelineWidth + Self.SCRUBBER_DIAMETER / 2
        if let animationDuration {
            UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveLinear, .allowUserInteraction], animations: {
                self.scrubberControl.view.center.x = newPosition
            })
        } else {
            self.scrubberControl.view.center.x = newPosition
        }
    }
    
}
