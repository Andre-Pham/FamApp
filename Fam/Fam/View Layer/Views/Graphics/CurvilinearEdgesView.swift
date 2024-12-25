//
//  CurvilinearEdgesView.swift
//  Fam
//
//  Created by Andre Pham on 21/12/2024.
//

import Foundation
import UIKit
import SwiftMath

class CurvilinearEdgesView: FamView {
    
    private var curvilinearEdges = SMCurvilinearEdges()
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
        context.addPath(self.curvilinearEdges.cgPath)
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
    func setCurvilinearEdges(_ curvilinearEdges: SMCurvilinearEdges) -> Self {
        self.curvilinearEdges = curvilinearEdges
        self.boundingBox = curvilinearEdges.boundingBox ?? SMRect(minX: 0, maxX: 0, minY: 0, maxY: 0)
        self.boundingBox.expandAllSides(by: self.lineWidth)
        self.curvilinearEdges -= self.boundingBox.origin
        self.refreshSizeConstraints()
        return self
    }
    
    // TODO: Optimise setLineWidth for all geometry views, which currently performs two transform operations when only one is needed
    // let previousBoundingBoxOrigin = self.boundingBox.origin
    // self.boundingBox.expandAllSides(by: width - self.lineWidth)
    
    @discardableResult
    func setLineWidth(to width: Double) -> Self {
        self.curvilinearEdges += self.boundingBox.origin
        self.boundingBox.expandAllSides(by: width - self.lineWidth)
        self.curvilinearEdges -= self.boundingBox.origin
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
