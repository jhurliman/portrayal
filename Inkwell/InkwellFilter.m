//
//  InkwellFilter.m
//  Inkwell
//
//  Created by John Hurliman on 2/4/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#import "GPUImagePicture.h"
#import "GPUImageGaussianBlurFilter.h"
#import "InkwellFilter.h"
#import "GPUImageStructureTensorFilter.h"
#import "GPUImageEdgeTangentFlowFilter.h"
#import "GPUImageFlowBilateralFilter.h"
#import "GPUImageFlowDifferenceOfGaussiansFilter0.h"
#import "GPUImageFlowDifferenceOfGaussiansFilter1.h"
#import "GPUImageRGBToLABFilter.h"

@implementation InkwellFilter {
    GPUImageRGBToLABFilter *rgb2lab;
    GPUImageStructureTensorFilter *st;
    GPUImageGaussianBlurFilter *sst;
    GPUImageEdgeTangentFlowFilter *etf;
    GPUImageFlowBilateralFilter *bfe;
    GPUImageFlowDifferenceOfGaussiansFilter0 *fdog0;
    GPUImageFlowDifferenceOfGaussiansFilter1 *fdog1;
}

- (id)initWithImageSize:(CGSize)imageSize
{
    if (self = [super init]) {
        rgb2lab = GPUImageRGBToLABFilter.new;
        [self addFilter:rgb2lab];
        
        st = GPUImageStructureTensorFilter.new;
        [self addFilter:st];
        
        sst = GPUImageGaussianBlurFilter.new;
        sst.outputTextureOptions = InkwellFilter.twoChannelFloatTexture;
        [self addFilter:sst];
        
        etf = GPUImageEdgeTangentFlowFilter.new;
        [self addFilter:etf];
        
        bfe = GPUImageFlowBilateralFilter.new;
        [self addFilter:bfe];
        
        fdog0 = GPUImageFlowDifferenceOfGaussiansFilter0.new;
        [self addFilter:fdog0];
        
        fdog1 = GPUImageFlowDifferenceOfGaussiansFilter1.new;
        [self addFilter:fdog1];
        
        self.initialFilters = @[ st, rgb2lab ];
        
        // Original image is fed into structure tensor calculation
        [st addTarget:sst];
        // Gaussian blur is applied to structure tensor to get a smoothed
        // structure tensor
        [sst addTarget:etf];
        
        // LAB colorspace image and flow map are fed into flow bilateral filter
        // pre-processing for black & white output (FDoG)
        [rgb2lab addTarget:bfe atTextureLocation:0];
        [etf addTarget:bfe atTextureLocation:1];
        
        // Blurred source image (in LAB) and flow map are fed into the first
        // step of the flow difference of Gaussians (FDoG)
        [bfe addTarget:fdog0 atTextureLocation:0];
        [etf addTarget:fdog0 atTextureLocation:1];
        
        // Output from the first step and the flow map are fed into the second
        // step of the flow difference of Gaussians (FDoG)
        [fdog0 addTarget:fdog1 atTextureLocation:0];
        [etf addTarget:fdog1 atTextureLocation:1];
        
        self.terminalFilter = fdog1;
        
        self.imageSize = imageSize;
        self.sigmaE = 1.39;
        self.sigmaR = 2.87;
        self.sigmaSST = 2.5;
        self.sigmaM = 3.0;
        self.p = 39.0;
        self.phi = 0.17;
        self.epsilon = 0.15;
        self.sigmaBFD = 3.0;
        self.sigmaBFR = 0.0425;
        self.bfeNumPasses = 1;
    }
    return self;
}

- (void)setImageSize:(CGSize)imageSize
{
    st.imageSize = imageSize;
    bfe.imageSize = imageSize;
    fdog0.imageSize = imageSize;
    fdog1.imageSize = imageSize;
}

- (void)setSigmaE:(CGFloat)sigmaE { fdog0.sigmaE = sigmaE; }
- (void)setSigmaR:(CGFloat)sigmaR { fdog0.sigmaR = sigmaR; }
- (void)setSigmaSST:(CGFloat)sigmaSST { sst.blurRadiusInPixels = sigmaSST; }
- (void)setSigmaM:(CGFloat)sigmaM { fdog1.sigmaM = sigmaM; }
- (void)setP:(CGFloat)p { fdog0.p = p; }
- (void)setPhi:(CGFloat)phi { fdog1.phi = phi; }
- (void)setEpsilon:(CGFloat)epsilon { fdog1.epsilon = epsilon; }
- (void)setSigmaBFD:(CGFloat)sigmaBFD { bfe.sigmaD = sigmaBFD; }
- (void)setSigmaBFR:(CGFloat)sigmaBFR { bfe.sigmaR = sigmaBFR; }
- (void)setBfeNumPasses:(int)numPasses { bfe.numBlurPasses = numPasses; }

+ (GPUTextureOptions)twoChannelFloatTexture
{
    GPUTextureOptions opts = {
        .minFilter = GL_NEAREST,
        .magFilter = GL_NEAREST,
        .wrapS = GL_CLAMP_TO_EDGE,
        .wrapT = GL_CLAMP_TO_EDGE,
        .internalFormat = GL_RG_EXT,
        .format = GL_RG_EXT,
        .type = GL_HALF_FLOAT_OES,
    };
    return opts;
}

@end
