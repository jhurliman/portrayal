//
//  SliderCell.swift
//  Portrayal
//
//  Created by John Hurliman on 2/5/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import UIKit

class SliderCell : UICollectionViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var slider: UISlider!
    
    weak var controller: MainViewController?
    
    @IBAction func sliderValueChanged(sender: UISlider) {
        controller?.sliderValueChanged(sender)
    }
}
