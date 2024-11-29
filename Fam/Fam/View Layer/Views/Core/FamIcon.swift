//
//  FamIcon.swift
//  Fam
//
//  Created by Andre Pham on 30/10/2024.
//

import Foundation
import UIKit

class FamIcon: UIImageView {
    
    struct Config {
        public let image: UIImage?
        public let systemName: String?
        public let weight: UIImage.SymbolWeight?
        public let color: UIColor?
        public let size: Double?
        public let renderMode: RenderMode?
        
        init(
            image: UIImage? = nil,
            size: Double? = nil,
            renderMode: RenderMode? = nil
        ) {
            self.image = image
            self.systemName = nil
            self.size = size
            self.renderMode = renderMode
            self.weight = nil
            self.color = nil
        }
        
        init(
            systemName: String? = nil,
            size: Double? = nil,
            renderMode: RenderMode? = nil,
            weight: UIImage.SymbolWeight? = nil,
            color: UIColor? = nil
        ) {
            self.image = nil
            self.systemName = systemName
            self.size = size
            self.renderMode = renderMode
            self.weight = weight
            self.color = color
        }
        
        private init(
            image: UIImage?,
            systemName: String?,
            size: Double?,
            renderMode: RenderMode?,
            weight: UIImage.SymbolWeight?,
            color: UIColor?
        ) {
            self.image = image
            self.systemName = systemName
            self.size = size
            self.renderMode = renderMode
            self.weight = weight
            self.color = color
        }
        
        @discardableResult
        func merge(_ config: Self) -> Self {
            return Config(
                image: config.systemName == nil ? (config.image ?? self.image) : nil,
                systemName: config.image == nil ? (config.systemName ?? self.systemName) : nil,
                size: config.size ?? self.size,
                renderMode: config.renderMode ?? self.renderMode,
                weight: config.weight ?? self.weight,
                color: config.color ?? self.color
            )
        }
        
        func with(image: UIImage? = nil, size: Double? = nil, renderMode: RenderMode? = nil) -> Self {
            return Config(
                image: image ?? self.image,
                systemName: image == nil ? self.systemName : nil,
                size: size ?? self.size,
                renderMode: renderMode ?? self.renderMode,
                weight: self.weight,
                color: self.color
            )
        }
        
        func with(
            systemName: String? = nil,
            size: Double? = nil,
            renderMode: RenderMode? = nil,
            weight: UIImage.SymbolWeight? = nil,
            color: UIColor? = nil
        ) -> Self {
            return Config(
                image: systemName == nil ? self.image : nil,
                systemName: systemName ?? self.systemName,
                size: size ?? self.size,
                renderMode: renderMode ?? self.renderMode,
                weight: weight ?? self.weight,
                color: color ?? self.color
            )
        }
    }
    
    /// Render mode determines if the icon should render past the square dimensions
    /// E.g. see system symbol "character.textbox" - it should be rendered wide to not appear weirdly small
    /// This is handled on a case-by-case basis because it entirely depends on the padding the original icon has set
    enum RenderMode {
        case normal
        case wide
        case tall
    }
    
    private var config = Config(size: 26.0, renderMode: .normal, color: FamColors.black)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    func setup() {
        self.useAutoLayout()
            .refresh()
    }
    
    @discardableResult
    func setIcon(to config: Config) -> Self {
        if let image = config.image {
            self.setImage(to: image)
        } else if let systemName = config.systemName {
            self.setSymbol(systemName: systemName)
        }
        if let weight = config.weight {
            self.setWeight(to: weight)
        }
        if let color = config.color {
            self.setColor(to: color)
        }
        if let size = config.size {
            self.setSize(to: size)
        }
        if let renderMode = config.renderMode {
            self.setRenderMode(to: renderMode)
        }
        return self
    }
    
    @discardableResult
    func setImage(to image: UIImage) -> Self {
        self.image = image
        return self
    }
    
    @discardableResult
    func setSymbol(systemName: String) -> Self {
        if let image = UIImage(systemName: systemName) {
            if let weight = self.config.weight {
                self.image = image.withConfiguration(UIImage.SymbolConfiguration(weight: weight))
            } else {
                self.image = image
            }
            if let color = self.config.color {
                self.setColor(to: color)
            }
        } else {
            self.image = UIImage(systemName: "questionmark.circle.fill")!
            assertionFailure("Could not find system icon with name \(systemName)")
        }
        return self
    }
    
    @discardableResult
    func setSize(to size: Double) -> Self {
        self.config = self.config.with(size: size)
        self.renderSize()
        return self
    }
    
    @discardableResult
    func setRenderMode(to mode: RenderMode) -> Self {
        self.config = self.config.with(renderMode: mode)
        self.renderSize()
        return self
    }
    
    @discardableResult
    func renderNormal() -> Self {
        self.setRenderMode(to: .normal)
        return self
    }
    
    @discardableResult
    func renderWide() -> Self {
        self.setRenderMode(to: .wide)
        return self
    }
    
    @discardableResult
    func renderTall() -> Self {
        self.setRenderMode(to: .tall)
        return self
    }
    
    @discardableResult
    func setWeight(to weight: UIImage.SymbolWeight) -> Self {
        self.config = self.config.with(weight: weight)
        // Point size should never be used - we use width/height constraints to set size
        // This is so system icons and images can be used interchangeably
        let config = UIImage.SymbolConfiguration(weight: weight)
        self.image = self.image?.withConfiguration(config)
        return self
    }
    
    @discardableResult
    func setColor(to color: UIColor) -> Self {
        self.config = self.config.with(color: color)
        self.tintColor = color
        return self
    }
    
    @discardableResult
    private func renderSize() -> Self {
        guard let renderMode = self.config.renderMode, let size = self.config.size else {
            // These properties start with defaults
            // Assigning them to nil in the config just doesn't set them
            // They can't be assigned to nil as arguments to functions
            // So this branch should be impossible
            assertionFailure("Shouldn't be possible to set a render mode or size to nil")
            return self
        }
        self.removeWidthConstraint()
            .removeHeightConstraint()
        switch renderMode {
        case .normal:
            // Icons should always by default use scaleAspectFit for consistency in sizing
            self.setContentMode(to: .scaleAspectFit)
                .setWidthConstraint(to: size)
                .setHeightConstraint(to: size)
        case .wide:
            self.setContentMode(to: .scaleAspectFill)
                .setHeightConstraint(to: size)
        case .tall:
            self.setContentMode(to: .scaleAspectFill)
                .setWidthConstraint(to: size)
        }
        return self
    }
    
    @discardableResult
    private func setContentMode(to contentMode: UIView.ContentMode) -> Self {
        self.contentMode = contentMode
        return self
    }
    
    @discardableResult
    private func refresh() -> Self {
        self.setIcon(to: self.config)
        return self
    }
    
}
