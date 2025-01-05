//
//  CanvasController.swift
//  Fam
//
//  Created by Andre Pham on 18/4/2024.
//

import Foundation
import UIKit
import SwiftMath

public class CanvasController: UIViewController, UIScrollViewDelegate {
    
    // MARK: - Default Constants
    
    private static let DEFAULT_CANVAS_WIDTH = 4000.0
    private static let DEFAULT_CANVAS_HEIGHT = 4000.0
    private static let DEFAULT_CANVAS_COLOR = UIColor.clear
    private static let DEFAULT_BOUNCE = true
    private static let DEFAULT_MIN_ZOOM_SCALE = 0.2
    private static let DEFAULT_MAX_ZOOM_SCALE = 1.0
    private static let DEFAULT_SHOW_SCROLL_BARS = true
    
    // MARK: - View Properties
    
    private let scrollContainer = UIScrollView()
    private let canvasContainer = UIView()
    
    // MARK: - Layer Properties
    
    private(set) var layers = [UIView]()
    
    // MARK: - Rendering Properties
    
    /// The size of the canvas
    private(set) var canvasSize = CGSize()
    /// The size of the controller's view
    private var viewSize: CGSize {
        return self.view.bounds.size
    }
    /// The min allowed zoom scale
    private var minZoomScale: CGFloat {
        return self.scrollContainer.minimumZoomScale
    }
    /// The max allowed zoom scale
    private var maxZoomScale: CGFloat {
        return self.scrollContainer.maximumZoomScale
    }
    /// The zoom scale applied to the canvas
    private var zoomScale: CGFloat {
        return self.scrollContainer.zoomScale
    }
    /// True if the user is holding a position that's zoomed out further than the max zoom scale
    private var pastMinZoomScale: Bool {
        return self.zoomScale.isLess(than: self.minZoomScale)
    }
    /// The visible area (viewport) as a subset of the entire canvas
    private var visibleArea: CGRect {
        let width = self.scrollContainer.bounds.size.width/self.zoomScale
        let height = self.scrollContainer.bounds.size.height/self.zoomScale
        var x = self.scrollContainer.contentOffset.x/self.zoomScale
        var y = self.scrollContainer.contentOffset.y/self.zoomScale
        guard !self.pastMinZoomScale else {
            return CGRect(x: x, y: y, width: width, height: height)
        }
        if (x + width).isGreater(than: self.canvasSize.width) {
            x -= (x + width - self.canvasSize.width)
        }
        if (y + height).isGreater(than: self.canvasSize.height) {
            y -= (y + height - self.canvasSize.height)
        }
        return CGRect(
            x: max(x, 0.0),
            y: max(y, 0.0),
            width: min(width, self.canvasWidth),
            height: min(height, self.canvasHeight)
        )
    }
    
    // MARK: - Alignment Guides
    
    public var canvasRect: SMRect {
        return SMRect(minX: 0.0, minY: 0.0, maxX: self.canvasSize.width, maxY: self.canvasSize.height)
    }
    public var canvasWidth: Double {
        return self.canvasSize.width
    }
    public var canvasHeight: Double {
        return self.canvasSize.height
    }
    public var canvasCenter: SMPoint {
        return SMPoint(x: self.canvasSize.width/2.0, y: self.canvasSize.height/2.0)
    }
    public var canvasTopLeft: SMPoint {
        return SMPoint()
    }
    public var canvasTopRight: SMPoint {
        return SMPoint(x: self.canvasSize.width, y: 0)
    }
    public var canvasBottomLeft: SMPoint {
        return SMPoint(x: 0, y: self.canvasSize.height)
    }
    public var canvasBottomRight: SMPoint {
        return SMPoint(x: self.canvasSize.width, y: self.canvasSize.height)
    }
    public var canvasLeftBorder: SMLineSegment {
        return SMLineSegment(origin: SMPoint(), end: SMPoint(x: 0.0, y: self.canvasSize.height))
    }
    public var canvasRightBorder: SMLineSegment {
        return SMLineSegment(origin: SMPoint(x: self.canvasSize.width, y: 0), end: SMPoint(x: self.canvasSize.width, y: self.canvasSize.height))
    }
    public var canvasTopBorder: SMLineSegment {
        return SMLineSegment(origin: SMPoint(), end: SMPoint(x: self.canvasSize.width, y: 0.0))
    }
    public var canvasBottomBorder: SMLineSegment {
        return SMLineSegment(origin: SMPoint(x: 0.0, y: self.canvasSize.height), end: SMPoint(x: self.canvasSize.width, y: self.canvasSize.height))
    }
    public var canvasBorder: SMPolygon {
        return SMPolygon(vertices: [
            SMPoint(x: 0.0, y: 0.0),
            SMPoint(x: 0.0, y: self.canvasSize.height),
            SMPoint(x: self.canvasSize.width, y: self.canvasSize.height),
            SMPoint(x: self.canvasSize.width, y: 0.0)
        ])
    }
    
    // MARK: - View Loading Functions
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup properties
        self.canvasSize = CGSize(width: Self.DEFAULT_CANVAS_WIDTH, height: Self.DEFAULT_CANVAS_HEIGHT)
        self.view.backgroundColor = Self.DEFAULT_CANVAS_COLOR
        
