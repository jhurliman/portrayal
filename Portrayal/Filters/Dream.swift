//
//  Dream.swift
//  Portrayal
//
//  Created by John Hurliman on 2/7/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import Inkwell

class Dream : Filter {
    let saturation: GPUImageSaturationFilter
    let contrast: GPUImageContrastFilter
    let bilateral: GPUImageBilateralFilter
    let gaussian1: GPUImageGaussianBlurFilter
    let gaussian2: GPUImageGaussianBlurFilter
    let gaussian3: GPUImageGaussianBlurFilter
    let background: DarkenBlend
    let edgeGaussian: GPUImageGaussianBlurPositionFilter
    let edge: LaplaceSketch
    let blurredEdge: GPUImageGaussianBlurFilter
    let unsharpEdge: GPUImageUnsharpMaskFilter
    let finalBlend: GPUImageSubtractBlendFilter
    
    let filterGroup: GPUImageFilterGroup
    var sliderArray: [FilterSlider] = [
        FilterSlider(name: "Saturation", min: 0, max: 2, defaultValue: 1.3),
        FilterSlider(name: "Contrast", min: 0.2, max: 4, defaultValue: 1.1),
        FilterSlider(name: "Tracing", min: 0, max: 8.0, defaultValue: 2.0),
        FilterSlider(name: "Glow", min: 0, max: 10.0, defaultValue: 5.0),
        FilterSlider(name: "Ink", min: 0, max: 38.0/255.0, defaultValue: 4.0/255.0),
        FilterSlider(name: "Cleanup", min: 0, max: 1.0, defaultValue: 0.8)
    ]
    
    init() {
        filterGroup = GPUImageFilterGroup()
        
        // Preprocessing
        
        saturation = GPUImageSaturationFilter()
        saturation.saturation = 1.3
        
        contrast = GPUImageContrastFilter()
        contrast.contrast = 1.1
        
        bilateral = GPUImageBilateralFilter()
        bilateral.distanceNormalizationFactor = 2.0
        
        // Background
        
        gaussian1 = GPUImageGaussianBlurFilter()
        gaussian1.blurRadiusInPixels = 5.0
        
        gaussian2 = GPUImageGaussianBlurFilter()
        gaussian2.blurRadiusInPixels = 5.0
        
        gaussian3 = GPUImageGaussianBlurFilter()
        gaussian3.blurRadiusInPixels = 5.0
        
        background = DarkenBlend()
        
        saturation.addTarget(contrast)
        contrast.addTarget(bilateral)
        bilateral.addTarget(gaussian1)
        gaussian1.addTarget(gaussian2)
        gaussian2.addTarget(gaussian3)
        gaussian3.addTarget(background, atTextureLocation: 0)
        contrast.addTarget(background, atTextureLocation: 1)
        
        // Edges
        
        edgeGaussian = GPUImageGaussianBlurPositionFilter()
        edgeGaussian.blurSize = 0.3
        
        edge = LaplaceSketch()
        edge.setImageSize(CGSize.zero)
        edge.setThreshold(4.0 / 255.0)
        edge.setLuminanceOffset(0.8)
        
        blurredEdge = GPUImageGaussianBlurFilter()
        blurredEdge.blurRadiusInPixels = 1.0
        
        unsharpEdge = GPUImageUnsharpMaskFilter()
        unsharpEdge.blurRadiusInPixels = 1.0
        unsharpEdge.intensity = 3.0
        
        bilateral.addTarget(edgeGaussian)
        edgeGaussian.addTarget(edge)
        edge.addTarget(blurredEdge)
        blurredEdge.addTarget(unsharpEdge)
        
        // Final blend
        
        finalBlend = GPUImageSubtractBlendFilter()
        
        background.addTarget(finalBlend, atTextureLocation: 0)
        unsharpEdge.addTarget(finalBlend, atTextureLocation: 1)
        
        filterGroup.initialFilters = [saturation]
        filterGroup.terminalFilter = finalBlend
    }
    
    var name: String { get { return "Dream" } }
    var thumbnail: UIImage { get { return UIImage(named: "thumbnail-dream@3x.jpg")! } }
    var sliders: [FilterSlider] {
        get { return sliderArray }
        set(newValue) { sliderArray = newValue }
    }
    var gpuFilter: GPUImageFilterGroup { get { return filterGroup } }
    
    func updateImage(newImage: UIImage) {
        edge.setImageSize(newImage.pixelSize)
    }
    
    func sliderChanged(index: Int, value: Float) {
        let cgValue = CGFloat(value)
        
        switch (index) {
        case 0: saturation.saturation = cgValue; break
        case 1: contrast.contrast = cgValue; break
        case 2: bilateral.distanceNormalizationFactor = cgValue; break
        case 3: gaussian1.blurRadiusInPixels = cgValue
                gaussian2.blurRadiusInPixels = cgValue
                gaussian3.blurRadiusInPixels = cgValue
                break
        case 4: edge.setThreshold(value); break
        case 5: edge.setLuminanceOffset(value); break
        default: break
        }
    }
}

// Darken blend with alpha preservation
class DarkenBlend : GPUImageTwoInputFilter {
    convenience override init() {
        let path = NSBundle.mainBundle().pathForResource("DarkenBlend", ofType: "fragsh")!
        let str = try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)
        
        self.init(fragmentShaderFromString: str as String)
    }
}

class LaplaceSketch : GPUImageFilter {
    convenience override init() {
        let path = NSBundle.mainBundle().pathForResource("LaplaceSketch", ofType: "fragsh")!
        let str = try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)
        
        self.init(fragmentShaderFromString: str as String)
        
        setImageSize(CGSize(width: 256, height: 256))
        setThreshold(4.0 / 255.0)
        setLuminanceOffset(0.8)
    }
    
    func setImageSize(size: CGSize) {
        setSize(size, forUniformName: "imageSize")
    }
    
    func setThreshold(value: Float) {
        setFloat(value, forUniformName: "threshold")
    }
    
    func setLuminanceOffset(value: Float) {
        setFloat(value, forUniformName: "luminanceOffset")
    }
}
