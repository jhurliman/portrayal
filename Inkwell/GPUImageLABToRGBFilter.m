//
//  GPUImageLABToRGBFilter.m
//  Inkwell
//
//  Created by John Hurliman on 2/4/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#import "GPUImageLABToRGBFilter.h"

@implementation GPUImageLABToRGBFilter

NSString *const kGPUImageLABToRGBFragmentShader = SHADER_STRING(
precision highp float;

varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

highp vec3 lab2xyz(highp vec3 c)
{
    float fy = (c.x + 16.0) / 116.0;
    float fx = c.y / 500.0 + fy;
    float fz = fy - c.z / 200.0;
    
    return vec3( 95.047 * ((fx > 0.206897) ? fx * fx * fx : (fx - 16.0 / 116.0) / 7.787),
                100.000 * ((fy > 0.206897) ? fy * fy * fy : (fy - 16.0 / 116.0) / 7.787),
                108.883 * ((fz > 0.206897) ? fz * fz * fz : (fz - 16.0 / 116.0) / 7.787));
}

highp vec3 xyz2rgb(highp vec3 c)
{
    highp vec3 v =  c / 100.0 * mat3(3.2406, -1.5372, -0.4986,
                                     -0.9689, 1.8758, 0.0415,
                                     0.0557, -0.2040, 1.0570);
    highp vec3 r;
    r.x = (v.r > 0.0031308) ? ((1.055 * pow(v.r, 1.0 / 2.4)) - 0.055) : 12.92 * v.r;
    r.y = (v.g > 0.0031308) ? ((1.055 * pow(v.g, 1.0 / 2.4)) - 0.055) : 12.92 * v.g;
    r.z = (v.b > 0.0031308) ? ((1.055 * pow(v.b, 1.0 / 2.4)) - 0.055) : 12.92 * v.b;
    
    return r;
}

highp vec3 lab2rgb(highp vec3 c)
{
    return xyz2rgb(lab2xyz(vec3(1.0 * 100.0 * c.x,
                                2.0 * 127.0 * (c.y - 0.5),
                                2.0 * 127.0 * (c.z - 0.5))));
}

void main()
{
    highp vec4 c = texture2D(inputImageTexture, textureCoordinate);
    gl_FragColor = vec4(clamp(lab2rgb(clamp(c.xyz, 0.0, 1.0)), 0.0, 1.0), c.a);
}
);

- (id)init
{
    if (self = [super initWithFragmentShaderFromString:kGPUImageLABToRGBFragmentShader]) {
    }
    return self;
}

@end
