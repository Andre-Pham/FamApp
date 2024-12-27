//
//  LineSegmentView.swift
//  Fam
//
//  Created by Andre Pham on 17/12/2024.
//

import Foundation
import UIKit
import SwiftMath

class LineSegmentView: FamView {
    
    private var lineSegment = SMLineSegment(origin: SMPoint(), end: SMPoint())
    private var boundingBox = SMRect(origin: SMPoint(), end: SMPoint())
    private var strokeColor = UIColor.black
    private var lineWidth = 1.0
    private var lineCap: CGLineCap = .butt
    private var dash: (phase: CGFloat, lengths: [CGFloat])? = nil
    
    override func setup() {
        super.setup()
        self.setBackgroundColor(to: .clear)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.addPath(self.lineSegment.cgPath)
        context.setStrokeColor(self.strokeColor.cgColor)
        context.setLineWidth(self.lineWidth)
        context.setLineCap(self.lineCap)
        if let dash {
            context.setLineDash(phase: dash.phase, lengths: dash.lengths)
        }
        context.strokePath()
    }
    
    @discardableResult
    func constrainToPosition() -> Self {
        self.constrainLeft(padding: self.boundingBox.minX)
            .constrainTop(padding: self.boundingBox.minY)
    }
    
    @discardableResult
    func setLineSegment(_ lineSegment: SMLineSegment) -> Self {
        self.lineSegment = lineSegment
        self.boundingBox = lineSegment.boundingBox
        self.boundingBox.expandAllSides(by: self.lineWidth)
        self.lineSegment -= self.boundingBox.origin
        self.refreshSizeConstraints()
        return self
    }
    
    @discardableResult
    func setLineWidth(to width: Double) -> Self {
        let previousOrigin = self.boundingBox.origin
        self.boundingBox.expandAllSides(by: width - self.lineWidth)
        self.lineSegment += (previousOrigin - self.boundingBox.origin)
        self.lineWidth = width
        self.refreshSizeConstraints()
        return self
    }
    
    @discardableResult
    func setStrokeColor(to color: UIColor) -> Self {
        self.strokeColor = color
        return self
    }
    
    @discardableResult
    func setLineCap(to lineCap: CGLineCap) -> Self {
        self.lineCap = lineCap
        return self
    }
    
    @discardableResult
    func setDash(to dash: (phase: CGFloat, lengths: [CGFloat])?) -> Self {
        self.dash = dash
        return self
    }
    
    private func refreshSizeConstraints() {
        self.removeWidthConstraint()
            .removeHeightConstraint()
            .setWidthConstraint(to: self.boundingBox.width)
            .setHeightConstraint(to: self.boundingBox.height)
    }
    
}
