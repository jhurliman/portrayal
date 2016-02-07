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
        Pencil(),
        Noir()
    ]
    
    @IBOutlet weak var gpuImageView: GPUImageView!
    @IBOutlet weak var sliderCollectionView: UICollectionView!
    @IBOutlet weak var filterCollectionView: UICollectionView!
    
    let picker = UIImagePickerController()
    var inputImage: UIImage?
    var inputGpuImage: GPUImagePicture?
    var currentFilter: Filter?
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentFilter = FILTERS[0]
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        GPUImageContext.sharedFramebufferCache().purgeAllUnassignedFramebuffers()
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        sliderCollectionView.performBatchUpdates(nil, completion: nil)
    }
    
    // MARK: - Filter Helpers
    
    func reset() {
        inputGpuImage?.removeAllTargets()
        gpuImageView.newFrameReadyAtTime(CMTime(), atIndex: 0)
        GPUImageContext.sharedFramebufferCache().purgeAllUnassignedFramebuffers()
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
        
        updateImage()
    }
    
    func updateImage() {
        inputGpuImage?.processImage()
        currentFilter?.processImage()
    }
    
    // MARK: - UI Handlers
    
    @IBAction func cameraTapped(sender: UIBarButtonItem) {
        picker.delegate = self
        picker.sourceType = .PhotoLibrary
        
        presentViewController(picker, animated: true, completion: nil)
    }
    
    @IBAction func saveTapped(sender: UIBarButtonItem) {
        guard let filter = currentFilter else { return }
        
        // Render to a UIImage
        filter.gpuFilter.useNextFrameForImageCapture()
        updateImage()
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
        updateImage()
    }
    
    // MARK: - UIImagePickerController Handlers
    
    func imagePickerController(picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String: AnyObject])
    {
        let image = (info[UIImagePickerControllerOriginalImage] as! UIImage)
            .resizeTo(IMAGE_SIZES[1])
        
        reset()
        picker.dismissViewControllerAnimated(true) { self.loadImage(image) }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - UICollectionView Handlers
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (collectionView == sliderCollectionView) {
            return currentFilter?.sliders.count ?? 0
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
        
        currentFilter?.unload()
        if let filter = FILTERS[safe: indexPath.item] {
            currentFilter = filter
            if let image = inputImage { loadImage(image) }
            sliderCollectionView.reloadData()
        }
    }
}
