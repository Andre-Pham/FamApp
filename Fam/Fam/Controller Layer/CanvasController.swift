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
    
    private(set) var canvasSize = CGSize()
    private var viewSize: CGSize {
        return self.view.bounds.size
    }
    private var minZoomScale: CGFloat {
        return self.scrollContainer.minimumZoomScale
    }
    private var maxZoomScale: CGFloat {
        return self.scrollContainer.maximumZoomScale
    }
    private var zoomScale: CGFloat {
        return self.scrollContainer.zoomScale
    }
    ///
    private var visibleArea: CGRect {
        let width = self.scrollContainer.bounds.size.width/self.zoomScale
        let height = self.scrollContainer.bounds.size.height/self.zoomScale
        var x = self.scrollContainer.contentOffset.x/self.zoomScale
        var y = self.scrollContainer.contentOffset.y/self.zoomScale
        guard !self.visibleAreaOutOfBounds else {
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
    private var visibleAreaOutOfBounds: Bool {
        return self.zoomScale.isLess(than: self.minZoomScale)
    }
    
    public func printTest() {
        print("zoom scale: \(self.zoomScale)")
        
        print("visible area: \(SMRect(self.visibleArea).toString())")
        
        print("canvas size: \(SMSize(self.canvasSize).toString())")
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
    
    // MARK: - Config Functions
    
    @discardableResult
    public func setCanvasSize(to size: SMSize) -> Self {
        let previousZoom = self.zoomScale
        let previousVisibleArea = SMRect(self.visibleArea)
        print("previous visible area: \(previousVisibleArea.toString())")
        print("previous canvas size: \(SMSize(self.canvasSize).toString())")
        let visibleAreaOffset = SMPoint(x: size.width - self.canvasWidth, y: size.height - self.canvasHeight) / 2.0
        var targetNewVisibleArea = previousVisibleArea + visibleAreaOffset
        targetNewVisibleArea.translate(
            x: min(size.width - targetNewVisibleArea.maxX, 0),
            y: min(size.height - targetNewVisibleArea.maxY, 0)
        )
        let newVisibleArea = targetNewVisibleArea.overlap(SMRect(origin: SMPoint(), width: size.width, height: size.height))
        print("visibleAreaOffset: \(visibleAreaOffset.toString())")
        self.zoomTo(scale: 1.0, animated: false)
        self.canvasSize = size.cgSize
        self.canvasContainer.frame = CGRect(origin: CGPoint(), size: self.canvasSize)
//        self.zoomTo(scale: previousZoomScale, animated: false)
//        let sizeDifference = SMRect(origin: SMPoint(), width: size.width - self.canvasWidth, height: size.height - self.canvasHeight)
        
//        self.zoomToFit(animated: false)
        if let newVisibleArea {
            print("new visible area: \(newVisibleArea.toString())")
//            self.zoom(to: newVisibleArea, animated: false)
//            self.zoomToArea(newVisibleArea, animated: false)
            self.zoomCenterTo(position: newVisibleArea.center, scale: previousZoom, animated: false)
        } else {
            print("zooming to center")
            self.zoomToCenter(scale: previousZoom, animated: false)
        }
//        if SMRect(self.visibleArea).contains(rect: self.canvasRect) {
//            self.zoomToCenter(scale: previousZoom, animated: false)
//        }
        
        print("applied visible area: \(SMRect(self.visibleArea).toString())")
        
        print("new canvas size: \(size.toString())")
        self.scrollViewDidZoom(self.scrollContainer)
        return self
    }
    
    
    
    public func zoomToVisibleArea() {
//        self.zoomToArea(SMRect(self.visibleArea), animated: true)
        self.zoom(to: SMRect(self.visibleArea), animated: true)
    }
    
    public func printVisibleArea() {
        print(SMRect(self.visibleArea))
    }
    
    @discardableResult
    public func setCanvasSize2(to size: SMSize) -> Self {
        let previousZoomScale = self.scrollContainer.zoomScale
//        guard let previousVisibleArea = SMRect(self.visibleArea).overlap(self.canvasRect) else {
//            return self
//        }
//        let previousVisibleAreaCenter = previousVisibleArea.center
//        let previousNormalizedCenterX = previousVisibleAreaCenter.x / self.canvasWidth
//        let previousNormalizedCenterY = previousVisibleAreaCenter.y / self.canvasHeight
//        print("previous visible area: \(previousVisibleArea.toString())")
//        print("previous visible area center: \(previousVisibleAreaCenter.toString())")
//        print("previous canvas size: \(SMSize(self.canvasSize).toString())")
//        print("previous normalised center x: \(previousNormalizedCenterX)")
//        print("previous normalised center y: \(previousNormalizedCenterY)")
        self.zoomTo(scale: 1.0, animated: false)
        self.canvasSize = size.cgSize
        self.canvasContainer.frame = CGRect(origin: CGPoint(), size: self.canvasSize)
        self.zoomTo(scale: previousZoomScale, animated: false)
//        self.zoomCenterTo(
//            position: SMPoint(
//                x: size.width*previousNormalizedCenterX,
//                y: size.height*previousNormalizedCenterY
//            ),
//            scale: previousZoomScale,
//            animated: false
//        )
//        print("post x: \(size.width*previousNormalizedCenterX)")
//        print("post y: \(size.height*previousNormalizedCenterY)")
        self.scrollViewDidZoom(self.scrollContainer)
        return self
    }
    
    // 17 -> 18
    // zoom in on middle
    // should end up in middle
    // does not end up in middle
    
    public func zoomToFit(animated: Bool) {
        let widthFraction = self.viewSize.width/self.canvasWidth
        let heightFraction = self.viewSize.height/self.canvasHeight
        let targetScale = min(widthFraction, heightFraction)
        self.zoomToCenter(scale: targetScale, animated: animated)
    }
    
    public func zoomToCenter(scale: Double? = nil, animated: Bool) {
        let targetScale = scale ?? self.zoomScale
        if let scale {
            self.zoomTo(scale: scale, animated: animated)
        }
        self.scrollContainer.setContentOffset(
            CGPoint(
                x: self.canvasWidth/2.0*targetScale - self.viewSize.width/2.0,
                y: self.canvasHeight/2.0*targetScale - self.viewSize.height/2.0
            ),
            animated: animated
        )
    }
    
    public func zoomCenterTo(position: SMPoint, scale: Double? = nil, animated: Bool) {
        let targetScale = scale ?? self.zoomScale
        if let scale {
            self.zoomTo(scale: scale, animated: animated)
        }
        self.scrollContainer.setContentOffset(
            CGPoint(
                x: position.x*targetScale - self.viewSize.width/2.0,
                y: position.y*targetScale - self.viewSize.height/2.0
            ),
            animated: animated
        )
    }
    
    // TODO: Current bugs to fix:
    // BUG 1
    // 1. Start with full family rendered
    // 2. Zoom to bottom right
    // 3. Set step to 1 (only render 1 family member)
    // Now it's stuck in the top left until you zoom again
    // BUG 2
    // 1. Run the app
    // 2. Canvas doesn't render until you start zooming/scrolling (do I need to call layoutIfNeeded()?)
    // TODO: Other problems popping up
    // Problems:
    // Zoom in max, and go to top left, then go from step 0 to 1 -> it gets stuck in the top right
    // When the canvas first loads in (don't zoom in yet) you can scroll down way further than you should be able to
    // Zoom in max, go to step 0 to 1, then go from step 1 to 0
    // Go to step 17, move viewport furthest right (to right edge), then go to step 16, it shouldn't have viewport outside visible area
    
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
    
    public func scrollTo(_ position: SMPoint, animated: Bool) {
        self.scrollContainer.setContentOffset(position.cgPoint, animated: animated)
    }
    
    public func zoomTo(scale: Double, animated: Bool) {
        self.scrollContainer.setZoomScale(scale, animated: animated)
    }
    
    public func zoom(to area: SMRect, animated: Bool) {
        self.scrollContainer.zoom(to: area.cgRect, animated: animated)
    }
    
    /// Performs better
    public func zoomToArea(_ area: SMRect, animated: Bool) {
        // TODO: Where i'm at
        print("VISIBLE AREA: \(SMRect(self.visibleArea).toString())")
        print("TARGET AREA: \(area.toString())")
        let widthFraction = self.viewSize.width/area.width
        let heightFraction = self.viewSize.height/area.height
        let targetScale = min(widthFraction, heightFraction)
        self.zoomTo(scale: targetScale, animated: animated)
        self.scrollContainer.setContentOffset(
            CGPoint(
                x: area.origin.x*targetScale,
                y: area.origin.y*targetScale
            ),
            animated: animated
        )
    }
    
}

/*
 public func zoomToFit(animated: Bool) {
     let widthFraction = self.viewSize.width/self.canvasWidth
     let heightFraction = self.viewSize.height/self.canvasHeight
     let targetScale = min(widthFraction, heightFraction)
     self.zoomToCenter(scale: targetScale, animated: animated)
 }
 
 public func zoomToCenter(scale: Double? = nil, animated: Bool) {
     let targetScale = scale ?? self.zoomScale
     if let scale {
         self.zoomTo(scale: scale, animated: animated)
     }
     self.scrollContainer.setContentOffset(
         CGPoint(
             x: self.canvasWidth/2.0*targetScale - self.viewSize.width/2.0,
             y: self.canvasHeight/2.0*targetScale - self.viewSize.height/2.0
         ),
         animated: animated
     )
 }
 
 public func zoomCenterTo(position: SMPoint, scale: Double? = nil, animated: Bool) {
     let targetScale = scale ?? self.zoomScale
     if let scale {
         self.zoomTo(scale: scale, animated: animated)
     }
     self.scrollContainer.setContentOffset(
         CGPoint(
             x: position.x*targetScale - self.viewSize.width/2.0,
             y: position.y*targetScale - self.viewSize.height/2.0
         ),
         animated: animated
     )
 }
 */
