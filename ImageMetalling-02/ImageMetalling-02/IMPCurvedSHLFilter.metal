//
//  IMPFilter.metal
//  ImageMetalling-00
//
//  Created by denis svinarchuk on 27.10.15.
//  Copyright © 2015 ImageMetalling. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "IMPCommonMetal.h"
using namespace metal;

//
// Маска теней
//
inline float LsMask(float Li, float W, float Wt, float Ks){
    float c(1.0 - pow((1.0 - Li),4));
    return c * W / exp( 6 * Ks * Li / Wt) * Wt;
}

//
// Маска светов
//
inline float LhMask(float Li, float W, float Wt, float Ka){
    return 1 - LsMask(1-Li,W,Wt,Ka);
}

//
// Результирующая кривая коррекции свето-тени
//
inline float4 adjustShadowsHighlights(float4 source, constant IMPShadowsHighLights &adjustment)
{
    float3 rgb = source.rgb;
    
    float luminance = dot(rgb, luma_factor);
    
    //
    // Распаковываем выходной буфер, прилетевший из памяти приложения в память GPU
    //
    float3 highlights(adjustment.highlights);
    float3 shadows(adjustment.shadows);

    float lh = LhMask(luminance,
                  highlights.x,
                  highlights.y,
                  highlights.z
                  );

    float ls = LsMask(luminance,
                  shadows.x,
                  shadows.y,
                  shadows.z
                  );
    

    //
    // Результирующая кривая коррекции
    //
    float L = (luminance + ls) * lh;
    
    //
    // Результат смешиваем в режиме светов с учетом композиции в альфа канале.
    //
    return blendLuminosity (source, float4 (float3(L) , adjustment.level));
}


kernel void kernel_adjustCurvedSHL(
                             texture2d<float, access::sample> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             constant IMPShadowsHighLights &adjustment  [[buffer(0)]],
                             uint2 gid [[thread_position_in_grid]]
                             )
{
    float4 inColor = inTexture.read(gid);
    outTexture.write(adjustShadowsHighlights(inColor, adjustment), gid);
}
