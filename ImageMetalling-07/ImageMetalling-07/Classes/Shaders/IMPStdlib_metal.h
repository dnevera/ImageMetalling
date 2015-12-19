//
//  IMPStdlib_metal.h
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 17.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPStdlib_metal_h
#define IMPStdlib_metal_h

#include <metal_stdlib>
#include <simd/simd.h>

#include "IMPTypes_metal.h"
#include "IMPConstants_metal.h"
#include "IMPHistogram_metal.h"
#include "IMPHistogramLayer_metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPCommon_metal.h"
#include "IMPBlending_metal.h"
#include "IMPAdjustment_metal.h"

#ifdef __cplusplus

namespace IMProcessing
{    
    kernel void kernel_passthrough(texture2d<float, access::sample> inTexture [[texture(0)]],
                                   texture2d<float, access::write> outTexture [[texture(1)]],
                                   uint2 gid [[thread_position_in_grid]])
    {
        float4 inColor = IMProcessing::sampledColor(inTexture,outTexture,gid);
        outTexture.write(inColor, gid);
    }
}

#endif

#endif /*IMPStdlib_metal_h*/
