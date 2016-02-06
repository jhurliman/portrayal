//
//  Inkwell.h
//  Inkwell
//
//  Created by John Hurliman on 2/4/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for Inkwell.
FOUNDATION_EXPORT double InkwellVersionNumber;

//! Project version string for Inkwell.
FOUNDATION_EXPORT const unsigned char InkwellVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Inkwell/PublicHeader.h>

#import "GPUImage.h"
#import "GPUImageFASTCornerDetectionFilter.h"
#import "GPUImageHighlightShadowTintFilter.h"
#import "GPUImageMovieComposition.h"
#import "GPUImagePicture+TextureSubimage.h"
#import "GPUImageSkinToneFilter.h"
#import "GPUImageVibranceFilter.h"

#import "GPUImageEdgeTangentFlowFilter.h"
#import "GPUImageFlowBilateralFilter.h"
#import "GPUImageFlowDifferenceOfGaussiansFilter0.h"
#import "GPUImageFlowDifferenceOfGaussiansFilter1.h"
#import "GPUImageFlowDifferenceOfGaussiansFilter1MultiThreshold.h"
#import "GPUImageLABToRGBFilter.h"
#import "GPUImageRGBToLABFilter.h"
#import "GPUImageStructureTensorFilter.h"

#import "InkwellFilter.h"
#import "InkwellColorFilter.h"
#import "PencilSketchFilter.h"
