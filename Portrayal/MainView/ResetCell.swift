//
//  ResetCell.swift
//  Portrayal
//
//  Created by John Hurliman on 2/8/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import UIKit

class ResetCell : UICollectionViewCell {
    weak var controller: MainViewController?
    
    @IBAction func resetTapped(_ sender: UIButton) {
        controller?.resetCurrentSliders()
    }
}
