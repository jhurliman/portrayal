//
//  Noir.swift
//  Portrayal
//
//  Created by John Hurliman on 2/6/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import Inkwell

class Noir : Filter {
    let filter: NoirFilter
    let filterGroup: GPUImageFilterGroup
    var sliderArray = [
        FilterSlider(name: "Color", min: 0.01, max: 1, defaultValue: 1.0),
        FilterSlider(name: "Cutoff", min: 0, max: 0.5, defaultValue: 0.2),
        FilterSlider(name: "Bleed", min: 0, max: 1.0, defaultValue: 0.1),
        FilterSlider(name: "Contrast", min: 0.2, max: 4.0, defaultValue: 1.4)
    ]
    
    init() {
        filter = NoirFilter()
        filterGroup = GPUImageFilterGroup()
        
        filterGroup.initialFilters = [filter]
        filterGroup.terminalFilter = filter
    }
    
    var name: String { get { return "Noir" } }
    var thumbnail: UIImage { get { return UIImage(named: "thumbnail-noir@3x.jpg")! } }
    var sliders: [FilterSlider] {
        get { return sliderArray }
        set(newValue) { sliderArray = newValue }
    }
    var gpuFilter: GPUImageFilterGroup { get { return filterGroup } }
    
    func sliderChanged(_ index: Int, value: Float) {
        switch (index) {
        case 0:
            let color = UIColor(hue: CGFloat(value), saturation: 1.0,
                brightness: 1.0, alpha: 1.0)
            filter.setColor(color)
            break
        case 1:
            filter.setThreshold(value)
            break
        case 2:
            filter.setSmoothing(value)
        case 3:
            filter.setContrast(value)
        default:
            break
        }
    }
}

class NoirFilter : GPUImageFilter {
    convenience override init() {
        let path = Bundle.main.path(forResource: "Noir", ofType: "fragsh")!
        let str = try! NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)
        
        self.init(fragmentShaderFrom: str as String)
        
        setColor(UIColor.red)
        setThreshold(0.2)
        setSmoothing(0.1)
        setContrast(1.4)
    }
    
    func setColor(_ color: UIColor) {
        let rgb = color.cgColor.components
        let vec3 = GPUVector3(one: GLfloat((rgb?[0])!), two: GLfloat((rgb?[1])!), three: GLfloat((rgb?[2])!))
        self.setFloatVec3(vec3, forUniformName: "chromaKeyColor")
    }
    
    func setThreshold(_ value: Float) {
        self.setFloat(value, forUniformName: "threshold")
    }
    
    func setSmoothing(_ value: Float) {
        self.setFloat(value, forUniformName: "smoothing")
    }
    
    func setContrast(_ value: Float) {
        self.setFloat(value, forUniformName: "contrast")
    }
}
