//
//  IMPColorSpaces_metal.h
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 19.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPColorSpaces_metal_h
#define IMPColorSpaces_metal_h

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;
#ifdef __cplusplus

namespace IMProcessing
{
    
    
    inline  float rgb_2_L(float3 color)
    {
        float fmin = min_component(color); //Min. value of RGB
        float fmax = max_component(color); //Max. value of RGB
        
        return (fmax + fmin) * 0.5; // Luminance
    }
    
    inline float3 rgb_2_HSV(float3 c)
    {
        constexpr float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
        float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
        
        float d = q.x - min(q.w, q.y);
        constexpr float e = 1.0e-10;
        return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
    }
    
    inline float3 HSV_2_rgb(float3 c)
    {
        constexpr float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
        return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }
    
    inline float3 rgb_2_HSL(float3 color)
    {
        float3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)
        
        float fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
        float fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
        float delta = fmax - fmin;             //Delta RGB value
        
        hsl.z = clamp((fmax + fmin) * 0.5, 0.0, 1.0); // Luminance
        
        if (delta == 0.0)   //This is a gray, no chroma...
        {
            hsl.x = 0.0;	// Hue
            hsl.y = 0.0;	// Saturation
        }
        else                //Chromatic data...
        {
            if (hsl.z < 0.5)
                hsl.y = delta / (fmax + fmin); // Saturation
            else
                hsl.y = delta / (2.0 - fmax - fmin); // Saturation
            
            float deltaR = (((fmax - color.r) / 6.0) + (delta * 0.5)) / delta;
            float deltaG = (((fmax - color.g) / 6.0) + (delta * 0.5)) / delta;
            float deltaB = (((fmax - color.b) / 6.0) + (delta * 0.5)) / delta;
            
            if (color.r == fmax )     hsl.x = deltaB - deltaG; // Hue
            else if (color.g == fmax) hsl.x = 1.0/3.0 + deltaR - deltaB; // Hue
            else if (color.b == fmax) hsl.x = 2.0/3.0 + deltaG - deltaR; // Hue
            
            if (hsl.x < 0.0)       hsl.x += 1.0; // Hue
            else if (hsl.x > 1.0)  hsl.x -= 1.0; // Hue
        }
        
