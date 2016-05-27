//
//  IMPMetal_main.metal
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 15.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

//#include "IMPAdjustmentHSV_metal.h"
#include "IMPStdlib_metal.h"

///
/// @brief Kernel optimized HSV adjustment version
///
//kernel void kernel_adjustHSV3DLut(
//                                  texture3d<float, access::write>         hsv3DLut     [[texture(0)]],
//                                  texture1d_array<float, access::sample>  hueWeights   [[texture(1)]],
//                                  constant IMPHSVAdjustment               &adjustment  [[buffer(0) ]],
//                                  uint3 gid [[thread_position_in_grid]]){
//    
//    float4 input_color  = float4(float3(gid)/(hsv3DLut.get_width(),hsv3DLut.get_height(),hsv3DLut.get_depth()),1);
//    float4 result       = IMProcessing::adjustHSV(input_color, hueWeights, adjustment);
//    hsv3DLut.write(result, gid);
//}
