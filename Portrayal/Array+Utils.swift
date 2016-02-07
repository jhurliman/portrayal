//
//  Array+Utils.swift
//  Portrayal
//
//  Created by John Hurliman on 2/5/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import Foundation

extension Array {
    subscript (safe index: Int) -> Element? {
        get {
            return indices ~= index ? self[index] : nil
        }
        set(newValue) {
            if (indices ~= index) {
                if let v = newValue {
                    self[index] = v
                } else {
                    self.removeAtIndex(index)
                }
            }
        }
    }
}
