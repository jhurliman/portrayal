//
//  UIImage+Utils.swift
//  Portrayal
//
//  Created by John Hurliman on 2/4/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import UIKit

extension UIImage {
    var pixelSize: CGSize {
        get {
            var size = self.size
            let scale = self.scale
            
            size.width *= scale
            size.height *= scale

            return size
        }
    }
    
    func resizeTo(size: CGFloat) -> UIImage {
        // Resize to clamp max height/width (preserving aspect ratio, and
        // rotate if needed
        let oldWidth = self.size.width
        let oldHeight = self.size.height
        let scaleFactor = min(1.0, size / max(oldWidth, oldHeight))
        let newSize = CGSize(width: oldWidth * scaleFactor,
            height: oldHeight * scaleFactor)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        self.drawInRect(CGRect(origin: CGPoint.zero, size: newSize))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
}
