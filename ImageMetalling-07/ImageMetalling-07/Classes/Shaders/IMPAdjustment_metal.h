//
//  IMPAdjustment_metal.h
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 17.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPAdjustment_metal_h
#define IMPAdjustment_metal_h

#include "IMPStdlib_metal.h"

using namespace metal;

#ifdef __cplusplus

namespace IMProcessing
{
    kernel void kernel_desaturate(texture2d<float, access::sample> inTexture [[texture(0)]],
                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                  uint2 gid [[thread_position_in_grid]])
    {
        float4 inColor = IMProcessing::sampledColor(inTexture,outTexture,gid);
        inColor.rgb = float3(dot(inColor.rgb,IMProcessing::Y_mean_factor));
        outTexture.write(inColor, gid);
    }
}

#endif

#endif /* IMPAdjustment_metal_h */
