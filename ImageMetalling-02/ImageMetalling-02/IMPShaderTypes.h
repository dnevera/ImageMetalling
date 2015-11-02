//
//  IMPShaderTypes.hpp
//  ImageMetalling-02
//
//  Created by denis svinarchuk on 02.11.15.
//  Copyright © 2015 ImageMetalling. All rights reserved.
//

#ifndef IMPShaderTypes_h
#define IMPShaderTypes_h

#include <simd/simd.h>
using namespace metal;

//
// float4 - тип данных экспортируемых из Metal Framework
// .x - вес светов/теней 0-1
// .y - тональная ширины светов/теней над которыми производим операцию >0-1
// .w - степень подъема/наклона кривой воздействия [1-5]
//

typedef struct{
    float  level;
    float3 shadows;       // [weight, tonal width, slop]
    float3 highlights;    // [weight, tonal width, ascent]
} IMPShadowsHighLights;



#endif /* IMPShaderTypes_h */
