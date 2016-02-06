//
//  GPUImageStructureTensorFilter.m
//  Inkwell
//
//  Created by John Hurliman on 2/4/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#import "GPUImageStructureTensorFilter.h"
#import "InkwellFilter.h"

@implementation GPUImageStructureTensorFilter {
    GLuint _imageSizeUniform;
    CGSize _imageSize;
}

NSString *const kGPUImageStructureTensorFragmentShader = SHADER_STRING(
precision highp float;

varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform mediump vec2 imageSize;

float luma(vec4 c)
{
    return 0.2126*c.r + 0.7152*c.g + 0.0722*c.b;
}

void main()
{
    highp vec2 uv = textureCoordinate;
    highp vec2 d = 1.0 / imageSize;
    
    highp vec4 u = (
              -1.0 * texture2D(inputImageTexture, uv + vec2(-d.x, -d.y)) +
              -2.0 * texture2D(inputImageTexture, uv + vec2(-d.x,  0.0)) +
              -1.0 * texture2D(inputImageTexture, uv + vec2(-d.x,  d.y)) +
              +1.0 * texture2D(inputImageTexture, uv + vec2( d.x, -d.y)) +
              +2.0 * texture2D(inputImageTexture, uv + vec2( d.x,  0.0)) +
              +1.0 * texture2D(inputImageTexture, uv + vec2( d.x,  d.y))
              ) / 4.0;
    
    highp vec4 v = (
              -1.0 * texture2D(inputImageTexture, uv + vec2(-d.x, -d.y)) +
              -2.0 * texture2D(inputImageTexture, uv + vec2( 0.0, -d.y)) +
              -1.0 * texture2D(inputImageTexture, uv + vec2( d.x, -d.y)) +
              +1.0 * texture2D(inputImageTexture, uv + vec2(-d.x,  d.y)) +
              +2.0 * texture2D(inputImageTexture, uv + vec2( 0.0,  d.y)) +
              +1.0 * texture2D(inputImageTexture, uv + vec2( d.x,  d.y))
              ) / 4.0;
    
    gl_FragColor = vec4(luma(u), luma(v), 0.0, 1.0);
}
);

- (id)init
{
    if (self = [super initWithFragmentShaderFromString:kGPUImageStructureTensorFragmentShader]) {
        self.outputTextureOptions = InkwellFilter.twoChannelFloatTexture;
        
        _imageSizeUniform = [filterProgram uniformIndex:@"imageSize"];
        self.imageSize = CGSizeMake(640.0, 800.0);
    }
    
    return self;
}

- (void)setImageSize:(CGSize)imageSize
{
    _imageSize = imageSize;
    [self setSize:imageSize forUniform:_imageSizeUniform program:filterProgram];
}

@end
