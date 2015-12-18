//
//  IMPMetal_main.metal
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 15.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#include "IMPStdlib_metal.h"

kernel void kernel_histogramLayer(texture2d<float, access::read>    inTexture   [[texture(0)]],
                                  texture2d<float, access::write>   outTexture  [[texture(1)]],
                                  constant IMPHistogramFloatBuffer  &histogram  [[buffer(0)]],
                                  constant uint                     &channels   [[buffer(1)]],
                                  constant IMPHistogramLayer        &layer      [[buffer(2)]],
                                  uint2 gid [[thread_position_in_grid]])
{

    constexpr uint Im(kIMP_HistogramSize - 1);

    float4 inColor   = inTexture.read(gid);

    float  width             = float(outTexture.get_width());
    float  height            = float(outTexture.get_height());
    float  y_position        = (height-float(gid.y));
    
    uint   histogramBinIndex = uint(gid.x/width*Im);   // normalize to histogram length
    float  delim = height;
    
    float4 result;
    if (layer.backgroundSource){
        result = inColor;
    }
    else{
        result = layer.backgroundColor;
    }
    
    for (uint c=0; c<channels; c++){
        
        float4 component = layer.components[c];
        
        uint   bin       = uint(histogram.channels[c][histogramBinIndex]*delim);   // red bin value
        float  opacity   = y_position>=bin?0.0:1.0*component.a;
        
        float4 color     = float4(component.r,component.g,component.b,opacity);
        
        result = IMProcessing::blendNormal(result, color);
    }
    
    outTexture.write(result, gid);
}
