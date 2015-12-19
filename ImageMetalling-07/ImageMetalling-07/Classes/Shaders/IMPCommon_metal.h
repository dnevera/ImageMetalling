//
//  IMPCommon_metal.h
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 17.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPCommon_metal_h
#define IMPCommon_metal_h

#include <metal_stdlib>
#include "IMPTypes_metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPConstants_metal.h"

using namespace metal;

#ifdef __cplusplus

namespace IMProcessing
{
    
    // maxComponent
    
    inline float sinc(float x){
        return sin(x*M_PI_H)/(x*M_PI_H);
    }
    
    inline float lanczos(float x, float a){
        if (x == 0.0) { return 1.0;}
        if (abs(x)<a) {return sinc(x) * sinc(x/a); }
        return 0.0;
    }
    
    inline float gaus_distribution(float x, float fi, float mu, float sigma){
        return fi * exp(- pow( (x-mu),2.0) / (2* pow(sigma,2.0)));
    }
    
    template<typename T> METAL_FUNC T max_component(vec<T, 2> v) {
        return max(v[0], v[1]);
    }
    
    template<typename T> METAL_FUNC T max_component(vec<T, 3> v) {
        return max(v[0], max(v[1], v[2]));
    }
    
    template<typename T> METAL_FUNC T max_component(vec<T, 4> v) {
        vec<T, 2> v2 = max(vec<T, 2>(v[0], v[1]), vec<T, 2>(v[2], v[3]));
        return max(v2[0], v2[1]);
    }
    
    // minComponent
    
    template<typename T> METAL_FUNC T min_component(vec<T, 2> v) {
        return min(v[0], v[1]);
    }
    
    template<typename T> METAL_FUNC T min_component(vec<T, 3> v) {
        return min(v[0], min(v[1], v[2]));
    }
    
    template<typename T> METAL_FUNC T min_component(vec<T, 4> v) {
        vec<T, 2> v2 = min(vec<T, 2>(v[0], v[1]), vec<T, 2>(v[2], v[3]));
        return min(v2[0], v2[1]);
    }
    
    
    template<typename T> METAL_FUNC T lum(vec<T, 3> c) {
        return dot(c, Y_YCbCr_factor);
    }
    
    
    inline float3 clipcolor_wlum(float3 c, float wlum) {
        
        float l = wlum;
        float n = min_component(c);
        float x = max_component(c);
        
        if (n < 0.0) {
            float v = 1.0/(l - n);
            c.r = l + ((c.r - l) * l) * v;
            c.g = l + ((c.g - l) * l) * v;
            c.b = l + ((c.b - l) * l) * v;
        }
        if (x > 1.0) {
            float v = 1.0/(x - l);
            c.r = l + ((c.r - l) * (1.0 - l)) * v;
            c.g = l + ((c.g - l) * (1.0 - l)) * v;
            c.b = l + ((c.b - l) * (1.0 - l)) * v;
        }
        
        return c;
    }
    
    inline float3 clipcolor(float3 c) {
        return clipcolor_wlum(c,lum(c));
    }
    
    inline float3 setlum(float3 c, float l) {
        float ll = lum(c);
        float d = l - ll;
        c = c + float3(d);
        return clipcolor_wlum(c,ll);
    }
    
    
    inline  float sat(float3 c) {
        float n = min_component(c);
        float x = max_component(c);
        return x - n;
    }
    
    inline  float mid(float cmin, float cmid, float cmax, float s) {
        return ((cmid - cmin) * s) / (cmax - cmin);
    }
    
    inline  float3 setsat(float3 c, float s) {
        if (c.r > c.g) {
            if (c.r > c.b) {
                if (c.g > c.b) {
                    /* g is mid, b is min */
                    c.g = mid(c.b, c.g, c.r, s);
                    c.b = 0.0;
                } else {
                    /* b is mid, g is min */
                    c.b = mid(c.g, c.b, c.r, s);
                    c.g = 0.0;
                }
                c.r = s;
            } else {
                /* b is max, r is mid, g is min */
                c.r = mid(c.g, c.r, c.b, s);
                c.b = s;
                c.r = 0.0;
            }
        } else if (c.r > c.b) {
            /* g is max, r is mid, b is min */
            c.r = mid(c.b, c.r, c.g, s);
            c.g = s;
            c.b = 0.0;
        } else if (c.g > c.b) {
            /* g is max, b is mid, r is min */
            c.b = mid(c.r, c.b, c.g, s);
            c.g = s;
            c.r = 0.0;
        } else if (c.b > c.g) {
            /* b is max, g is mid, r is min */
            c.g = mid(c.r, c.g, c.b, s);
            c.b = s;
            c.r = 0.0;
        } else {
            c = float3(0.0);
        }
        return c;
    }

    inline float4 sampledColor(
                               texture2d<float, access::sample> inTexture,
                               texture2d<float, access::write> outTexture,
                               uint2 gid
                               ){
        constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
        float w = outTexture.get_width();
        return mix(inTexture.sample(s, float2(gid) * float2(1.0/w, 1.0/outTexture.get_height())),
                   inTexture.read(gid),
                   IMProcessing::when_eq(inTexture.get_width(), w) // whe equal read exact texture color
                   );
    }
}

#endif

#endif /* IMPCommon_metal_h */
