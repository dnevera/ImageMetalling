//
//  IMPConstants_metal.h
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 17.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPConstants_metal_h
#define IMPConstants_metal_h

#ifdef __cplusplus

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

namespace IMProcessing
{
    
    static constant float cielab_X = 95.047;
    static constant float cielab_Y = 100.000;
    static constant float cielab_Z = 108.883;
    
    // YCbCr luminance(Y) values
    static constant float3 Y_YCbCr_factor = float3(0.299, 0.587, 0.114);
    
    // average
    static constant float3 Y_mean_factor = float3(0.3333, 0.3333, 0.3333);
    
    // sRGB luminance(Y) values
    static constant float3 Y_YUV_factor = float3(0.2125, 0.7154, 0.0721);
    
    //
    // color circle
    //
    static constant float4 reds     = float4(315.0, 345.0, 15.0,   45.0);
    static constant float4 yellows  = float4( 15.0,  45.0, 75.0,  105.0);
    static constant float4 greens   = float4( 75.0, 105.0, 135.0, 165.0);
    static constant float4 cyans    = float4(135.0, 165.0, 195.0, 225.0);
    static constant float4 blues    = float4(195.0, 225.0, 255.0, 285.0);
    static constant float4 magentas = float4(255.0, 285.0, 315.0, 345.0);
    
};

#endif

#endif /* IMPConstants_metal_h */