        // View hierarchy
        self.view.addSubview(self.scrollContainer)
        self.scrollContainer.addSubview(self.canvasContainer)
        
        // Setup scroll container
        self.scrollContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.scrollContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.scrollContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.scrollContainer.topAnchor.constraint(equalTo: view.topAnchor),
            self.scrollContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.scrollContainer.delegate = self
        self.scrollContainer.alwaysBounceVertical = Self.DEFAULT_BOUNCE
        self.scrollContainer.alwaysBounceHorizontal = Self.DEFAULT_BOUNCE
        self.scrollContainer.contentSize = self.canvasSize
        self.scrollContainer.minimumZoomScale = Self.DEFAULT_MIN_ZOOM_SCALE
        self.scrollContainer.maximumZoomScale = Self.DEFAULT_MAX_ZOOM_SCALE
        self.scrollContainer.showsVerticalScrollIndicator = Self.DEFAULT_SHOW_SCROLL_BARS
        self.scrollContainer.showsHorizontalScrollIndicator = Self.DEFAULT_SHOW_SCROLL_BARS
        
        // Setup canvas container
        self.canvasContainer.frame = CGRect(origin: CGPoint(), size: self.canvasSize)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.scrollContainer.contentOffset = CGPoint(
            x: self.canvasWidth/2.0 - self.viewSize.width/2.0,
            y: self.canvasHeight/2.0 - self.viewSize.height/2.0
        )
    }
    
    /// Mounts this view controller as a child of another view controller.
    /// Example:
    /// ```
    /// // Inside a view controller's viewDidLoad
    /// let canvasView = self.canvasController.mount(to: self) // 1. Mount canvas to view controller
    /// self.view.add(canvasView)                              // 2. Add canvas view as subview
    /// canvasView.constrainAllSides(padding: 50)              // 3. Constrain canvas view
    /// ```
    /// - Parameters:
    ///   - viewController: The view controller to be the parent of the canvas view controller
    /// - Returns: The canvas controller's view to be added as a subview
    public func mount(to viewController: UIViewController) -> UIView {
        viewController.addChild(self)
        self.view.useAutoLayout()
        self.didMove(toParent: viewController)
        return self.view
    }
    
    // MARK: - Config Functions
    
    /// Sets the canvas size.
    /// Maintains the viewport position relative to if the canvas was expanding/contracting in all directions equally.
    /// - Parameters:
    ///   - size: The new size for the canvas
    @discardableResult
    public func setCanvasSize(to size: SMSize) -> Self {
        let previousZoom = self.zoomScale
        let previousVisibleArea = SMRect(self.visibleArea)
        // Calculate where the visible area would be if the canvas expanded/contracted in all directions equally
        // (In reality, the canvas expands in the positive x and y direction)
        let visibleAreaOffset = SMPoint(x: size.width - self.canvasWidth, y: size.height - self.canvasHeight) / 2.0
        var targetNewVisibleArea = previousVisibleArea + visibleAreaOffset
        // If the target visible area is outside the new canvas size (because the canvas shrank), translate it to be inside
        targetNewVisibleArea.translate(
            x: min(size.width - targetNewVisibleArea.maxX, 0),
            y: min(size.height - targetNewVisibleArea.maxY, 0)
        )
        // We only want to zoom to inside the new canvas area
        // If our target visible area is partially outside, the center can be offset from where it should be
        let newVisibleArea = targetNewVisibleArea.overlap(SMRect(origin: SMPoint(), width: size.width, height: size.height))
        // Zoom to a scale of 1.0 first, otherwise canvas content can become clipped
        self.zoom(scale: 1.0, animated: false)
        self.canvasSize = size.cgSize
        self.canvasContainer.frame = CGRect(origin: CGPoint(), size: self.canvasSize)
        if let newVisibleArea {
            self.zoomCenterTo(newVisibleArea.center, scale: previousZoom, animated: false)
        } else {
            self.zoomToCanvasCenter(scale: previousZoom, animated: false)
        }
        // Necessary - otherwise can cause canvas getting "stuck"
        // Example: scroll to the bottom-right corner of a large canvas, and then shrink the canvas, then scroll around
        self.scrollViewDidZoom(self.scrollContainer)
        return self
    }
    
    @discardableResult
    public func setCanvasBounce(to state: Bool) -> Self {
        self.scrollContainer.alwaysBounceVertical = state
        self.scrollContainer.alwaysBounceHorizontal = state
        return self
    }
    
    @discardableResult
    public func setCanvasBackgroundColor(to color: UIColor) -> Self {
        self.view.backgroundColor = color
        return self
    }
    
    @discardableResult
    public func setMinZoomScale(to scale: Double) -> Self {
        self.scrollContainer.minimumZoomScale = scale
        return self
    }
    
    @discardableResult
    public func setMaxZoomScale(to scale: Double) -> Self {
        self.scrollContainer.maximumZoomScale = scale
        return self
    }
    
    @discardableResult
    public func matchMinZoomScaleToCanvasSize() -> Self {
        return self.setMinZoomScale(to: self.viewSize.height/min(self.canvasSize.width, self.canvasSize.height))
    }
    
    @discardableResult
    public func setScrollBarVisibility(to visible: Bool) -> Self {
        self.scrollContainer.showsVerticalScrollIndicator = visible
        self.scrollContainer.showsHorizontalScrollIndicator = visible
        return self
    }
    
    // MARK: - Layer Functions
    
    public func addLayer() -> UIView {
        let newLayer = UIView().useAutoLayout()
        self.layers.append(newLayer)
        self.canvasContainer.add(newLayer)
        newLayer.constrainAllSides()
        return newLayer
    }
    
    public func insertLayer(at position: Int) -> UIView {
        guard position <= self.layers.count else {
            return self.addLayer()
        }
        let newLayer = UIView().useAutoLayout()
        self.layers.insert(newLayer, at: position)
        self.canvasContainer.add(newLayer, at: position)
        newLayer.constrainAllSides()
        return newLayer
    }
    
    // MARK: - Scroll and Zoom Functions
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.canvasContainer
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.size.width
        let height = scrollView.bounds.size.height
        let contentWidth = scrollView.contentSize.width
        let contentHeight = scrollView.contentSize.height
        let horizontalInset = max(0, (width - contentWidth) / 2)
        let verticalInset = max(0, (height - contentHeight) / 2)
        scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }
    
    /// Sets the zoom scale.
    /// - Parameters:
    ///   - animated: True to animate the zoom
    public func zoom(scale: Double, animated: Bool) {
        self.scrollContainer.setZoomScale(scale, animated: animated)
    }
    
    /// Zooms so the viewport origin (top left corner) is at the provided position.
    /// - Parameters:
    ///   - position: The position to set the viewport window at
    ///   - scale: The scale to zoom to (by default doesn't change scale)
    ///   - animated: True to animate the zoom
    public func zoomOriginTo(_ position: SMPoint, scale: Double? = nil, animated: Bool) {
        if let scale {
            self.zoom(scale: scale, animated: animated)
        }
        self.scrollContainer.setContentOffset(position.cgPoint, animated: animated)
    }
    
    /// Zooms so the viewport is centered at the provided position.
    /// - Parameters:
    ///   - position: The position to zoom to and be centered
    ///   - scale: The scale to zoom to (by default doesn't change scale)
    ///   - animated: True to animate the zoom
    public func zoomCenterTo(_ position: SMPoint, scale: Double? = nil, animated: Bool) {
        let targetScale = scale ?? self.zoomScale
        if let scale {
            self.zoom(scale: scale, animated: animated)
        }
        self.scrollContainer.setContentOffset(
            CGPoint(
                x: position.x*targetScale - self.viewSize.width/2.0,
                y: position.y*targetScale - self.viewSize.height/2.0
            ),
            animated: animated
        )
    }
    
    /// Zooms to the center of the canvas.
    /// - Parameters:
    ///   - scale: The scale to zoom to (by default doesn't change scale)
    ///   - animated: True to animate the zoom
    public func zoomToCanvasCenter(scale: Double? = nil, animated: Bool) {
        let targetScale = scale ?? self.zoomScale
        if let scale {
            self.zoom(scale: scale, animated: animated)
        }
        self.scrollContainer.setContentOffset(
            CGPoint(
                x: self.canvasWidth/2.0*targetScale - self.viewSize.width/2.0,
                y: self.canvasHeight/2.0*targetScale - self.viewSize.height/2.0
            ),
            animated: animated
        )
    }
    
    /// Zooms to fit the canvas exactly (zoom-to-fit).
    /// - Parameters:
    ///   - animated: True to animate the zoom
    public func zoomToFitCanvas(animated: Bool) {
        let widthFraction = self.viewSize.width/self.canvasWidth
        let heightFraction = self.viewSize.height/self.canvasHeight
        let targetScale = min(widthFraction, heightFraction)
        self.zoomToCanvasCenter(scale: targetScale, animated: animated)
    }
    
    /// Zooms so the viewport fits the passed in rect.
    /// - Parameters:
    ///   - rect: The rect to zoom to and become visible
    ///   - animated: True to animate the zoom
    public func zoomToFitRect(_ rect: SMRect, animated: Bool) {
        self.scrollContainer.zoom(to: rect.cgRect, animated: animated)
        
        // Note:
        // Test thoroughly when calling this internally
        // It can have some side effects with the canvas getting "stuck" if called whilst, for example, modifying the canvas size
        // In such a scenario, the following code can handle those cases correctly
        // (Although it would have to be revisited - it currently doesn't center the canvas if zooming the entire canvas size)
        // ``` let widthFraction = self.viewSize.width/rect.width
        //     let heightFraction = self.viewSize.height/rect.height
        //     let targetScale = min(widthFraction, heightFraction)
        //     self.zoom(scale: targetScale, animated: animated)
        //     self.scrollContainer.setContentOffset(
        //         CGPoint(
        //             x: rect.origin.x*targetScale,
        //             y: rect.origin.y*targetScale
        //         ),
        //         animated: animated
        //     )
        // ```
    }
    
}
