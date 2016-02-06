//
//  Pencil.swift
//  Portrayal
//
//  Created by John Hurliman on 2/5/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import Inkwell

class Pencil : Filter {
    let pencilTexture: GPUImagePicture
    let filter: PencilSketchFilter
    let sliderArray = [
        FilterSlider(name: "SigmaE", min: 0, max: 10, defaultValue: 1),
        FilterSlider(name: "SigmaR", min: 0, max: 10, defaultValue: 1),
        FilterSlider(name: "SigmaSST", min: 0, max: 8, defaultValue: 2)
    ]
    
    init() {
        let image = UIImage(named: "pencil-shading-01.jpg")!
        pencilTexture = GPUImagePicture(image: image, smoothlyScaleOutput: false)
        filter = PencilSketchFilter(imageSize: image.pixelSize,
            pencilTexture: pencilTexture)
    }
    
    var name: String { get { return "Pencil" } }
    var thumbnail: UIImage { get { return UIImage() } }
    var sliders: [FilterSlider] { get { return sliderArray } }
    var gpuFilter: GPUImageFilterGroup { get { return filter } }
    
    func load(input: GPUImageOutput, output: GPUImageInput) {
        input.addTarget(filter)
        pencilTexture.addTarget(filter)
        filter.addTarget(output)
    }
    
    func unload() {
        filter.removeAllTargets()
        pencilTexture.removeAllTargets()
    }
    
    func updateImage(newImage: UIImage) {
        filter.setImageSize(newImage.pixelSize)
        pencilTexture.addTarget(filter)
    }
    
    func processImage() {
        pencilTexture.processImage()
    }
    
    func sliderChanged(index: Int, value: Float) {
        let cgValue = CGFloat(value)
        
        switch (index) {
        case 0:
            filter.setSigmaE(cgValue)
            break
        case 1:
            filter.setSigmaR(cgValue)
            break
        case 2:
            filter.setSigmaSST(cgValue)
            break
        default:
            break
        }
    }
}
