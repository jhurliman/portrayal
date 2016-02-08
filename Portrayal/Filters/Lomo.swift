//
//  Lomo.swift
//  Portrayal
//
//  Created by John Hurliman on 2/7/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import Inkwell

class Lomo : Filter {
    let levels1: GPUImageLevelsFilter
    let toneCurve: GPUImageToneCurveFilter
    let unsharpMask: GPUImageUnsharpMaskFilter
    let saturation: GPUImageSaturationFilter
    let levels2: GPUImageLevelsFilter
    let colorBalance: GPUImageLookupFilter
    let lookupTexture: GPUImagePicture
    let boxBlur: GPUImageBoxBlurFilter
    let highpass: GPUImageSubtractBlendFilter
    let add: GPUImageAddBlendFilter
    let vignette: GPUImageVignetteFilter
    let irisBlur: GPUImageGaussianSelectiveBlurFilter
    
    let filterGroup: GPUImageFilterGroup
    var sliderArray: [FilterSlider] = [
        FilterSlider(name: "Aperture", min: 0, max: 0.85, defaultValue: 6.0/255.0),
        FilterSlider(name: "Gamma", min: 0.01, max: 2, defaultValue: 0.90),
        FilterSlider(name: "Exposure", min: 0.2, max: 1, defaultValue: 253.0/255.0),
        FilterSlider(name: "Balance", min: 0, max: 0.725, defaultValue: 0.07),
        FilterSlider(name: "Process", min: 0.02, max: 1, defaultValue: 0.85),
        FilterSlider(name: "Saturation", min: 0, max: 4, defaultValue: 2.0),
        FilterSlider(name: "Vignette", min: 0, max: 0.784, defaultValue: 0.5)
    ]
    
    init() {
        filterGroup = GPUImageFilterGroup()
        
        levels1 = GPUImageLevelsFilter()
        levels1.setMin(6.0/255.0, gamma: 0.90, max: 253.0/255.0, minOut: 0.07, maxOut: 0.85)
        
        toneCurve = GPUImageToneCurveFilter(ACV: "lomo-tonecurves")
        
        unsharpMask = GPUImageUnsharpMaskFilter()
        unsharpMask.blurRadiusInPixels = 2.0
        unsharpMask.intensity = 2.25
        
        saturation = GPUImageSaturationFilter()
        saturation.saturation = 2.0
        
        levels2 = GPUImageLevelsFilter()
        levels2.setMin(0.0, gamma: 1.00, max: 210.0/255.0, minOut: 0.0, maxOut: 1.0)
        
        colorBalance = GPUImageLookupFilter()
        lookupTexture = GPUImagePicture(image: UIImage(named: "lomo-lookup.png")!,
            smoothlyScaleOutput: false)
        
        boxBlur = GPUImageBoxBlurFilter()
        boxBlur.blurRadiusInPixels = 2.0
        highpass = GPUImageSubtractBlendFilter()
        
        add = GPUImageAddBlendFilter()
        
        vignette = GPUImageVignetteFilter()
        vignette.vignetteStart = 0.5
        vignette.vignetteEnd = 0.785
        
        irisBlur = GPUImageGaussianSelectiveBlurFilter()
        irisBlur.blurRadiusInPixels = 5.0
        irisBlur.excludeCircleRadius = 210.0/320.0
        irisBlur.excludeBlurSize = 40.0/320.0
        
        vignette.addTarget(levels1)
        levels1.addTarget(toneCurve)
        toneCurve.addTarget(irisBlur)
        irisBlur.addTarget(unsharpMask)
        unsharpMask.addTarget(saturation)
        saturation.addTarget(levels2)
        levels2.addTarget(colorBalance, atTextureLocation: 0)
        lookupTexture.addTarget(colorBalance, atTextureLocation: 1)
        colorBalance.addTarget(boxBlur)
        colorBalance.addTarget(highpass, atTextureLocation: 0)
        boxBlur.addTarget(highpass, atTextureLocation: 1)
        colorBalance.addTarget(add, atTextureLocation: 0)
        highpass.addTarget(add, atTextureLocation: 1)
        
        filterGroup.initialFilters = [vignette]
        filterGroup.terminalFilter = add
    }
    
    var name: String { get { return "Lomo" } }
    var thumbnail: UIImage { get { return UIImage(named: "thumbnail-lomo@3x.jpg")! } }
    var sliders: [FilterSlider] {
        get { return sliderArray }
        set(newValue) { sliderArray = newValue }
    }
    var gpuFilter: GPUImageFilterGroup { get { return filterGroup } }
    
    func processImage() {
        lookupTexture.processImage()
    }
    
    func sliderChanged(index: Int, value: Float) {
        let cgValue = CGFloat(value)
        
        switch (index) {
        case 0:
            levels1.setMin(
                cgValue,
                gamma: CGFloat(sliderArray[1].value),
                max: CGFloat(sliderArray[2].value),
                minOut: CGFloat(sliderArray[3].value),
                maxOut: CGFloat(sliderArray[4].value))
            break
        case 1:
            levels1.setMin(
                CGFloat(sliderArray[0].value),
                gamma: cgValue,
                max: CGFloat(sliderArray[2].value),
                minOut: CGFloat(sliderArray[3].value),
                maxOut: CGFloat(sliderArray[4].value))
            break
        case 2:
            levels1.setMin(
                CGFloat(sliderArray[0].value),
                gamma: CGFloat(sliderArray[1].value),
                max: cgValue,
                minOut: CGFloat(sliderArray[3].value),
                maxOut: CGFloat(sliderArray[4].value))
            break
        case 3:
            levels1.setMin(
                CGFloat(sliderArray[0].value),
                gamma: CGFloat(sliderArray[1].value),
                max: CGFloat(sliderArray[2].value),
                minOut: cgValue,
                maxOut: CGFloat(sliderArray[4].value))
            break
        case 4:
            levels1.setMin(
                CGFloat(sliderArray[0].value),
                gamma: CGFloat(sliderArray[1].value),
                max: CGFloat(sliderArray[2].value),
                minOut: CGFloat(sliderArray[3].value),
                maxOut: cgValue)
            break
        case 5: saturation.saturation = cgValue; break
        case 6: vignette.vignetteStart = cgValue; break
        default: break
        }
    }
}
