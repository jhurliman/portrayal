//
//  Comic.swift
//  Portrayal
//
//  Created by John Hurliman on 2/7/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import Inkwell

class Comic : Filter {
    let bilateral: GPUImageBilateralFilter
    let saturation: GPUImageSaturationFilter
    let halftone: ColorHalftone
    let halftoneBlend: GPUImageLinearBurnBlendFilter
    let inkwell: InkwellFilter
    let median: GPUImageMedianFilter
    let invert: GPUImageColorInvertFilter
    let lineBlend: GPUImageSubtractBlendFilter
    let paperTexture: GPUImagePicture
    let paperBlend: TextureBlend
    
    let filterGroup: GPUImageFilterGroup
    var sliderArray: [FilterSlider] = [
        FilterSlider(name: "Halftone", min: 0, max: 1.0, defaultValue: 0.7),
        FilterSlider(name: "Dot Size", min: 0.001, max: 0.02, defaultValue: 0.01),
        FilterSlider(name: "Lines", min: 0, max: 10, defaultValue: 1.6),
        FilterSlider(name: "Saturation", min: 0, max: 4, defaultValue: 2.0),
        FilterSlider(name: "Smoothing", min: 0, max: 8, defaultValue: 4.0)
    ]
    
    init() {
        filterGroup = GPUImageFilterGroup()
        
        // Background color
        
        bilateral = GPUImageBilateralFilter()
        bilateral.distanceNormalizationFactor = 4.0
        
        saturation = GPUImageSaturationFilter()
        saturation.saturation = 2.0
        
        // Halftone dots
        
        halftone = ColorHalftone()
        
        halftoneBlend = GPUImageLinearBurnBlendFilter()
        
        // Ink lines
        
        inkwell = InkwellFilter(imageSize: CGSize.zero)
        inkwell.setSigmaE(1.0)
        inkwell.setSigmaR(1.6)
        inkwell.setSigmaSST(1.0)
        inkwell.setSigmaM(2.0)
        inkwell.setP(100.0)
        inkwell.setPhi(0.01)
        inkwell.setEpsilon(0.0)
        inkwell.setSigmaBFD(3.0)
        inkwell.setSigmaBFR(0.0425)
        inkwell.setBfeNumPasses(1)
        
        median = GPUImageMedianFilter()
        
        invert = GPUImageColorInvertFilter()
        
        lineBlend = GPUImageSubtractBlendFilter()
        
        // Paper texture blending
        
        let image = UIImage(named: "texture-paper-01.jpg")!
        paperTexture = GPUImagePicture(image: image, smoothlyScaleOutput: false)
        
        paperBlend = TextureBlend()
        paperBlend.setInputSize(CGSize.zero, atIndex: 0)
        
        // Wire everything up
        
        bilateral.addTarget(saturation)
        saturation.addTarget(halftone)
        saturation.addTarget(halftoneBlend, atTextureLocation: 0)
        halftone.addTarget(halftoneBlend, atTextureLocation: 1)
        inkwell.addTarget(median)
        median.addTarget(invert)
        halftoneBlend.addTarget(lineBlend, atTextureLocation: 0)
        invert.addTarget(lineBlend, atTextureLocation: 1)
        paperTexture.addTarget(paperBlend, atTextureLocation: 0)
        lineBlend.addTarget(paperBlend, atTextureLocation: 1)
        
        filterGroup.initialFilters = [bilateral, inkwell]
        filterGroup.terminalFilter = paperBlend
    }
    
    var name: String { get { return "Comic" } }
    var thumbnail: UIImage { get { return UIImage(named: "thumbnail-comic@3x.jpg")! } }
    var sliders: [FilterSlider] {
        get { return sliderArray }
        set(newValue) { sliderArray = newValue }
    }
    var gpuFilter: GPUImageFilterGroup { get { return filterGroup } }
    
    func updateImage(newImage: UIImage) {
        inkwell.setImageSize(newImage.pixelSize)
        paperBlend.setInputSize(newImage.pixelSize, atIndex: 0)
        paperBlend.forceProcessingAtSize(newImage.pixelSize)
    }
    
    func processImage() {
        paperTexture.processImage()
    }
    
    func sliderChanged(index: Int, value: Float) {
        switch (index) {
        case 0: halftone.setThreshold(value); break
        case 1: halftone.setScale(value); break
        case 2: inkwell.setSigmaR(CGFloat(value)); break
        case 3: saturation.saturation = CGFloat(value); break
        case 4: bilateral.distanceNormalizationFactor = CGFloat(value); break
        default: break
        }
    }
}

class ColorHalftone : GPUImageFilter {
    convenience override init() {
        let path = NSBundle.mainBundle().pathForResource("ColorHalftone", ofType: "fragsh")!
        let str = try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)
        
        self.init(fragmentShaderFromString: str as String)
        
        setDotSize(0.4)
        setThreshold(0.7)
        setStepThresholdMin(0.6)
        setStepThresholdMax(1.176)
        setScale(0.01)
    }
    
    func setDotSize(value: Float) {
        setFloat(value, forUniformName: "dotSize")
    }
    
    func setThreshold(value: Float) {
        setFloat(value, forUniformName: "threshold")
    }
    
    func setStepThresholdMin(value: Float) {
        setFloat(value, forUniformName: "stepThresholdMin")
    }
    
    func setStepThresholdMax(value: Float) {
        setFloat(value, forUniformName: "stepThresholdMax")
    }
    
    func setScale(value: Float) {
        setFloat(value, forUniformName: "scale")
    }
}

class TextureBlend : GPUImageTwoInputFilter {
    convenience override init() {
        let path = NSBundle.mainBundle().pathForResource("TextureBlend", ofType: "fragsh")!
        let str = try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)
        
        self.init(fragmentShaderFromString: str as String)
    }
}
