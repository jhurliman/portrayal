//
//  GPUImageFlowDifferenceOfGaussiansFilter1MultiThreshold.h
//  Inkwell
//
//  Created by John Hurliman on 2/4/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#import "GPUImageTwoInputFilter.h"

@interface GPUImageFlowDifferenceOfGaussiansFilter1MultiThreshold : GPUImageTwoInputFilter

- (void)setImageSize:(CGSize)imageSize;

- (void)setSigmaM:(CGFloat)sigmaM;

- (void)setPhi:(CGFloat)phi;

- (void)setEpsilonX:(CGFloat)epsilon;

- (void)setEpsilonY:(CGFloat)epsilon;

- (void)setEpsilonZ:(CGFloat)epsilon;

@end
