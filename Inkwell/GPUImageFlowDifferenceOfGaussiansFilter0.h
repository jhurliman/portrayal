//
//  GPUImageFlowDifferenceOfGaussiansFilter0.h
//  Inkwell
//
//  Created by John Hurliman on 2/4/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#import "GPUImageTwoInputFilter.h"

@interface GPUImageFlowDifferenceOfGaussiansFilter0 : GPUImageTwoInputFilter

- (void)setImageSize:(CGSize)imageSize;

- (void)setSigmaE:(CGFloat)sigmaE;

- (void)setSigmaR:(CGFloat)sigmaR;

- (void)setP:(CGFloat)p;

@end
