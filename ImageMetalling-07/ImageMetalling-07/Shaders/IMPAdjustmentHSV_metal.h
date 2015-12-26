//
//  IMPAdjustmentHSB_metal.h
//  IMProcessing
//
//  Created by denis svinarchuk on 22.12.15.
//  Copyright © 2015 Dehancer.photo. All rights reserved.
//

#ifndef IMPAdjustmentHSB_metal_h
#define IMPAdjustmentHSB_metal_h

#ifdef __METAL_VERSION__

#include "IMPStdlib_metal.h"

using namespace metal;

#include "IMPSwift-Bridging-Metal.h"
#include "IMPConstants_metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPCommon_metal.h"
#include "IMPColorSpaces_metal.h"
#include "IMPBlending_metal.h"

#ifdef __cplusplus

namespace IMProcessingExample
{
    ///  @brief Получить семплированное значение веса из кривых весов перекрытия близких цветов круга HSV
    ///
    ///  @param hue       текущее значение тона цвета для определения веса перекрытия
    ///  @param weights   кривая весов тональной палитры перекрытий близких цветов.
    ///                   Веса расчтывается как массив одномерых текстур
    ///                   каждого тонального сектора цветового круга HSV.
    ///  @param index     текущий индекс сектора цветового круга HSV
    ///
    ///  @return вес перекрытия пиксела в цветовом пространстве hsv для заданного hue
    ///
    inline float weightOf(float hue, texture1d_array<float, access::sample>  weights, uint index){
        constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
        return weights.sample(s, hue, index).x;
    }


    ///  @brief Сдвинуть на -1..+1 значение яркостного канала HSV.
    ///
    ///  @param hsv        входное значение в пространстве HSV
    ///  @param levelOut   сдвиг
    ///  @param hue        текущее значение тона цвета для определения веса перекрытия
    ///  @param weights    кривая весов тональной палитры перекрытий близких цветов
    ///  @param index      текущий индекс сектора цветового круга HSV
    ///
    ///  @return новое значение пиксела в цветовом пространстве hsv
    ///
    inline float3 adjust_lightness(float3 hsv, float levelOut, float hue, texture1d_array<float, access::sample>  weights, uint index)
    {
        //
        // Значение сдвига яркостного канала с перекрытием близких цветов
        // рассматриваем не только как функцию значения сдвига но и функцию значениея каналы
        // насыщенности.
        //
        float v = 1.0 + levelOut * weightOf(hue,weights,index) * hsv.y;
        hsv.z = clamp(hsv.z * v, 0.0, 1.0);
        return hsv;
    }
    
    ///  @brief Сдвинуть на -1..+1 значение канала насыщенности HSV.
    ///
    ///  @param hsv        входное значение в пространстве HSV
    ///  @param levelOut   сдвиг
    ///  @param hue        текущее значение тона цвета для определения веса перекрытия
    ///  @param weights    кривая весов тональной палитры перекрытий близких цветов
    ///  @param index      текущий индекс сектора цветового круга HSV
    ///
    ///  @return новое значение пиксела в цветовом пространстве hsv
    ///
    inline float3 adjust_saturation(float3 hsv, float levelOut, float hue, texture1d_array<float, access::sample>  weights, uint index)
    {
        float v = 1.0 + levelOut * weightOf(hue,weights,index);
        hsv.y = clamp(hsv.y * v, 0.0, 1.0);
        return hsv;
    }
    
    ///  @brief Сдвинуть на -1..+1 значение канала тона HSV.
    ///
    ///  @param hsv        входное значение в пространстве HSV
    ///  @param levelOut   сдвиг
    ///  @param hue        текущее значение тона цвета для определения веса перекрытия
    ///  @param weights    кривая весов тональной палитры перекрытий близких цветов
    ///  @param index      текущий индекс сектора цветового круга HSV
    ///
    ///  @return новое значение пиксела в цветовом пространстве hsv
    ///
    inline float3 adjust_hue(float3 hsv, float levelOut, float hue, texture1d_array<float, access::sample>  weights, uint index){
        
        //
        // hue rotates with overlap ranages
        //
        hsv.x  = hsv.x + 0.5 * levelOut * weightOf(hue,weights,index);
        return hsv;
    }
    
