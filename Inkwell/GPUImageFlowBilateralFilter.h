//
//  GPUImageFlowBilateralFilter.h
//  Inkwell
//
//  Created by John Hurliman on 2/4/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#import "GPUImageTwoInputFilter.h"

@interface GPUImageFlowBilateralFilter : GPUImageTwoInputFilter

- (void)setImageSize:(CGSize)imageSize;

- (void)setSigmaD:(CGFloat)sigmaD;

- (void)setSigmaR:(CGFloat)sigmaR;

- (void)setNumBlurPasses:(int)passes;

@end
