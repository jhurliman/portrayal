//
//  Filter.swift
//  Portrayal
//
//  Created by John Hurliman on 2/5/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import Inkwell

struct FilterSlider {
    let name: String
    let min: Float
    let max: Float
    let defaultValue: Float
    var value: Float
}

protocol Filter {
    var name: String { get }
    var thumbnail: UIImage { get }
    var sliders: [FilterSlider] { get }
    var gpuFilter: GPUImageFilterGroup { get }
    
    func updateImage(newImage: UIImage)
    func processImage()
    func unload()
}

extension Filter {
    func updateImage(newImage: UIImage) { }
    func processImage() { }
    func unload() { gpuFilter.removeAllTargets() }
}
