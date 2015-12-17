//
//  IMPFlowControl_metal.h
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 17.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPFlowControl_metal_h
#define IMPFlowControl_metal_h

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

#ifdef __cplusplus

namespace IMProcessing
{
    
    inline float when_eq(float x, float y) {
        return 1.0 - abs(sign(x - y));
    }
    
    inline  float when_neq(float x, float y) {
        return abs(sign(x - y));
    }
    
    inline  float when_gt(float x, float y) {
        return max(sign(x - y), 0.0);
    }
    
    inline  float when_lt(float x, float y) {
        return min(1.0 - sign(x - y), 1.0);
    }
    
    inline  float when_ge(float x, float y) {
        return 1.0 - when_lt(x, y);
    }
    
    inline  float when_le(float x, float y) {
        return 1.0 - when_gt(x, y);
    }
    
    inline  float  when_and(float a, float b) {
        return a * b;
    }
    
    inline  float  when_between_and(float x, float y, float h) {
        return when_ge(x - h, 0) * when_le(y - h, 0);
    }
    
    inline  float  when_or(float a, float b) {
        return min(a + b, 1.0);
    }
    
    inline  float when_not(float a) {
        return 1.0 - a;
    }
}

#endif

#endif /* IMPFlowControl_metal_h */
