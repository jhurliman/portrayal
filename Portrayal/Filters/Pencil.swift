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
    
    init() {
        let image = UIImage(named: "pencil-shading-01.jpg")!
        pencilTexture = GPUImagePicture(image: image, smoothlyScaleOutput: false)
        filter = PencilSketchFilter(imageSize: image.pixelSize,
            pencilTexture: pencilTexture)
        
        pencilTexture.addTarget(filter)
    }
    
    var name: String { get { return "Pencil" } }
    var thumbnail: UIImage { get { return UIImage() } }
    var sliders: [FilterSlider] { get { return [] } }
    var gpuFilter: GPUImageFilterGroup { get { return filter } }
    
    func updateImage(newImage: UIImage) {
        filter.setImageSize(newImage.pixelSize)
        pencilTexture.addTarget(filter)
    }
    
    func processImage() {
        pencilTexture.processImage()
    }
    
    func unload() {
        pencilTexture.removeAllTargets()
        filter.removeAllTargets()
    }
}
