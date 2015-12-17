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

using namespace metal;

#ifdef __cplusplus

namespace IMProcessing
{
    
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
