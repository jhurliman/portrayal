//
//  UIView+Utils.swift
//  Portrayal
//
//  Created by John Hurliman on 2/8/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import UIKit

extension UIView {
    var pixelSize: CGSize {
        get {
            var size = self.bounds.size
            let scale = UIScreen.mainScreen().scale
            
            size.width *= scale
            size.height *= scale
            
            return size
        }
    }
}
