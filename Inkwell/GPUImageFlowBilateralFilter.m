//
//  GPUImageFlowBilateralFilter.m
//  Inkwell
//
//  Created by John Hurliman on 2/4/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#import "GPUImageFlowBilateralFilter.h"

@implementation GPUImageFlowBilateralFilter {
    GLuint _imageSizeUniform, _sigmaDUniform, _sigmaRUniform, _passUniform;
    CGSize _imageSize;
    CGFloat _sigmaD, _sigmaR;
    int _blurPasses;
}

NSString *const kGPUImageFlowBilateralFragmentShader = SHADER_STRING(
precision highp float;

varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;  // Source Image
uniform sampler2D inputImageTexture2; // Edge Tangent Flow
uniform vec2 imageSize;
uniform float sigma_d;
uniform float sigma_r;
uniform int pass;

void main()
{
    float twoSigmaD2 = 2.0 * sigma_d * sigma_d;
    float twoSigmaR2 = 2.0 * sigma_r * sigma_r;
    highp vec2 uv = textureCoordinate;
    
    highp vec2 t = texture2D(inputImageTexture2, uv).xy;
    highp vec2 dir = (pass == 0) ? vec2(t.y, -t.x) : t;
    highp vec2 dabs = abs(dir);
    float ds = 1.0 / max(dabs.x, dabs.y);
    dir /= imageSize;
    
    highp vec3 center = texture2D(inputImageTexture, uv).rgb;
    highp vec3 sum = center;
    float norm = 1.0;
    float halfWidth = 2.0 * sigma_d;
    for (float d = ds; d <= halfWidth; d += ds) {
        vec3 c0 = texture2D(inputImageTexture, uv + d * dir).rgb;
        vec3 c1 = texture2D(inputImageTexture, uv - d * dir).rgb;
        float e0 = length(c0 - center);
        float e1 = length(c1 - center);
        
        float kerneld = exp(-d * d / twoSigmaD2);
        float kernele0 = exp(-e0 * e0 / twoSigmaR2);
        float kernele1 = exp(-e1 * e1 / twoSigmaR2);
        norm += kerneld * kernele0;
        norm += kerneld * kernele1;
        
        sum += kerneld * kernele0 * c0;
        sum += kerneld * kernele1 * c1;
    }
    sum /= norm;
    
    gl_FragColor = vec4(sum, 1.0);
}
);

- (id)init
{
    if (self = [super initWithFragmentShaderFromString:kGPUImageFlowBilateralFragmentShader]) {
        _imageSizeUniform = [filterProgram uniformIndex:@"imageSize"];
        _sigmaDUniform = [filterProgram uniformIndex:@"sigma_d"];
        _sigmaRUniform = [filterProgram uniformIndex:@"sigma_r"];
        _passUniform = [filterProgram uniformIndex:@"pass"];
        
        self.imageSize = CGSizeMake(640.0, 800.0);
        self.sigmaD = 3.00;
        self.sigmaR = 0.0425;
        self.numBlurPasses = 1;
    }
    
    return self;
}

- (void)setImageSize:(CGSize)imageSize
{
    _imageSize = imageSize;
    [self setSize:imageSize forUniform:_imageSizeUniform program:filterProgram];
}

- (void)setSigmaD:(CGFloat)sigmaD
{
    _sigmaD = sigmaD;
    [self setFloat:sigmaD forUniform:_sigmaDUniform program:filterProgram];
}

- (void)setSigmaR:(CGFloat)sigmaR
{
    _sigmaR = sigmaR;
    [self setFloat:sigmaR forUniform:_sigmaRUniform program:filterProgram];
}

- (void)setNumBlurPasses:(int)passes
{
    _blurPasses = passes;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        [secondInputFramebuffer unlock];
        return;
    }
    
    outputFramebuffer = [GPUImageContext.sharedFramebufferCache fetchFramebufferForSize:self.sizeOfFBO
                                                                         textureOptions:self.outputTextureOptions
                                                                            onlyTexture:NO];
    GPUImageFramebuffer *tmpFramebuffer = [GPUImageContext.sharedFramebufferCache fetchFramebufferForSize:self.sizeOfFBO
                                                                                           textureOptions:self.outputTextureOptions
                                                                                              onlyTexture:NO];
    
    [GPUImageContext setActiveShaderProgram:filterProgram];
    [self setUniformsForProgramAtIndex:0];
    
    for (int blurPass = 0; blurPass < _blurPasses; blurPass++) {
        GLuint src = (blurPass == 0) ? firstInputFramebuffer.texture : outputFramebuffer.texture;
        
        // First pass
        [tmpFramebuffer activateFramebuffer];
        [self setInteger:0 forUniform:_passUniform program:filterProgram];
        [self renderPassToTextureWithVertices:vertices
                           textureCoordinates:[self.class textureCoordinatesForRotation:kGPUImageNoRotation]
                                 firstTexture:src];
        
        // Second pass
        [outputFramebuffer activateFramebuffer];
        [self setInteger:1 forUniform:_passUniform program:filterProgram];
        [self renderPassToTextureWithVertices:vertices
                           textureCoordinates:[self.class textureCoordinatesForRotation:kGPUImageNoRotation]
                                 firstTexture:src];
    }
    
    [tmpFramebuffer unlock];
    tmpFramebuffer = nil;
    
    [firstInputFramebuffer unlock];
    [secondInputFramebuffer unlock];
    if (usingNextFrameForImageCapture) {
        [outputFramebuffer lock];
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
}

- (void)renderPassToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates firstTexture:(GLuint)firstTexture
{
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, firstTexture);
    glUniform1i(filterInputTextureUniform, 2);
    
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, [secondInputFramebuffer texture]);
    glUniform1i(filterInputTextureUniform2, 3);
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glVertexAttribPointer(filterSecondTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [[self class] textureCoordinatesForRotation:inputRotation2]);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

@end
