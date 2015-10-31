//
//  ImageMetalling-02-mainMetal.metal
//  ImageMetalling-02
//
//  Created by denis svinarchuk on 31.10.15.
//  Copyright © 2015 ImageMetalling. All rights reserved.
//

#include <metal_stdlib>
#include "DPMetal_main.h"
using namespace metal;



kernel void kernel_adjustCustom(
                             texture2d<float, access::sample> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             constant float &adjustment                 [[buffer(0)]],
                             uint2 gid [[thread_position_in_grid]]
                             )
{
    float4 inColor = inTexture.read(gid);
    
    //  luminance
    float  value = dot(inColor.rgb, float3(0.299, 0.587, 0.114));
    // mix color and saturation
    float4 outColor(mix(float4(float3(value), 1.0), inColor, adjustment));

    outTexture.write(outColor, gid);
}
