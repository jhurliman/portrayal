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
    
    init(name: String, min: Float, max: Float, defaultValue: Float) {
        self.name = name
        self.min = min
        self.max = max
        self.defaultValue = defaultValue
        self.value = defaultValue
    }
}

protocol Filter {
    var name: String { get }
    var thumbnail: UIImage { get }
    var sliders: [FilterSlider] { get set }
    var gpuFilter: GPUImageFilterGroup { get }
    
    func load(_ input: GPUImageOutput, output: GPUImageInput)
    func unload()
    func updateImage(_ newImage: UIImage)
    func processImage()
    func sliderChanged(_ index: Int, value: Float)
}

extension Filter {
    func load(_ input: GPUImageOutput, output: GPUImageInput) {
        input.addTarget(gpuFilter)
        gpuFilter.addTarget(output)
    }
    func unload() {
        gpuFilter.removeAllTargets()
    }
    func updateImage(_ newImage: UIImage) { }
    func processImage() { }
    func sliderChanged(_ index: Int, value: Float) { }
}
