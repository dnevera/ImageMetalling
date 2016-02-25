//
//  IMPMain_metal.metal
//  ImageMetalling-09
//
//  Created by denis svinarchuk on 01.01.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


#include "IMPStdlib_metal.h"

///
///  @brief Kernel compute partial variability
///
kernel void kernel_variabilityPartial(
                                       texture2d<float, access::sample>   inTexture  [[texture(0)]],
                                       device   IMPHistogramBuffer        *outArray  [[ buffer(0)]],
                                       constant uint                      &channels  [[ buffer(1)]],
                                       constant IMPCropRegion             &regionIn  [[ buffer(2)]],
                                       constant float                     &scale     [[ buffer(3)]],
                                       uint  tid      [[thread_index_in_threadgroup]],
                                       uint2 groupid  [[threadgroup_position_in_grid]],
                                       uint2 groupSize[[threadgroups_per_grid]]
                                       )
{
    threadgroup atomic_int temp[kIMP_HistogramMaxChannels][kIMP_HistogramSize];
    
    uint w      = uint(float(inTexture.get_width())*scale)/groupSize.x;
    uint h      = uint(float(inTexture.get_height())*scale);
    uint size   = w*h;
    uint offset = kIMP_HistogramSize;
    
    for (uint i=0; i<channels; i++){
        atomic_store_explicit(&(temp[i][tid]),0,memory_order_relaxed);
    }
    
    threadgroup_barrier(mem_flags::mem_threadgroup);
    
    for (uint i=0; i<size; i+=offset){
        
        uint  j = i+tid;
        uint2 gid(j%w+groupid.x*w,j/w);
        
        uint4  rgby = IMProcessing::channel_binIndex(inTexture,regionIn,scale,gid);
        
        //
        // Заменяем канал яркости гистограммы на квадратичное расстояние вектора RGB
        // который описывает 
        //
        rgby.y = uint(length_squared(float3(rgby.rgb))/3);
        
        for (uint c=0; c<channels; c++){
            atomic_fetch_add_explicit(&(temp[c][rgby[c]]), 1, memory_order_relaxed);
        }
    }
    
    threadgroup_barrier(mem_flags::mem_threadgroup);
    
    for (uint i=0; i<channels; i++){
        outArray[groupid.x].channels[i][tid]=atomic_load_explicit(&(temp[i][tid]), memory_order_relaxed);
    }
}