    ///  @brief Установить новое значение поксела в соответствиями с параметрами сдвигов
    ///  каналов в каналах в каждом тональном секторе цветового пространства HSV.
    ///
    ///  @param input_color входной RGBA
    ///  @param hueWeights  веса перекрытий
    ///  @param adjust      параметры преображования
    ///
    ///  Параметры преобразования задаются объектом имеющим структуру уровней:
    ///
    ///  typedef struct{
    ///    float hue;
    ///    float saturation;
    ///    float value;
    ///  }IMPHSVLevel;
    ///
    ///  И настройки для каждом из секторов и мастер уровня
    ///  typedef struct {
    ///    IMPHSVLevel   master;
    ///    IMPHSVLevel   levels[kIMP_Color_Ramps];
    ///    IMPBlending   blending;
    ///  } IMPHSVAdjustment;
    ///
    ///
    ///  Сектора задются из фиксированного набора с исходными значениями перекрытий взятых из
    ///  Adobe Photoshop CC2015.
    ///
    ///  #define  kIMP_Color_Ramps  6
    ///
    ///  static constant metal_float4 kIMP_Reds        = {315.0, 345.0, 15.0,   45.0};
    ///  static constant metal_float4 kIMP_Yellows     = { 15.0,  45.0, 75.0,  105.0};
    ///  static constant metal_float4 kIMP_Greens      = { 75.0, 105.0, 135.0, 165.0};
    ///  static constant metal_float4 kIMP_Cyans       = {135.0, 165.0, 195.0, 225.0};
    ///  static constant metal_float4 kIMP_Blues       = {195.0, 225.0, 255.0, 285.0};
    ///  static constant metal_float4 kIMP_Magentas    = {255.0, 285.0, 315.0, 345.0};
    ///
    ///
    ///  @return новое значение пиксела в RGBA
    ///
    inline float4 adjustHSV(float4 input_color,
                            texture1d_array<float, access::sample>  hueWeights,
                            constant IMPHSVAdjustment              &adjust
                            ){
        
        float3 hsv = IMProcessing::rgb_2_HSV(input_color.rgb);
        
        float  hue = hsv.x;
        
        //
        // Для каждого из каналов сдвигаем значения в каждом мз секторов
        //
        // Сдвигаем яркости
        for (uint i = 0; i<kIMP_Color_Ramps; i++){
            hsv = adjust_lightness(hsv, adjust.levels[i].value,    hue, hueWeights, i);
        }
        
        // Сдвигаем насыщенности
        for (uint i = 0; i<kIMP_Color_Ramps; i++){
            hsv = adjust_saturation(hsv, adjust.levels[i].saturation,    hue, hueWeights, i);
        }
        
        //
        // Сдвигаем тона
        //
        for (uint i = 0; i<kIMP_Color_Ramps; i++){
            hsv = adjust_hue(hsv, adjust.levels[i].hue,    hue, hueWeights, i);
        }
        
        //
        // Устанавливаем мастер значение
        //
        hsv.z = clamp(hsv.z * (1.0 + adjust.master.value), 0.0, 1.0);
        hsv.y = clamp(hsv.y * (1.0 + adjust.master.saturation), 0.0, 1.0);
        hsv.x  = hsv.x + 0.5 * adjust.master.hue;
        
        float3 rgb(IMProcessing::HSV_2_rgb(hsv));
        
        //
        // Традиционно выбираем одно из смешиваний
        //
        if (adjust.blending.mode == 0)
            return IMProcessing::blendLuminosity(input_color, float4(rgb, adjust.blending.opacity));
        else
            return IMProcessing::blendNormal(input_color, float4(rgb, adjust.blending.opacity));
    }

    ///
    ///  @brief Ядро прямого преобразования.
    ///
    kernel void kernel_adjustHSVExample(texture2d<float, access::sample>  inTexture         [[texture(0)]],
                                 texture2d<float, access::write>   outTexture        [[texture(1)]],
                                 texture1d_array<float, access::sample>  hueWeights  [[texture(2)]],
                                 constant IMPHSVAdjustment               &adjustment  [[buffer(0)]],
                                 uint2 gid [[thread_position_in_grid]]){
        
        
        float4 input_color   = inTexture.read(gid);
        
        float4 result =  adjustHSV(input_color, hueWeights, adjustment);
        
        outTexture.write(result, gid);
    }
    
    ///
    /// @brief Ядро предварительного расчета LUT преобразования
    ///
    ///
    ///  @param hsv3DLut  3D текстура новой таблицы
    ///  @param hueWeights  веса перекрытий
    ///  @param adjust      параметры преображования
    ///
    kernel void kernel_adjustHSV3DLutExample(
                                      texture3d<float, access::write>         hsv3DLut     [[texture(0)]],
                                      texture1d_array<float, access::sample>  hueWeights   [[texture(1)]],
                                      constant IMPHSVAdjustment               &adjustment  [[buffer(0) ]],
                                      uint3 gid [[thread_position_in_grid]]){
        
        //
        // Вычисляем входной пиксел в 3D пространстве.
        //
        float4 input_color  = float4(float3(gid)/(hsv3DLut.get_width(),hsv3DLut.get_height(),hsv3DLut.get_depth()),1);
        
        //
        // Преобразовываем его в соостветсвие с параметрами сдвигов
        //
        float4 result       = IMProcessingExample::adjustHSV(input_color, hueWeights, adjustment);
        
        //
        // Пишем LUT
        //
        hsv3DLut.write(result, gid);
    }
}

#endif

#endif

#endif /* IMPAdjustmentHSB_metal_h */
