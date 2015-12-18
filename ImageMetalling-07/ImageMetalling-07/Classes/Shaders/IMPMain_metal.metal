//
//  IMPMetal_main.metal
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 15.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#include "IMPStdlib_metal.h"

///
/// Функция счета через атомарные операции.
///
kernel void kernel_impHistogramCuda(
                                    texture2d<float, access::sample>   inTexture  [[texture(0)]],
                                    device   IMPHistogramPartialBuffer &out       [[ buffer(0)]],
                                    constant IMPCropRegion             &regionIn  [[ buffer(1)]],
                                    constant float                     &scale     [[ buffer(2)]],
                                    uint  tid [[thread_index_in_threadgroup]]
                                    )
{
    threadgroup atomic_int temp[kIMP_HistogramChannels][kIMP_HistogramSize];
    
    for (uint i=0; i<kIMP_HistogramChannels; i++){
        atomic_store_explicit(&(temp[i][tid]),0,memory_order_relaxed);
    }
    
    threadgroup_barrier(mem_flags::mem_threadgroup);
    
    uint w      = uint(float(inTexture.get_width())*scale);
    uint h      = uint(float(inTexture.get_height())*scale);
    uint size   = w*h;
    uint offset = kIMP_HistogramSize;
    
    for (uint i=0; i<size; i+=offset){
        
        uint  j = i+tid;
        uint  x = j%w;
        uint  y = j/w;
        uint2 gid(x,y);
        
        uint4  rgby = IMProcessing::channel_binIndex(inTexture,regionIn,scale,gid);

        if (rgby.a>0){
            for (uint c=0;
                 c<kIMP_HistogramChannels; c++){
                atomic_fetch_add_explicit(&(temp[c][rgby[c]]), 1, memory_order_relaxed);
            }
        }
    }
    
    threadgroup_barrier(mem_flags::mem_threadgroup);
    
    for (uint i=0; i<kIMP_HistogramChannels; i++){
        out.channels[i][tid]=atomic_load_explicit(&(temp[i][tid]), memory_order_relaxed);
    }
}

