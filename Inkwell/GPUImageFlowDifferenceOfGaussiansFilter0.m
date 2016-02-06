//
//  GPUImageFlowDifferenceOfGaussiansFilter0.m
//  Inkwell
//
//  Created by John Hurliman on 2/4/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#import "GPUImageFlowDifferenceOfGaussiansFilter0.h"
#import "InkwellFilter.h"

@implementation GPUImageFlowDifferenceOfGaussiansFilter0 {
    GLuint _imageSizeUniform, _sigmaEUniform, _sigmaRUniform, _pUniform;
    CGSize _imageSize;
    CGFloat _sigmaE, _sigmaR, _p;
}

NSString *const kGPUImageFlowDifferenceOfGaussians0FragmentShader = SHADER_STRING(
precision highp float;

varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;  // Source Image
uniform sampler2D inputImageTexture2; // Edge Tangent Flow
uniform vec2 imageSize;
uniform float sigma_e;
uniform float sigma_r;
uniform float p;

void main()
{
    vec2 uv = textureCoordinate;
    
    vec2 t = texture2D(inputImageTexture2, uv).xy;
    vec2 n = vec2(t.y, -t.x);
    vec2 nabs = abs(n);
    
    float ds = 1.0 / max(nabs.x, nabs.y);
    n /= imageSize;
    
    vec2 sum = texture2D(inputImageTexture, uv).xx;
    vec2 norm = vec2(1.0);
    
    float twoSigmaE2 = 2.0 * sigma_e * sigma_e;
    float twoSigmaR2 = 2.0 * sigma_r * sigma_r;
    float halfWidth =  2.0 * sigma_r;
    
    for (float d = ds; d <= halfWidth; d += ds) {
        vec2 kernel = vec2(exp(-d * d / twoSigmaE2),
                           exp(-d * d / twoSigmaR2));
        norm += 2.0 * kernel;
        
        vec2 L0 = texture2D(inputImageTexture, uv - d*n).xx;
        vec2 L1 = texture2D(inputImageTexture, uv + d*n).xx;
        
        sum += kernel * (L0 + L1);
    }
    sum /= norm;
    
    float H = (1.0 + p) * sum.x - p * sum.y;
    gl_FragColor = vec4(vec3(H), 1.0);
}
);

- (id)init
{
    if (self = [super initWithFragmentShaderFromString:kGPUImageFlowDifferenceOfGaussians0FragmentShader]) {
        self.outputTextureOptions = InkwellFilter.twoChannelFloatTexture;
        
        _imageSizeUniform = [filterProgram uniformIndex:@"imageSize"];
        _sigmaEUniform = [filterProgram uniformIndex:@"sigma_e"];
        _sigmaRUniform = [filterProgram uniformIndex:@"sigma_r"];
        _pUniform = [filterProgram uniformIndex:@"p"];
        self.imageSize = CGSizeMake(640.0, 800.0);
        self.sigmaE = 1.0;
        self.sigmaR = 1.6;
        self.p = 20.0;
    }
    
    return self;
}

- (void)setImageSize:(CGSize)imageSize
{
    _imageSize = imageSize;
    [self setSize:imageSize forUniform:_imageSizeUniform program:filterProgram];
}

- (void)setSigmaE:(CGFloat)sigmaE
{
    _sigmaE = sigmaE;
    [self setFloat:sigmaE forUniform:_sigmaEUniform program:filterProgram];
}

- (void)setSigmaR:(CGFloat)sigmaR
{
    _sigmaR = sigmaR;
    [self setFloat:sigmaR forUniform:_sigmaRUniform program:filterProgram];
}

- (void)setP:(CGFloat)p
{
    _p = p;
    [self setFloat:p forUniform:_pUniform program:filterProgram];
}

@end
