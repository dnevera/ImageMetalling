//
//  IMPMain_metal.metal
//  ImageMetalling-09
//
//  Created by denis svinarchuk on 01.01.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

#include <metal_stdlib>
#include "IMPStdlib_metal.h"
using namespace metal;

fragment float4 fragment_gridGenerator(
                                       IMPVertexOut in [[stage_in]],
                                       texture2d<float, access::sample> texture [[ texture(0) ]],
                                       const device uint    &gridStep     [[ buffer(0) ]],
                                       const device uint    &gridSubDiv   [[ buffer(1) ]],
                                       const device float4  &gridColor    [[ buffer(2) ]],
                                       const device float4  &gridSubDivColor    [[ buffer(3) ]]
                                       ) {
    
    constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
    
    
    uint x = uint(in.texcoord.x*texture.get_width());
    uint y = uint(in.texcoord.y*texture.get_height());
    uint sd = gridStep*gridSubDiv;
    
    float4 inColor = texture.sample(s, in.texcoord.xy);
    float4 color = inColor;
    
    if (x == 0 ) return color;
    if (y == 0 ) return color;
    
    if(x % sd == 0 || y % sd == 0 ) {
        
        color = IMProcessing::blendNormal(1-inColor, gridSubDivColor);

        if (x % 2 == 0 && y % 2 == 0){
            color = inColor;
        }
    }
    else if(x % gridStep==0 || y % gridStep==0) {
        
        color = IMProcessing::blendNormal(inColor, gridColor);
        
        if (x % 2 == 0 && y % 2 == 0){
            color = inColor;
        }
    }
    
    return color;
}
