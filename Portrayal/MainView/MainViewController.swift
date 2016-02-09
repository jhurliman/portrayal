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
    var inputGpuImage: GPUImagePicture?
    var currentFilter: Filter?
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar.clipsToBounds = true
        currentFilter = FILTERS[0]
        
        photoButtonCTA()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        GPUImageContext.sharedFramebufferCache().purgeAllUnassignedFramebuffers()
    }
    
    // MARK: - Misc Helpers
    
    func photoButtonCTA() {
        guard let view = photoButton.valueForKey("view") as? UIView
            else { return }
        
        view.layer.shadowColor = UIColor.whiteColor().CGColor
        view.layer.shadowOffset = CGSize.zero
        view.layer.shadowRadius = 8.0
        view.layer.shadowOpacity = 0.0
        
        let animation = CABasicAnimation(keyPath: "shadowOpacity")
        animation.fromValue = NSNumber(float: 0.0)
        animation.toValue = NSNumber(float: 1.0)
        animation.duration = 1.5
        animation.autoreverses = true
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.repeatCount = 10
        animation.removedOnCompletion = true
        view.layer.addAnimation(animation, forKey: "shadowOpacity")
    }
    
    func resetCurrentSliders() {
        guard var filter = currentFilter else { return }
        
        var i = 0
        filter.sliders = filter.sliders.map {
            (var slider: FilterSlider) -> FilterSlider in
            slider.value = slider.defaultValue
            
            if let cell = sliderCollectionView.cellForItemAtIndexPath(
                NSIndexPath(forItem: i, inSection: 0)) as? SliderCell
            {
                cell.slider.value = slider.value
            }
            filter.sliderChanged(i++, value: slider.value)
            
            return slider
        }
        
        processImage()
    }
    
    // MARK: - Filter Helpers
    
    func reset() {
        inputGpuImage?.removeAllTargets()
        // Reset the on-screen image
        gpuImageView.newFrameReadyAtTime(CMTime(), atIndex: 0)
    }
    
    func loadImage(image: UIImage) {
        inputGpuImage?.removeAllTargets()
        inputGpuImage = nil
        
        let gpuImage = GPUImagePicture(image: image, smoothlyScaleOutput: true)
        inputImage = image
        inputGpuImage = gpuImage
        
        if let filter = currentFilter {
            filter.load(gpuImage, output: gpuImageView)
            filter.updateImage(image)
        }
        
        processImage()
        
        // Show UI that is hidden when the app first starts
        sliderCollectionView.hidden = false
        shareButton.enabled = true
        
        // Now that the pipeline is up and running, drop any extra framebuffers
        // we're not using
        GPUImageContext.sharedFramebufferCache().purgeAllUnassignedFramebuffers()
    }
    
    func processImage() {
        inputGpuImage?.processImage()
        currentFilter?.processImage()
    }
    
    // MARK: - UI Handlers
    
    @IBAction func cameraTapped(sender: UIBarButtonItem) {
        // Cancel the call-to-action animation as soon as the camera button is
        // tapped
        if let view = photoButton.valueForKey("view") as? UIView {
            view.layer.removeAnimationForKey("shadowOpacity")
        }
        
        picker.delegate = self
        picker.sourceType = .PhotoLibrary
        presentViewController(picker, animated: true, completion: nil)
    }
    
    @IBAction func saveTapped(sender: UIBarButtonItem) {
        guard let filter = currentFilter else { return }
        
        // Render to a UIImage
        filter.gpuFilter.useNextFrameForImageCapture()
        processImage()
        guard let image = filter.gpuFilter.imageFromCurrentFramebuffer()
            else { return }
        
        // Create share text based on the filter used
        let verb: String
        if filter is Pencil { verb = "Drawn" }
        else if filter is Noir { verb = "Illustrated" }
        else { verb = "Created" }
        let text = NSString(string: "\(verb) in #Portrayal")
        
        // iOS share sheet
        let activityViewController = UIActivityViewController(
            activityItems: [text, image], applicationActivities: nil)
        presentViewController(activityViewController, animated: true, completion: {})
    }
    
    func sliderValueChanged(sender: UISlider) {
        guard var filter = currentFilter else { return }
        
        filter.sliderChanged(sender.tag, value: sender.value)
        filter.sliders[safe: sender.tag]?.value = sender.value
        processImage()
    }
    
    // MARK: - UIImagePickerController Handlers
    
    func imagePickerController(picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String: AnyObject])
    {
        let image = (info[UIImagePickerControllerOriginalImage] as! UIImage)
            .resizeTo(IMAGE_SIZES[0])
        
        reset()
        picker.dismissViewControllerAnimated(true) { self.loadImage(image) }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - UICollectionView Handlers
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (collectionView == sliderCollectionView) {
            if let filter = currentFilter { return filter.sliders.count + 1 }
            return 0
        } else {
            return FILTERS.count
        }
    }
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        if (collectionView == sliderCollectionView) {
            return CGSize(width: collectionView.bounds.width, height: SLIDER_CELL_HEIGHT)
        } else {
            return FILTER_CELL_SIZE
        }
    }
    
    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        if (collectionView == sliderCollectionView) {
            if indexPath.item == currentFilter?.sliders.count {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
                    "ResetCell", forIndexPath: indexPath)
                guard let resetCell = cell as? ResetCell else { return cell }
                resetCell.controller = self
                return resetCell
            }
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
                "SliderCell", forIndexPath: indexPath)
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
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
                "FilterCell", forIndexPath: indexPath)
            guard let filterCell = cell as? FilterCell else { return cell }
            guard let filter = FILTERS[safe: indexPath.item] else { return cell }
            
            filterCell.name.text = filter.name
            filterCell.image.image = filter.thumbnail
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath)
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
