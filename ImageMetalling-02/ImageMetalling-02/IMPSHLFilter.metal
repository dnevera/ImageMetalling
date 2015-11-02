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
// Расчет веса теней в якростном канале сигнала
//
inline float Ls(float Li, float W, float Wt, float Ks){
    return  W / exp( 6 * Ks * Li / Wt) * Wt;
}

//
// Расчет веса светов в якростном канале сигнала
//
inline float Lh(float Li, float W, float Wt, float Ka){
    return Ls(1-Li,W,Wt,Ka);
}

//
// Результирующая функция коррекции теней
//
inline float4 adjustShadows(float4 source, constant IMPShadowsHighLights &adjustment)
{
    float3 rgb = source.rgb;
    
    //
    // выучите эту строчку наизусть, используется почти везде
    // можно запомнить как 3/6/1
    //
    // почитать можно тут: https://en.wikipedia.org/wiki/Relative_luminance
    // исходная формула относительной яркости в колорометрии:
    // Y = 0.2126 R + 0.7152 G + 0.0722 B
    // но мы работаем не с колорметрически измеренным значением RGB, а с представлением
    // rgb в виде sRGB цветового пространства. Так случилось, что быстрое преобразование:
    // L(rgb)= (r,g,b)(0.299, 0.587, 0.114)', для наших целей подходит лучше
    // и подтверждается рядом экспериментов с большим набором изображений.
    //
    float luminance = dot(rgb, luma_factor);
    
    float3 shadows(adjustment.shadows);
    
    float ls = Ls(luminance,
                  shadows.x,
                  shadows.y,
                  shadows.z);
    
    //
    // Альфа канал - функция уровня воздействия фильтра и вес от яркости
    //
    float  a(adjustment.level * ls);
    
    //
    // Функция смешивания в режиме screen 2 раза или
    // гаммакорекция негатива с гаммой == 4
    //
    float3 c(1.0 - pow((1.0 - rgb),4));
    
    return blendNormal (source, float4 (c , a));
}

//
// Результирующая функция коррекции светов
//
inline float4 adjustHighlights(float4 source, constant IMPShadowsHighLights &adjustment)
{
    float3 rgb = source.rgb;
    
    float luminance = dot(rgb, luma_factor);
    
    float3 highlights(adjustment.highlights);
    
    float lh = Lh(luminance,
                  highlights.x,
                  highlights.y,
                  highlights.z);
    
    //
    // Альфа канал - функция уровня воздействия фильтра и вес от яркости
    //
    float  a(adjustment.level * lh);
    
    //
    // Функция смешивания в режиме multiply 2 раза
    //
    float3 c(pow(rgb,4));
    
    return blendNormal (source, float4 (c , a));
}


kernel void kernel_adjustSHL(
                              texture2d<float, access::sample> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              constant IMPShadowsHighLights &adjustment  [[buffer(0)]],
                              uint2 gid [[thread_position_in_grid]]
                              )
{
    float4 inColor = inTexture.read(gid);
    inColor = adjustShadows(inColor, adjustment);
    outTexture.write(adjustHighlights(inColor, adjustment), gid);
}
