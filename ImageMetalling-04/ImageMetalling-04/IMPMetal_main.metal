//
//  IMPMetal_main.metal
//  ImageMetalling-04
//
//  Created by denis svinarchuk on 12.11.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#include <metal_stdlib>
#include "DPMetal_main.h"
using namespace metal;


inline float3 original_rgb_2_HSV(float3 rgb)
{
        
    float M = max_component(rgb);
    float m = min_component(rgb);
    float C = M - m;

    float Hi;
    float S;
    float V = M;
    
    if (C==0){
        Hi = 0;
        S  = 0;
    }
    else{
        
        S = C/V;
        
        if (M==rgb.r){
            Hi = fmod((rgb.g-rgb.b)/C,6);
        }
        else if (M==rgb.g){
            Hi = (rgb.b-rgb.r)/C+2;
        }
        else if (M==rgb.b){
            Hi = (rgb.r-rgb.g)/C+4;
        }
    }
    
    float H = Hi / 6;
    
    return float3(H,S,V);
}

inline float3 original_HSV_2_rgb(float3 hsv){
    
    float3 rgb;
    
    if ( hsv.y == 0 )
    {
        rgb.r = hsv.z;
        rgb.g = hsv.z;
        rgb.b = hsv.z;
    }
    else
    {
        float C  = hsv.z * hsv.y;
        float Hi = hsv.x * 6;
        float X  = C*(1-abs(fmod(Hi,2)-1));
        
        if      ( Hi >= 0 && Hi<1 ) { rgb = float3(C,X,0); }
        else if ( Hi >= 1 && Hi<2 ) { rgb = float3(X,C,0); }
        else if ( Hi >= 2 && Hi<3 ) { rgb = float3(0,C,X); }
        else if ( Hi >= 3 && Hi<4 ) { rgb = float3(0,X,C); }
        else if ( Hi >= 4 && Hi<5 ) { rgb = float3(X,0,C); }
        else                        { rgb = float3(C,0,X); }

        float m = hsv.z-C;
        
        rgb = rgb + m;
        
    }
    
    return rgb;
}


kernel void kernel_original_adjustHSV(
                                  texture2d<float, access::read> inTexture [[texture(0)]],
                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                  uint2 gid [[thread_position_in_grid]])
{
    float4 inColor   = inTexture.read(gid);
    
    for(int i=0; i<50; i++){
        float3 hsv = original_rgb_2_HSV(inColor.rgb);  hsv.x = 0.5;
        inColor.rgb = original_HSV_2_rgb(hsv);
        
        //
        // тут может быть какой-то другой код
        //
        
        hsv = original_rgb_2_HSV(inColor.rgb); hsv.y =clamp(hsv.y+0.5,0.0,1.0);
        inColor.rgb = original_HSV_2_rgb(hsv);
        
        //
        // тут может быть еще какой-то код
        //
        
        hsv = original_rgb_2_HSV(inColor.rgb); hsv.z =clamp(hsv.z+0.2,0.0,1.0);
        inColor.rgb = original_HSV_2_rgb(hsv);
    }
    outTexture.write(inColor, gid);
    
}

kernel void kernel_fast_adjustHSV(
                                  texture2d<float, access::read> inTexture [[texture(0)]],
                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                  uint2 gid [[thread_position_in_grid]])
{
    float4 inColor   = inTexture.read(gid);
    
    for(int i=0; i<50; i++){
        
        float3 hsv = rgb_2_HSV(inColor.rgb); hsv.x = 0.5;
        inColor.rgb = HSV_2_rgb(hsv);
        
        //
        // тут может быть какой-то другой код
        //
        
        hsv = rgb_2_HSV(inColor.rgb); hsv.y =clamp(hsv.y+0.5,0.0,1.0);
        inColor.rgb = HSV_2_rgb(hsv);
        
        //
        // тут может быть еще какой-то код
        //
        
        hsv = rgb_2_HSV(inColor.rgb); hsv.z =clamp(hsv.z+0.2,0.0,1.0);
        inColor.rgb = HSV_2_rgb(hsv);
    }
    
    outTexture.write(inColor, gid);
    
}