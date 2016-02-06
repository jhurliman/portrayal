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
    UINavigationControllerDelegate, UIImagePickerControllerDelegate,
    UICollectionViewDelegate, UICollectionViewDataSource {
    
    let IMAGE_SIZES: [CGFloat] = [1024, 2048, 3072, 3584]
    
    @IBOutlet weak var gpuImageView: GPUImageView!
    @IBOutlet weak var sliderLabel1: UILabel!
    @IBOutlet weak var sliderLabel2: UILabel!
    @IBOutlet weak var sliderLabel3: UILabel!
    @IBOutlet weak var slider1: UISlider!
    @IBOutlet weak var slider2: UISlider!
    @IBOutlet weak var slider3: UISlider!
    
    let picker = UIImagePickerController()
    var inputImage: GPUImagePicture?
    var currentFilter: Filter? = Pencil()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        GPUImageContext.sharedFramebufferCache().purgeAllUnassignedFramebuffers()
    }
    
    func reset() {
        inputImage?.removeAllTargets()
        gpuImageView.newFrameReadyAtTime(CMTime(), atIndex: 0)
        GPUImageContext.sharedFramebufferCache().purgeAllUnassignedFramebuffers()
    }
    
    func loadImage(image: UIImage) {
        let input = GPUImagePicture(image: image, smoothlyScaleOutput: true)
        inputImage = input
        
        if let filter = currentFilter {
//            filter.unload() // FIXME: Get unload working
            filter.load(input, output: gpuImageView)
            filter.updateImage(image)
        }
        
        updateImage()
    }
    
    func updateImage() {
        inputImage?.processImage()
        currentFilter?.processImage()
    }
    
    @IBAction func cameraTapped(sender: UIBarButtonItem) {
        picker.delegate = self
        picker.sourceType = .PhotoLibrary
        
        presentViewController(picker, animated: true, completion: nil)
    }
    
    @IBAction func saveTapped(sender: UIBarButtonItem) {
    }
    
    @IBAction func sliderValueChanged(sender: UISlider) {
        currentFilter?.sliderChanged(sender.tag, value: sender.value)
        updateImage()
    }
    
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
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
            "FilterCell", forIndexPath: indexPath) as! FilterCell
        
        return cell
    }
}
