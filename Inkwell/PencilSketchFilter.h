//
//  PencilSketchFilter.h
//  Inkwell
//
//  Created by John Hurliman on 2/4/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#import "GPUImagePicture.h"
#import "GPUImageFilterGroup.h"

@interface PencilSketchFilter : GPUImageFilterGroup

- (id)initWithImageSize:(CGSize)imageSize pencilTexture:(GPUImagePicture *)pencilTexture;

- (void)setImageSize:(CGSize)imageSize;
- (void)setSigmaE:(CGFloat)sigmaE;
- (void)setSigmaR:(CGFloat)sigmaR;
- (void)setSigmaM:(CGFloat)sigmaM;
- (void)setP:(CGFloat)p;
- (void)setPhi:(CGFloat)phi;
- (void)setEpsilonX:(CGFloat)epsilon;
- (void)setEpsilonY:(CGFloat)epsilon;
- (void)setEpsilonZ:(CGFloat)epsilon;
- (void)setSigmaSST:(CGFloat)sigmaSST;
- (void)setSigmaBFD:(CGFloat)sigmaBFD;
- (void)setSigmaBFR:(CGFloat)sigmaBFR;
- (void)setBfeNumPasses:(int)numPasses;

@end
