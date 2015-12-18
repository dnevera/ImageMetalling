//
//  File.metal
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 17.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPHistogram_h
#define IMPHistogram_h

#include <metal_stdlib>
#include "IMPTypes_metal.h"
#include "IMPHistogramTypes_metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPConstants_metal.h"

using namespace metal;

#ifdef __cplusplus

namespace IMProcessing
{
    
    namespace histogram{
        //
        // Линейно отсемплируем входную тектсуру до размера заданного параметром scale.
        // Предполагаем, что изменеяем размер всегда в меньшую сторону.
        //
        inline float4 sampledColor(
                                   texture2d<float, access::sample> inTexture,
                                   float                   scale,
                                   uint2 gid
                                   ){
            constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
            
            float w = float(inTexture.get_width())  * scale;
            float h = float(inTexture.get_height()) * scale;
            
            return mix(inTexture.sample(s, float2(gid) * float2(1.0/w, 1.0/h)),
                       inTexture.read(gid),
                       IMProcessing::when_eq(inTexture.get_width(), w) // whe equal read exact texture color
                       );
        }
        
        
        //
        // Проверка региона в котором вычисляем гистограмму
        //
        inline  float coordsIsInsideBox(float2 v, float2 bottomLeft, float2 topRight) {
            float2 s =  step(bottomLeft, v) - step(topRight, v);
            return s.x * s.y;
        }
        
        inline float4 histogramSampledColor(
                                            texture2d<float, access::sample>  inTexture,
                                            constant IMPCropRegion          &regionIn,
                                            float                    scale,
                                            uint2 gid){
            
            float w = float(inTexture.get_width())  * scale;
            float h = float(inTexture.get_height()) * scale;
            
            float2 coords  = float2(gid) * float2(1.0/w,1.0/h);
            //
            // для всех пикселей за пределами расчета возвращаем чорную точку с прозрачным альфа-каналом
            //
            float  isBoxed = coordsIsInsideBox(coords, float2(regionIn.left,regionIn.bottom), float2(1.0-regionIn.right,1.0-regionIn.top));
            return sampledColor(inTexture,scale,gid) * isBoxed;
        }
        
    }
    
    
    inline uint4 channel_binIndex(
                                  texture2d<float, access::sample>  inTexture,
                                  constant IMPCropRegion          &regionIn,
                                  constant float                    &scale,
                                  uint2 gid [[thread_position_in_grid]]
                                  ){
        constexpr float3 Im(kIMP_HistogramSize - 1);
        
        float4 inColor = histogram::histogramSampledColor(inTexture,regionIn,scale,gid);
        uint   Y       = uint(dot(inColor.rgb,IMProcessing::Y_YCbCr_factor) * inColor.a * Im.x);
        
        return uint4(uint3(inColor.rgb * Im), Y);
    }
    
    ///
    /// Функция счета через атомарные операции.
    ///
    kernel void kernel_impHistogramRGBYCounter(
                                               texture2d<float, access::sample>  inTexture  [[texture(0)]],
                                               device   IMPHistogramBuffer       &out       [[ buffer(0)]],
                                               constant IMPCropRegion            &regionIn  [[ buffer(1)]],
                                               constant float                    &scale     [[ buffer(2)]],
                                               uint2 gid [[thread_position_in_grid]]
                                               )
    {
        uint4  rgby = channel_binIndex(inTexture,regionIn,scale,gid);
        //threadgroup_barrier(mem_flags::mem_device);
        if (rgby.a>0){
            for (uint i=0; i<kIMP_HistogramSize; i++){
                //atomic_fetch_add_explicit(&out.channels[i][rgby[i]], 1, memory_order_relaxed);
            }
        }
        //threadgroup_barrier(mem_flags::mem_device);
    }
    
    ///
    /// Функция счета частичной гистограммы.
    ///
    kernel void kernel_impPartialRGBYHistogram(
                                               texture2d<float, access::sample>       inTexture  [[texture(0)]],
                                               device   IMPHistogramPartialBuffer     *outArray  [[ buffer(0)]],
                                               constant IMPCropRegion                 &regionIn  [[ buffer(1)]],
                                               constant float                         &scale     [[ buffer(2)]],
                                               //
                                               // Позиция группы в сетке групп.
                                               // Выходная текстура будет заполняться в соответствие с номером этой группы
                                               //
                                               uint  tindexi [[thread_index_in_threadgroup]],
                                               uint2 gid     [[thread_position_in_grid]]
                                               )
    {
        uint4  rgby = channel_binIndex(inTexture,regionIn,scale,gid);
        
        threadgroup_barrier(mem_flags::mem_device);
        if (rgby.a>0){
            for (uint i=0; i<kIMP_HistogramSize; i++){
                outArray[tindexi].channels[i][rgby[i]]++;
            }
        }
        threadgroup_barrier(mem_flags::mem_device);
    }
}

#endif

#endif
