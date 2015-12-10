//
//  IMPMetal_main.metal
//  ImageMetalling-03
//
//  Created by denis svinarchuk on 04.11.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#include <metal_stdlib>
#include "DPMetal_main.h"
#include "IMPHistogramConstatnts.h"

using namespace metal;

namespace histogram{
    //
    // Линейно отсемплируем входную тектсуру до размера заданного параметром scale.
    // Предполагаем, что изменеяем размер всегда в меньшую сторону.
    //
    METAL_FUNC float4 sampledColor(
                                   texture2d<float, access::sample> inTexture,
                                   float                   scale,
                                   uint2 gid
                                   ){
        constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
        
        float w = float(inTexture.get_width())  * scale;
        float h = float(inTexture.get_height()) * scale;
        
        return mix(inTexture.sample(s, float2(gid) * float2(1.0/w, 1.0/h)),
                   inTexture.read(gid),
                   when_eq(inTexture.get_width(), w) // whe equal read exact texture color
                   );
    }
    
    
    //
    // Проверка региона в котором вычисляем гистограмму
    //
    METAL_FUNC  float coordsIsInsideBox(float2 v, float2 bottomLeft, float2 topRight) {
        float2 s =  step(bottomLeft, v) - step(topRight, v);
        return s.x * s.y;
    }
    
    METAL_FUNC float4 histogramSampledColor(
                                            texture2d<float, access::sample>  inTexture,
                                            constant DPCropRegionIn          &regionIn,
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


///
/// Контейнер счета интенсивностей
///
typedef struct {
    atomic_uint channel[kIMP_HistogramChannels][kIMP_HistogramSize];
}IMPHistogramBuffer;

typedef struct{
    uint channel[kIMP_HistogramChannels][kIMP_HistogramSize];
}IMPHistogramPartialBuffer;


constexpr constant float3 Ym(0.299, 0.587, 0.114);


///
/// Функция счета через атомарные операции.
///
kernel void kernel_impHistogramRGBYCounter(
                                           texture2d<float, access::sample>  inTexture  [[texture(0)]],
                                           device IMPHistogramBuffer        &out        [[ buffer(0)]],
                                           constant DPCropRegionIn          &regionIn   [[ buffer(1)]],
                                           constant float                   &scale      [[ buffer(2)]],
                                           uint2 gid [[thread_position_in_grid]]
                                           )
{
    float4 inColor = histogram::histogramSampledColor(inTexture,regionIn,scale,gid);
    constexpr float3 Im(kIMP_HistogramSize - 1);
    uint   Y   = uint(dot(inColor.rgb,Ym) * inColor.a * Im.x);
    uint4  rgby(uint3(inColor.rgb * Im), Y);
    
    threadgroup_barrier(mem_flags::mem_device);
    if (inColor.a>0){
        for (uint i=0; i<kIMP_HistogramChannels; i++){
            atomic_fetch_add_explicit(&out.channel[i][rgby[i]], 1, memory_order_relaxed);
        }
    }
    threadgroup_barrier(mem_flags::mem_device);
}

///
/// Подготавливаем RGBA структуру под vImageHistogramCalculation_ARGB8888
///
kernel void kernel_impHistogramVImageRGBY(
                                          texture2d<float, access::sample>  inTexture  [[texture(0)]],
                                          texture2d<float, access::write>  outTexture  [[texture(1)]],
                                          constant DPCropRegionIn          &regionIn   [[ buffer(0)]],
                                          constant float                   &scale      [[ buffer(1)]],
                                          uint2 gid [[thread_position_in_grid]]
                                          )
{
    float4 inColor = histogram::histogramSampledColor(inTexture,regionIn,scale,gid);
    
    float   Y   = dot(inColor.rgb,Ym) * inColor.a; // в гистограмме яркостного канала не учитываем 0
    float4  rgby(inColor.rgb, Y);
    outTexture.write(rgby,gid);
}

///
/// Функция счета частичной гистограммы.
///
kernel void kernel_impPartialRGBYHistogram(
                                           texture2d<float, access::sample>  inTexture   [[ texture(0) ]],
                                           device IMPHistogramPartialBuffer  *outArray   [[ buffer(0) ]],
                                           constant DPCropRegionIn          &regionIn    [[ buffer(1) ]],
                                           constant float                   &scale       [[ buffer(2) ]],
                                           //
                                           // Позиция группы в сетке групп.
                                           // Выходная текстура будет заполняться в соответствие с номером этой группы
                                           //
                                           uint  tindexi [[thread_index_in_threadgroup]],
                                           uint2 gid     [[thread_position_in_grid]]
                                           )
{
    constexpr float3 Im(kIMP_HistogramSize - 1);
    
    float4 inColor = histogram::histogramSampledColor(inTexture,regionIn,scale,gid);
    
    uint   Y    = uint(dot(inColor.rgb,Ym) * inColor.a * Im.x);
    uint4  rgby(uint3(inColor.rgb * Im), Y);
    
    threadgroup_barrier(mem_flags::mem_device);
    if (inColor.a>0){
        for (uint i=0; i<kIMP_HistogramChannels; i++){
            outArray[tindexi].channel[i][rgby[i]]++;
        }
    }
    threadgroup_barrier(mem_flags::mem_device);
}
