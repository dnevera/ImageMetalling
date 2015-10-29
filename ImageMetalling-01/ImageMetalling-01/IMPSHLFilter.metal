//
//  IMPFilter.metal
//  ImageMetalling-00
//
//  Created by denis svinarchuk on 27.10.15.
//  Copyright © 2015 ImageMetalling. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

inline float4 blendScreen(float4 base, float4 blend){
    //
    // from: https://en.wikipedia.org/wiki/Blend_modes#Screen
    //
    return (1.0 - ((1.0 - base) * (1.0 - blend)));
}

inline float4 blendNormal(float4 c2, float4 c1)
{
    //
    // from: https://github.com/BradLarson/GPUImage
    //
    
    float4 outputColor;
    
    float a = c1.a + c2.a * (1.0 - c1.a);
    float alphaDivisor = a + step(a, 0.0);
    
    outputColor.r = (c1.r * c1.a + c2.r * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.g = (c1.g * c1.a + c2.g * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.b = (c1.b * c1.a + c2.b * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.a = a;
    
    return clamp(outputColor, float4(0.0), float4(1.0));
}

typedef struct{
    packed_float4 shadows;       // [level, weight, tonal width, slop]
} IMPShadows;

inline float shadows_weight_internal(float x, float weight, float width, float slop){
    float w = width * 0.5;
    return weight/ exp( 3 * x * slop / w) * (w);
}

inline float shadows_weight(float x, float weight, float width, float slop){
    float maxe = shadows_weight_internal(0, weight, width, slop);
    return weight * shadows_weight_internal(x, weight, width, slop)/maxe;
}

inline float4 adjustShadows(float4 source, constant IMPShadows &adjustment)
{
    float3 rgb       = source.rgb;
    
    float4 shadows(adjustment.shadows);
    
    float luminance = dot(rgb, float3(0.299, 0.587, 0.114));

    float weight = shadows_weight(luminance,
                                  shadows.y,
                                  shadows.z,
                                  shadows.w);
    
    float4 screen = blendScreen(source, source);
    float3 result = blendScreen(source, screen).rgb;
    
    return blendNormal (source, float4(float3(result),  shadows.x * weight));
}


kernel void kernel_adjustSHL(
                             texture2d<float, access::sample> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             constant IMPShadows &adjustment             [[buffer(0)]],
                             uint2 gid [[thread_position_in_grid]]
                                    )
{
    float4 inColor = inTexture.read(gid);
    outTexture.write(adjustShadows(inColor, adjustment), gid);
}
