//
//  MainViewController.swift
//  Portrayal
//
//  Created by John Hurliman on 2/4/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import UIKit
import Inkwell

class MainViewController : UIViewController,
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate,
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout
{
    let IMAGE_SIZES: [CGFloat] = [1024, 2048, 3072, 3584]
    let SLIDER_CELL_HEIGHT = CGFloat(34)
    let FILTER_CELL_SIZE = CGSize(width: 98, height: 128)
    let FILTERS: [Filter] = [
        Dream(),
        Pencil(),
        Comic(),
        Lomo(),
        Noir()
    ]
    
    @IBOutlet weak var gpuImageView: GPUImageView!
    @IBOutlet weak var sliderCollectionView: UICollectionView!
    @IBOutlet weak var filterCollectionView: UICollectionView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var photoButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    let picker = UIImagePickerController()
    var inputImage: UIImage?
    var largeInputImage: UIImage?
    var inputGpuImage: GPUImagePicture?
    var currentFilter: Filter?
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar.clipsToBounds = true
        currentFilter = FILTERS[0]
        
        photoButtonCTA()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        GPUImageContext.sharedFramebufferCache().purgeAllUnassignedFramebuffers()
    }
    
    // MARK: - Misc Helpers
    
    func photoButtonCTA() {
        guard let view = photoButton.value(forKey: "view") as? UIView
            else { return }
        
        view.layer.shadowColor = UIColor.white.cgColor
        view.layer.shadowOffset = CGSize.zero
        view.layer.shadowRadius = 8.0
        view.layer.shadowOpacity = 0.0
        
        let animation = CABasicAnimation(keyPath: "shadowOpacity")
        animation.fromValue = NSNumber(value: 0.0 as Float)
        animation.toValue = NSNumber(value: 1.0 as Float)
        animation.duration = 1.5
        animation.autoreverses = true
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.repeatCount = 10
        animation.isRemovedOnCompletion = true
        view.layer.add(animation, forKey: "shadowOpacity")
    }
    
    func resetCurrentSliders() {
        guard var filter = currentFilter else { return }
        
        var i = 0
        filter.sliders = filter.sliders.map {
            (slider: FilterSlider) -> FilterSlider in
            var mutableSlider = slider
            mutableSlider.value = slider.defaultValue
            
            if let cell = sliderCollectionView.cellForItem(
                at: IndexPath(item: i, section: 0)) as? SliderCell
            {
                cell.slider.value = mutableSlider.value
            }
            filter.sliderChanged(i, value: mutableSlider.value)
            i = i + 1
            
            return mutableSlider
        }
        
        processImage()
    }
  
    func previewPixelSize(_ image: UIImage, maxDimension: CGFloat = 1024.0) -> CGSize {
        let src = image.pixelSize
        var dst = gpuImageView.pixelSize
        dst.width = min(dst.width, maxDimension)
        dst.height = min(dst.height, maxDimension)
        let scale = min(dst.width / src.width, dst.height / src.height)
        
        return CGSize(width: src.width * scale, height: src.height * scale)
    }
    
    // MARK: - Filter Helpers
    
    func reset() {
        inputGpuImage?.removeAllTargets()
        // Reset the on-screen image
        gpuImageView.newFrameReady(at: CMTime(), at: 0)
    }
    
    func loadImage(_ image: UIImage) {
        inputGpuImage?.removeAllTargets()
        inputGpuImage = nil
        
        let gpuImage = GPUImagePicture(image: image, smoothlyScaleOutput: true)
        inputImage = image
        inputGpuImage = gpuImage
        
        if let filter = currentFilter {
            filter.load(gpuImage!, output: gpuImageView)
            filter.updateImage(image)
        }
        
        processImage()
        
        // Show UI that is hidden when the app first starts
        sliderCollectionView.isHidden = false
        shareButton.isEnabled = true
        
        // Now that the pipeline is up and running, drop any extra framebuffers
        // we're not using
        GPUImageContext.sharedFramebufferCache().purgeAllUnassignedFramebuffers()
    }
    
    func processImage() {
        inputGpuImage?.processImage()
        currentFilter?.processImage()
    }
    
    // MARK: - UI Handlers
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        // Cancel the call-to-action animation as soon as the camera button is
        // tapped
        if let view = photoButton.value(forKey: "view") as? UIView {
            view.layer.removeAnimation(forKey: "shadowOpacity")
        }
        
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        guard let filter = currentFilter else { return }
        guard let largeInput = largeInputImage else { return }
        guard let screenInput = inputImage else { return }
        
        loadImage(largeInput)
        
        // Render to a UIImage
        filter.gpuFilter.useNextFrameForImageCapture()
        processImage()
        guard let image = filter.gpuFilter.imageFromCurrentFramebuffer()
            else { return }
        
        loadImage(screenInput)
        
        // Create share text based on the filter used
        let verb: String
        if filter is Dream { verb = "Painted" }
        else if filter is Pencil { verb = "Sketched" }
        else if filter is Comic { verb = "Drawn" }
        else if filter is Lomo { verb = "Processed" }
        else if filter is Noir { verb = "Illustrated" }
        else { verb = "Created" }
        let text = NSString(string: "\(verb) in #Portrayal")
        
        // iOS share sheet
        let activityViewController = UIActivityViewController(
            activityItems: [text, image], applicationActivities: nil)
        present(activityViewController, animated: true, completion: {})
    }
    
    func sliderValueChanged(_ sender: UISlider) {
        guard var filter = currentFilter else { return }
        
        filter.sliderChanged(sender.tag, value: sender.value)
        filter.sliders[safe: sender.tag]?.value = sender.value
        processImage()
    }
    
    // MARK: - UIImagePickerController Handlers
    
    private func imagePickerController(_ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String: Any])
    {
        let fullImage = (info[UIImagePickerController.InfoKey.originalImage.rawValue] as! UIImage)
        largeInputImage = fullImage.resizeWithMaxDimension(IMAGE_SIZES[1])
        let image = fullImage.resizeTo(previewPixelSize(fullImage))
        
        reset()
        picker.dismiss(animated: true) { self.loadImage(image) }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UICollectionView Handlers
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (collectionView == sliderCollectionView) {
            if let filter = currentFilter { return filter.sliders.count + 1 }
            return 0
        } else {
            return FILTERS.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        if (collectionView == sliderCollectionView) {
            return CGSize(width: collectionView.bounds.width, height: SLIDER_CELL_HEIGHT)
        } else {
            return FILTER_CELL_SIZE
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        if (collectionView == sliderCollectionView) {
            if indexPath.item == currentFilter?.sliders.count {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "ResetCell", for: indexPath)
                guard let resetCell = cell as? ResetCell else { return cell }
                resetCell.controller = self
                return resetCell
            }
            
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "SliderCell", for: indexPath)
            guard let sliderCell = cell as? SliderCell else { return cell }
            guard let slider = currentFilter?.sliders[safe: indexPath.item] else { return cell }
            
            sliderCell.name.text = slider.name
            sliderCell.slider.minimumValue = slider.min
            sliderCell.slider.maximumValue = slider.max
            sliderCell.slider.value = slider.value
            sliderCell.slider.tag = indexPath.item
            sliderCell.controller = self
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "FilterCell", for: indexPath)
            guard let filterCell = cell as? FilterCell else { return cell }
            guard let filter = FILTERS[safe: indexPath.item] else { return cell }
            
            filterCell.name.text = filter.name
            filterCell.image.image = filter.thumbnail
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath)
    {
        if (collectionView == sliderCollectionView) { return }
        
        if let filter = FILTERS[safe: indexPath.item] {
            if filter.name == currentFilter?.name { return }
            
            currentFilter?.unload()
            currentFilter = filter
            if let image = inputImage { loadImage(image) }
            sliderCollectionView.reloadData()
        }
    }
}
