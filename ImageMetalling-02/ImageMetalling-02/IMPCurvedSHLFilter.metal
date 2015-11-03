//
//  IMPFilter.metal
//  ImageMetalling-02
//
//  Created by denis svinarchuk on 27.10.15.
//  Copyright © 2015 ImageMetalling. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "IMPCommonMetal.h"
using namespace metal;

//
// Маска теней для вектора RGB/канала яркости в произвольном числовом формате формате
//
template<typename T> inline T LsMask(T Li, float W, float Wt, float Ks){
    T c(1 - pow((1 - Li),4));
    return c * W / exp( 6 * Ks * Li / Wt) * Wt;
}

//
// Маска светов для вектора RGB/канала яркости в произвольном формате
//
template<typename T> inline T LhMask(T Li, float W, float Wt, float Ka){
    return 1 - LsMask(1-Li,W,Wt,Ka);
}

//
// Результирующая кривая коррекции канала яркости
//
template<typename T> inline T shlCurve(T Li, constant IMPShadowsHighLights &adjustment){
    
    T lh = LhMask(Li,
                  adjustment.highlights.x,
                  adjustment.highlights.y,
                  adjustment.highlights.z
                  );
    
    T ls = LsMask(Li,
                  adjustment.shadows.x,
                  adjustment.shadows.y,
                  adjustment.shadows.z
                  );
    
    return T ((Li + ls) * lh);
}

//
// Результирующая кривая коррекции свето-тени в RGB пространстве
//
inline float4 adjustRgbShadowsHighlights(float4 source, constant IMPShadowsHighLights &adjustment)
{
    float3 curve ( shlCurve(source.rgb, adjustment) );
    //
    // Результат ссмешивае с учетом композиции в альфа канале.
    //
    return blendNormal (source, float4 (curve , adjustment.level));
}

//
// Результирующая кривая коррекции свето-тени в L канале и смешивании в светах
//
inline float4 adjustLumaShadowsHighlights(float4 source, constant IMPShadowsHighLights &adjustment)
{
    float luminance = dot(source.rgb, luma_factor);
    
    float3 curve = shlCurve(luminance, adjustment);
    //
    // Результат ссмешивае с учетом композиции в альфа канале.
    //
    return blendLuminosity (source, float4 (curve , adjustment.level));
}


//
// Результирующая кривая коррекции свето-тени в HSV пространстве
//
inline float4 adjustHSVShadowsHighlights(float4 source, constant IMPShadowsHighLights &adjustment)
{
    float3 hsv = rgb_2_HSV (source.rgb);
    
    hsv.z = shlCurve(hsv.z, adjustment);
    
    //
    // Результат смешивание с учетом композиции в альфа канале.
    //
    return blendNormal (source, float4 (HSV_2_rgb(hsv) , adjustment.level));
}

//
// Дальше просто конкретные kernel-функции
//
kernel void kernel_adjustRgbCurvedSHL(
                                      texture2d<float, access::sample> inTexture [[texture(0)]],
                                      texture2d<float, access::write> outTexture [[texture(1)]],
                                      constant IMPShadowsHighLights &adjustment  [[buffer(0)]],
                                      uint2 gid [[thread_position_in_grid]]
                                      )
{
    float4 inColor = inTexture.read(gid);
    outTexture.write(adjustRgbShadowsHighlights(inColor, adjustment), gid);
}


kernel void kernel_adjustLumaCurvedSHL(
                                       texture2d<float, access::sample> inTexture [[texture(0)]],
                                       texture2d<float, access::write> outTexture [[texture(1)]],
                                       constant IMPShadowsHighLights &adjustment  [[buffer(0)]],
                                       uint2 gid [[thread_position_in_grid]]
                                       )
{
    float4 inColor = inTexture.read(gid);
    outTexture.write(adjustLumaShadowsHighlights(inColor, adjustment), gid);
}

kernel void kernel_adjustHSVCurvedSHL(
                                      texture2d<float, access::sample> inTexture [[texture(0)]],
                                      texture2d<float, access::write> outTexture [[texture(1)]],
                                      constant IMPShadowsHighLights &adjustment  [[buffer(0)]],
                                      uint2 gid [[thread_position_in_grid]]
                                      )
{
    float4 inColor = inTexture.read(gid);
    outTexture.write(adjustHSVShadowsHighlights(inColor, adjustment), gid);
}
