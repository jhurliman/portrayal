//
//  PencilSketchFilter.m
//  Inkwell
//
//  Created by John Hurliman on 2/4/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#import "GPUImageGaussianBlurFilter.h"
#import "PencilSketchFilter.h"
#import "GPUImageFlowBilateralFilter.h"
#import "GPUImageRGBToLABFilter.h"
#import "GPUImageStructureTensorFilter.h"
#import "GPUImageEdgeTangentFlowFilter.h"
#import "GPUImageFlowDifferenceOfGaussiansFilter0.h"
#import "GPUImageFlowDifferenceOfGaussiansFilter1MultiThreshold.h"

@implementation PencilSketchFilter {
    GPUImageRGBToLABFilter *rgb2lab;
    GPUImageStructureTensorFilter *st;
    GPUImageEdgeTangentFlowFilter *etf;
    GPUImageFlowBilateralFilter *bfe;
    GPUImageFlowDifferenceOfGaussiansFilter0 *fdog0;
    GPUImageFlowDifferenceOfGaussiansFilter1MultiThreshold *masks;
    GPUImageGaussianBlurFilter *maskSmooth;
    GPUImageTwoInputFilter *layerBlend;
    GPUImageTwoInputFilter *lineBlend;
    GPUImageTwoInputFilter *preserveAlpha;
}

- (id)initWithImageSize:(CGSize)imageSize pencilTexture:(GPUImagePicture *)pencilTexture
{
    if (self = [super init]) {
        rgb2lab = GPUImageRGBToLABFilter.new;
        [self addFilter:rgb2lab];
        
        st = GPUImageStructureTensorFilter.new;
        [self addFilter:st];
        
        etf = GPUImageEdgeTangentFlowFilter.new;
        [self addFilter:etf];
        
        bfe = GPUImageFlowBilateralFilter.new;
        [self addFilter:bfe];
        
        fdog0 = GPUImageFlowDifferenceOfGaussiansFilter0.new;
        [self addFilter:fdog0];
        
        masks = GPUImageFlowDifferenceOfGaussiansFilter1MultiThreshold.new;
        [self addFilter:masks];
        
        maskSmooth = GPUImageGaussianBlurFilter.new;
        [self addFilter:maskSmooth];
        
        layerBlend = [GPUImageTwoInputFilter.alloc initWithFragmentShaderFromString:SHADER_STRING(
            varying highp vec2 textureCoordinate;
            varying highp vec2 textureCoordinate2;
            
            uniform sampler2D inputImageTexture;
            uniform sampler2D inputImageTexture2;
            
            void main()
            {
                mediump vec2 darkUV = textureCoordinate2;
                mediump vec2 lightUV = textureCoordinate2;
                lightUV.x = 1.0 - lightUV.x;
                
                mediump vec4 masks = texture2D(inputImageTexture, textureCoordinate);
                mediump vec4 dark = texture2D(inputImageTexture2, darkUV);
                mediump vec4 light = texture2D(inputImageTexture2, lightUV);
                
                mediump float g = masks.x*1.0 + masks.y*(1.0-dark.x) + masks.z*(1.0-light.x);
                gl_FragColor = vec4(vec3(1.0 - g), masks.a);
            }
        )];
        [self addFilter:layerBlend];
        
        lineBlend = [GPUImageTwoInputFilter.alloc initWithFragmentShaderFromString:SHADER_STRING(
            varying highp vec2 textureCoordinate;
            varying highp vec2 textureCoordinate2;
            
            uniform sampler2D inputImageTexture;
            uniform sampler2D inputImageTexture2;
            
            void main()
            {
                mediump vec4 tones = texture2D(inputImageTexture, textureCoordinate);
                mediump vec4 edges = texture2D(inputImageTexture2, textureCoordinate2);
                
                gl_FragColor = vec4(vec3(tones.x * (1.0-edges.x)), tones.a);
            }
        )];
        [self addFilter:lineBlend];
        
        preserveAlpha = [GPUImageTwoInputFilter.alloc initWithFragmentShaderFromString:SHADER_STRING(
            varying highp vec2 textureCoordinate;
            varying highp vec2 textureCoordinate2;
            
            uniform sampler2D inputImageTexture;
            uniform sampler2D inputImageTexture2;
            
            void main()
            {
                lowp vec4 c1 = texture2D(inputImageTexture, textureCoordinate);
                lowp vec4 c2 = texture2D(inputImageTexture2, textureCoordinate2);
                
                gl_FragColor = vec4(c1.rgb, c2.a);
            }
        )];
        [self addFilter:preserveAlpha];
        
        
        self.initialFilters = @[ st, rgb2lab ];
        
        [st addTarget:etf];
        
        [rgb2lab addTarget:bfe atTextureLocation:0];
        [etf addTarget:bfe atTextureLocation:1];
        
        [bfe addTarget:fdog0 atTextureLocation:0];
        [etf addTarget:fdog0 atTextureLocation:1];
        
        [fdog0 addTarget:masks atTextureLocation:0];
        [etf addTarget:masks atTextureLocation:1];
        
        [masks addTarget:maskSmooth];
        
        [maskSmooth addTarget:layerBlend atTextureLocation:0];
        [pencilTexture addTarget:layerBlend atTextureLocation:1];
        
        [layerBlend addTarget:lineBlend atTextureLocation:0];
        [masks addTarget:lineBlend atTextureLocation:1];
        
        [lineBlend addTarget:preserveAlpha atTextureLocation:0];
        [rgb2lab addTarget:preserveAlpha atTextureLocation:1];
        
        self.terminalFilter = preserveAlpha;
        

        // Default tuning
        st.imageSize = imageSize;
        bfe.imageSize = imageSize;
        fdog0.imageSize = imageSize;
        fdog0.sigmaE = 0.5;
        fdog0.sigmaR = 3.5;
        fdog0.p = 35.0;
        masks.imageSize = imageSize;
        masks.sigmaM = 0.5;
        masks.phi = 0.08;
        masks.epsilonX = 0.0;
        masks.epsilonY = 30.0;
        masks.epsilonZ = 60.0;
        maskSmooth.blurRadiusInPixels = 2.0;
    }
    return self;
}

- (void)setImageSize:(CGSize)imageSize
{
    st.imageSize = imageSize;
    bfe.imageSize = imageSize;
    fdog0.imageSize = imageSize;
    masks.imageSize = imageSize;
}

- (void)setSigmaE:(CGFloat)sigmaE { fdog0.sigmaE = sigmaE; }
- (void)setSigmaR:(CGFloat)sigmaR { fdog0.sigmaR = sigmaR; }
- (void)setSigmaM:(CGFloat)sigmaM { masks.sigmaM = sigmaM; }
- (void)setP:(CGFloat)p { fdog0.p = p; }
- (void)setPhi:(CGFloat)phi { masks.phi = phi; }
- (void)setEpsilonX:(CGFloat)epsilon { masks.epsilonX = epsilon; }
- (void)setEpsilonY:(CGFloat)epsilon { masks.epsilonY = epsilon; }
- (void)setEpsilonZ:(CGFloat)epsilon { masks.epsilonZ = epsilon; }
- (void)setSigmaSST:(CGFloat)sigmaSST { maskSmooth.blurRadiusInPixels = sigmaSST; }
- (void)setSigmaBFD:(CGFloat)sigmaBFD { bfe.sigmaD = sigmaBFD; }
- (void)setSigmaBFR:(CGFloat)sigmaBFR { bfe.sigmaR = sigmaBFR; }
- (void)setBfeNumPasses:(int)numPasses { bfe.numBlurPasses = numPasses; }

@end
