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
    var filter: PencilSketchFilter
    var sliderArray = [
        FilterSlider(name: "Light", min: 0, max: 10, defaultValue: 0.5),
        FilterSlider(name: "Shadow", min: 0, max: 10, defaultValue: 3.5),
        FilterSlider(name: "Softness", min: 0, max: 8, defaultValue: 2),
        FilterSlider(name: "Detail", min: 0, max: 120, defaultValue: 35),
        FilterSlider(name: "Shade", min: -10, max: 100, defaultValue: 0),
        FilterSlider(name: "Right", min: -10, max: 100, defaultValue: 30),
        FilterSlider(name: "Left", min: -10, max: 100, defaultValue: 60),
        FilterSlider(name: "Contrast", min: 0.001, max: 2.5, defaultValue: 0.08)
    ]
    
    init() {
        let image = UIImage(named: "pencil-shading-01.jpg")!
        pencilTexture = GPUImagePicture(image: image, smoothlyScaleOutput: false)
        filter = PencilSketchFilter(imageSize: CGSize.zero,
            pencilTexture: pencilTexture)
    }
    
    var name: String { get { return "Sketch" } }
    var thumbnail: UIImage { get { return UIImage(named: "thumbnail-sketch@3x.jpg")! } }
    var sliders: [FilterSlider] {
        get { return sliderArray }
        set(newValue) { sliderArray = newValue }
    }
    var gpuFilter: GPUImageFilterGroup { get { return filter } }
    
    func load(input: GPUImageOutput, output: GPUImageInput) {
        filter = PencilSketchFilter(imageSize: CGSize.zero,
            pencilTexture: pencilTexture)
        input.addTarget(filter)
        filter.addTarget(output)
        
        // Update all of the filter parameters since we reloaded it
        filter.setSigmaE(CGFloat(sliderArray[0].value))
        filter.setSigmaR(CGFloat(sliderArray[1].value))
        filter.setSigmaSST(CGFloat(sliderArray[2].value))
        filter.setP(CGFloat(sliderArray[3].value))
        filter.setEpsilonX(CGFloat(sliderArray[4].value))
        filter.setEpsilonY(CGFloat(sliderArray[5].value))
        filter.setEpsilonZ(CGFloat(sliderArray[6].value))
        filter.setPhi(CGFloat(sliderArray[7].value))
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
        case 0: filter.setSigmaE(cgValue); break
        case 1: filter.setSigmaR(cgValue); break
        case 2: filter.setSigmaSST(cgValue); break
        case 3: filter.setP(cgValue); break
        case 4: filter.setEpsilonX(cgValue); break
        case 5: filter.setEpsilonY(cgValue); break
        case 6: filter.setEpsilonZ(cgValue); break
        case 7: filter.setPhi(cgValue); break
        default: break
        }
    }
}
