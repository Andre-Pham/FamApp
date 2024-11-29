//
//  FamImage.swift
//  Fam
//
//  Created by Andre Pham on 14/6/2023.
//

import Foundation
import UIKit

class FamImage: UIImageView {
    
    public var imageSize: CGSize? {
        return self.image?.size
    }
    
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
            .setContentMode(to: .scaleAspectFill)
    }
    
    @discardableResult
    func setContentMode(to contentMode: UIView.ContentMode) -> Self {
        self.contentMode = contentMode
        return self
    }
    
    @discardableResult
    func setImage(_ image: UIImage) -> Self {
        self.image = image
        return self
    }
    
    @discardableResult
    func setImage(_ image: CGImage) -> Self {
        self.image = UIImage(cgImage: image)
        return self
    }
    
    @discardableResult
    func resetImage() -> Self {
        self.image = nil
        return self
    }
    
}
