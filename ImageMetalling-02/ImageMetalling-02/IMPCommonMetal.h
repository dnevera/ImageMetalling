//
//  IMPCommonMetal.h
//  ImageMetalling-02
//
//  Created by denis svinarchuk on 02.11.15.
//  Copyright © 2015 ImageMetalling. All rights reserved.
//

#ifndef __IMPMETAL_COMMON
#define __IMPMETAL_COMMON

#include <metal_stdlib>
#include "IMPShaderTypes.h"
using namespace metal;

//
// Объявление констант в MSL
//
static constant float3 luma_factor = float3(0.299, 0.587, 0.114);

//
// Шаблоны функций
//
template<typename T> inline T max_component(vec<T, 2> v) {
    return max(v[0], v[1]);
}

template<typename T> inline T max_component(vec<T, 3> v) {
    return max(v[0], max(v[1], v[2]));
}

template<typename T> inline T max_component(vec<T, 4> v) {
    vec<T, 2> v2 = max(vec<T, 2>(v[0], v[1]), vec<T, 2>(v[2], v[3]));
    return max(v2[0], v2[1]);
}

template<typename T> inline T min_component(vec<T, 2> v) {
    return min(v[0], v[1]);
}

template<typename T> inline T min_component(vec<T, 3> v) {
    return min(v[0], min(v[1], v[2]));
}

template<typename T> inline T min_component(vec<T, 4> v) {
    vec<T, 2> v2 = min(vec<T, 2>(v[0], v[1]), vec<T, 2>(v[2], v[3]));
    return min(v2[0], v2[1]);
}

template<typename T> inline T lum(vec<T, 3> c) {
    return dot(c, luma_factor);
}

template<typename T> inline T lum(vec<T, 4> c) {
    return dot(c, luma_factor);
}

template<typename T> inline vec<T, 3> clipcolor_wlum(vec<T, 3> c, T wlum) {
    
    T l = wlum;
    T n = min_component(c);
    T x = max_component(c);
    
    if (n < 0.0) {
        T v = 1.0/(l - n);
        c.r = l + ((c.r - l) * l) * v;
        c.g = l + ((c.g - l) * l) * v;
        c.b = l + ((c.b - l) * l) * v;
    }
    if (x > 1.0) {
        T v = 1.0/(x - l);
        c.r = l + ((c.r - l) * (1.0 - l)) * v;
        c.g = l + ((c.g - l) * (1.0 - l)) * v;
        c.b = l + ((c.b - l) * (1.0 - l)) * v;
    }
    
    return c;
}

template<typename T> inline vec<T, 3> clipcolor(vec<T, 3> c) {
    return clipcolor_wlum(c,lum(c));
}

template<typename T> inline vec<T, 3> setlum(vec<T, 3> c, T l) {
    T ll = lum(c);
    T d = l - ll;
    c = c + vec<T, 3>(d);
    return clipcolor_wlum(c,ll);
}

//
// Режим композиционного смешивания цветов каналов в светах
//
// from: https://github.com/BradLarson/GPUImage
//
inline  float4 blendLuminosity(float4 baseColor, float4 overlayColor)
{
    return float4(baseColor.rgb * (1.0 - overlayColor.a) + setlum(baseColor.rgb, lum(overlayColor.rgb)) * overlayColor.a, baseColor.a);
}

//
// Нормальных режим композиционного смешивания цветов каналов
//
inline float4 blendNormal(float4 c2, float4 c1)
{
    float4 outputColor;
    
    float a = c1.a + c2.a * (1.0 - c1.a);
    float alphaDivisor = a + step(a, 0.0);
    
    outputColor.r = (c1.r * c1.a + c2.r * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.g = (c1.g * c1.a + c2.g * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.b = (c1.b * c1.a + c2.b * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.a = a;
    
    return clamp(outputColor, float4(0.0), float4(1.0));
}

//
// Сконвертировать цветовой пространство RGB в HSV
//
inline float3 rgb_2_HSV(float3 c)
{
    constexpr float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    
    float d = q.x - min(q.w, q.y);
    constexpr float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

//
// Сконвертировать цветовое пространстов HSV в RGB
//
inline float3 HSV_2_rgb(float3 c)
{
    constexpr float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}



#endif