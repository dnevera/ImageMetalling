//
//  IMPMetal_main.metal
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 15.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

inline float when_eq(float x, float y) {
    return 1.0 - abs(sign(x - y));
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
               when_eq(inTexture.get_width(), w) // whe equal read exact texture color
               );
}

kernel void kernel_passthrough(texture2d<float, access::sample> inTexture [[texture(0)]],
                               texture2d<float, access::write> outTexture [[texture(1)]],
                               uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = sampledColor(inTexture,outTexture,gid);
    outTexture.write(inColor, gid);
}
