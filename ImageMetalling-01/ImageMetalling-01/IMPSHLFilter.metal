//
//  IMPFilter.metal
//  ImageMetalling-00
//
//  Created by denis svinarchuk on 27.10.15.
//  Copyright © 2015 ImageMetalling. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

inline float4 blendNormal(float4 c2, float4 c1)
{
    //
    // from: https://github.com/BradLarson/GPUImage
    //
    
    float4 outputColor;
    
    float a = c1.a + c2.a * (1.0 - c1.a);
    float alphaDivisor = a + step(a, 0.0);
    
    outputColor.r = (c1.r * c1.a + c2.r * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.g = (c1.g * c1.a + c2.g * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.b = (c1.b * c1.a + c2.b * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.a = a;
    
    return clamp(outputColor, float4(0.0), float4(1.0));
}

typedef struct{
    packed_float4 shadows;       // [level, weight, tonal width, slop]
} IMPShadows;


//
// Прямое переложение функции расчета веса светов в якростном канале сигнала
//
inline float luminance_weight(float Li, float W, float Wt, float Ks){
    return W / exp( 6 * Ks * Li / Wt) * Wt;
}

//
// РЕзультирующая функция коррекции теней
//
inline float4 adjustShadows(float4 source, constant IMPShadows &adjustment)
{
    float3 rgb = source.rgb;

    //
    // выучите эту строчку наизусть, используется почти везде
    // можно запомнить как 3/6/1
    //
    // почитать можно тут: https://en.wikipedia.org/wiki/Relative_luminance
    // исходная формула относительной яркости в колорометрии:
    // Y = 0.2126 R + 0.7152 G + 0.0722 B
    // но мы работаем не с колорметрически измеренным значением RGB, а с представлением
    // rgb в виде sRGB цветового пространства. Так случилось, что быстрое преобразование:
    // L(rgb)= (r,g,b)(0.299, 0.587, 0.114)', для наших целей подходит лучше
    // и подтверждается рядом экспериментов с большим набором изображений.
    //
    float luminance = dot(rgb, float3(0.299, 0.587, 0.114));

    //
    // Распаковываем выходной буфер, прилетевший из памяти приложения в память GPU
    // подразумеваем:
    // 1. x - уровень воздействия фильтра
    // 2. y - коэффициент нормализации фильтра (по умолчанию = 1 и мы его не трогаем)
    // 3. z - тональная ширина охвата фильтра, т.е. насколько далеко мы восстанавливаем тени от черной точки
    // 4. w - коэффициент наклона (slope) кривой фильтра, т.е. скорость сниения воздействия в зависимости от
    //        яркости
    //
    float4 shadows(adjustment.shadows);
    
    float weight = luminance_weight(luminance,
                                    shadows.y,
                                    shadows.z,
                                    shadows.w);
    
    //
    // Альфа канал - функция уровня воздействия фильтра и вес от яркости
    //
    float  a(shadows.x * weight);
    
    //
    // Функция смешивания в режиме screen 2 раза или
    // гаммакорекция негатива с гаммой == 4
    //
    float3 c(1.0 - pow((1.0 - rgb),4));
    
    //
    // Результат смешиваем в нормальном режиме с учетом композиции в альфа канале
    //
    return blendNormal (source, float4 (c , a));
}


kernel void kernel_adjustSHL(
                             texture2d<float, access::sample> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             constant IMPShadows &adjustment             [[buffer(0)]],
                             uint2 gid [[thread_position_in_grid]]
                             )
{
    float4 inColor = inTexture.read(gid);
    outTexture.write(adjustShadows(inColor, adjustment), gid);
}
