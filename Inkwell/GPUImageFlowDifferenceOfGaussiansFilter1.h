//
//  GPUImageFlowDifferenceOfGaussiansFilter1.h
//  Inkwell
//
//  Created by John Hurliman on 2/4/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#import "GPUImageTwoInputFilter.h"

@interface GPUImageFlowDifferenceOfGaussiansFilter1 : GPUImageTwoInputFilter

- (void)setImageSize:(CGSize)imageSize;

- (void)setSigmaM:(CGFloat)sigmaM;

- (void)setPhi:(CGFloat)phi;

- (void)setEpsilon:(CGFloat)epsilon;

@end