        return hsl;
    }
    
    inline float hue_2_rgb(float f1, float f2, float hue)
    {
        if (hue < 0.0)      hue += 1.0;
        else if (hue > 1.0) hue -= 1.0;
        
        float res;
        
        if ((6.0 * hue) < 1.0)      res = f1 + (f2 - f1) * 6.0 * hue;
        else if ((2.0 * hue) < 1.0) res = f2;
        else if ((3.0 * hue) < 2.0) res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
        else                        res = f1;
        
        res = clamp(res, 0.0, 1.0);
        
        return res;
    }
    
    inline float3 HSL_2_rgb(float3 hsl)
    {
        float3 rgb;
        
        if (hsl.y == 0.0) rgb = clamp(float3(hsl.z), float3(0.0), float3(1.0)); // Luminance
        else
        {
            float f2;
            
            if (hsl.z < 0.5) f2 = hsl.z * (1.0 + hsl.y);
            else             f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);
            
            float f1 = 2.0 * hsl.z - f2;
            
            constexpr float tk = 1.0/3.0;
            
            rgb.r = hue_2_rgb(f1, f2, hsl.x + tk);
            rgb.g = hue_2_rgb(f1, f2, hsl.x);
            rgb.b = hue_2_rgb(f1, f2, hsl.x - tk);
        }
        
        return rgb;
    }
    
    
    //
    // http://www.easyrgb.com/index.php?X=MATH&H=02#text2
    //
    inline float3 rgb_2_XYZ(float3 rgb)
    {
        float r = rgb.r;
        float g = rgb.g;
        float b = rgb.b;
        
        
        if ( r > 0.04045 ) r = pow((( r + 0.055) / 1.055 ), 2.4);
        else               r = r / 12.92;
        
        if ( g > 0.04045 ) g = pow((( g + 0.055) / 1.055 ), 2.4);
        else               g = g / 12.92;;
        
        if ( b > 0.04045 ) b = pow((( b + 0.055) / 1.055 ), 2.4);
        else               b = b / 12.92;
        
        float3 xyz;
        
        xyz.x = r * 41.24 + g * 35.76 + b * 18.05;
        xyz.y = r * 21.26 + g * 71.52 + b * 7.22;
        xyz.z = r * 1.93  + g * 11.92 + b * 95.05;
        
        return xyz;
    }
    
    inline float3 Lab_2_XYZ(float3 lab){
        
        float3 xyz;
        
        xyz.y = ( lab.x + 16.0 ) / 116.0;
        xyz.x = lab.y / 500.0 + xyz.y;
        xyz.z = xyz.y - lab.z / 200.0;
        
        if ( pow(xyz.y,3.0) > 0.008856 ) xyz.y = pow(xyz.y,3.0);
        else                             xyz.y = ( xyz.y - 16.0 / 116.0 ) / 7.787;
        
        if ( pow(xyz.x,3.0) > 0.008856 ) xyz.x = pow(xyz.x,3.0);
        else                             xyz.x = ( xyz.x - 16.0 / 116.0 ) / 7.787;
        
        if ( pow(xyz.z,3.0) > 0.008856 ) xyz.z = pow(xyz.z,3.0);
        else                             xyz.z = ( xyz.z - 16.0 / 116.0 ) / 7.787;
        
        xyz.x *= cielab_X;    //     Observer= 2°, Illuminant= D65
        xyz.y *= cielab_Y;
        xyz.z *= cielab_Z;
        
        return xyz;
    }
    
    inline float3 XYZ_2_rgb (float3 xyz){
        
        float var_X = xyz.x / 100.0;       //X from 0 to  95.047      (Observer = 2°, Illuminant = D65)
        float var_Y = xyz.y / 100.0;       //Y from 0 to 100.000
        float var_Z = xyz.z / 100.0;       //Z from 0 to 108.883
        
        float3 rgb;
        
        rgb.r = var_X *  3.2406 + var_Y * -1.5372 + var_Z * -0.4986;
        rgb.g = var_X * -0.9689 + var_Y *  1.8758 + var_Z *  0.0415;
        rgb.b = var_X *  0.0557 + var_Y * -0.2040 + var_Z *  1.0570;
        
        if ( rgb.r > 0.0031308 ) rgb.r = 1.055 * pow( rgb.r, ( 1.0 / 2.4 ) ) - 0.055;
        else                     rgb.r = 12.92 * rgb.r;
        
        if ( rgb.g > 0.0031308 ) rgb.g = 1.055 * pow( rgb.g, ( 1.0 / 2.4 ) ) - 0.055;
        else                     rgb.g = 12.92 * rgb.g;
        
        if ( rgb.b > 0.0031308 ) rgb.b = 1.055 * pow( rgb.b, ( 1.0 / 2.4 ) ) - 0.055;
        else                     rgb.b = 12.92 * rgb.b;
        
        return rgb;
    }
    
    inline float3 XYZ_2_Lab(float3 xyz)
    {
        float var_X = xyz.x / cielab_X;   //   Observer= 2°, Illuminant= D65
        float var_Y = xyz.y / cielab_Y;
        float var_Z = xyz.z / cielab_Z;
        
        float t1 = 1.0/3.0;
        float t2 = 16.0/116.0;
        
        if ( var_X > 0.008856 ) var_X = pow (var_X, t1);
        else                    var_X = ( 7.787 * var_X ) + t2;
        
        if ( var_Y > 0.008856 ) var_Y = pow(var_Y, t1);
        else                    var_Y = ( 7.787 * var_Y ) + t2;
        
        if ( var_Z > 0.008856 ) var_Z = pow(var_Z, t1);
        else                    var_Z = ( 7.787 * var_Z ) + t2;
        
        return float3(( 116.0 * var_Y ) - 16.0, 500.0 * ( var_X - var_Y ), 200.0 * ( var_Y - var_Z ));
    }
    
    inline float3 Lab_2_rgb(float3 lab) {
        float3 xyz = Lab_2_XYZ(lab);
        return XYZ_2_rgb(xyz);
    }
    
    inline float3 rgb_2_Lab(float3 rgb) {
        float3 xyz = rgb_2_XYZ(rgb);
        return XYZ_2_Lab(xyz);
    }
    
    inline float3 rgb_2_YCbCr(float3 rgb){
        float3x3 tv = float3x3(
                               float3( 0.299,  0.587,  0.114),
                               float3(-0.169, -0.331,  0.5),
                               float3( 0.5,   -0.419, -0.081)
                               );
        constexpr float3 offset (0,128,128);
        
        return (tv * rgb*255 + offset)/255;
    }
    
    inline float3 YCbCr_2_rgb(float3 YCbCr){
        float3x3 ti = float3x3(
                               float3(1.0,  0.0,    1.4),
                               float3(1.0, -0.343, -0.711),
                               float3(1.0,  1.765,  0.0)
                               );
        constexpr float3 offset (0,128,128);
        
        return (ti * float3(YCbCr*255 - offset))/255;
    }
}
#endif

#endif /* IMPColorSpaces_metal_h */
