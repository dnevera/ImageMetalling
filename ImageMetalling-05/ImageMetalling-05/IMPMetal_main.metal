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

///
/// Контейнер счета интенсивностей
///
typedef struct {
    //
    // MSL предоставляет полноценный интерфейс к атомарным операцией в стиле C++11.
    // Атомарные операции как известно могут быть безопасно использованы для доступа
    // к одним итем же переменным или объектам памяти из разных потоков. В случае с MSL
    // эти операции возможны только для типов atomic_int/atomic_uint.
    //
    atomic_uint count;
    atomic_uint channel[kIMP_HistogramChannels][kIMP_HistogramSize];
}IMPHistogramBuffer;

///
/// Функция счета.
///
kernel void kernel_impHistogramRGBYCounter(
                                       //
                                       // Исходная текстура интенсивности которой нам нужно посчиать.
                                       //
                                       texture2d<float, access::sample>  inTexture  [[texture(0)]],
                                       //
                                       // Выходная текстура прилетает в качестве изыточного указателя на исходный объект
                                       // в этой конкретной реализации не используется
                                       //
                                       texture2d<float, access::write>   outTexture [[texture(1)]],
                                       //
                                       // Вот собственно структурированный кусок памяти который мы используем для
                                       // подсчета бинов гистограммы. В памяти СPU структура инициализированна
                                       // как 2D массив uint-ов.
                                       // Каждая строка массив значений бинов гистограммы.
                                       //
                                       device IMPHistogramBuffer         &out       [[ buffer(0) ]],
                                       uint2 gid [[thread_position_in_grid]]
                                       )
{
    float4 inColor = inTexture.read(gid);
    
    //
    // Максимальный индекс каждого канала в массиве бинов
    //
    constexpr float3 Im(kIMP_HistogramSize - 1);
    
    //
    // Вектор преобрахования RGB в яркостный канал Y из YCbCr
    //
    constexpr float3 Ym(0.299, 0.587, 0.114);
    
    //
    // Его тоже растянем до размерности гистограмы
    //
    uint   Y   = uint(dot(inColor.rgb,Ym) * inColor.a * Im.x);
    
    //
    // Индексы каналов rgb
    //
    uint3  rgb = uint3(inColor.rgb * Im);
    
    //
    // Каждый объект инкримента - указатель на участок памяти в 2D массиве номер строки == номеру канала,
    // в нашем конкретном случае RGB,Y.
    // Номер индекса - значении бина которое мы будем инкриментировать каждым попавшим в него занчением интенсиваности
    // конкретного канала.
    // И вот тут нам очень облегчает жизнь объявление переменной адресов как атомарного типа - такая возможность
    // гарантирует неконфликтную инкрементацию значений в множетсвенном массиве вычислительных потоков GPU.
    //
    // Если бы такой возможности в MSL не существовало, нам бы пришлось попотеть: ипользовать подход рекурсивной
    // обработки текстуры в графических шейдерах, как это, например, описано в:
    // http://www.shaderwrangler.com/publications/histogram/histogram_cameraready.pdf
    //
    
    //
    // Для инкрементации каждой ячейки используем атомарные операции!
    //
    atomic_fetch_add_explicit(&out.channel[0][rgb.r], 1, memory_order_relaxed);
    atomic_fetch_add_explicit(&out.channel[1][rgb.g], 1, memory_order_relaxed);
    atomic_fetch_add_explicit(&out.channel[2][rgb.b], 1, memory_order_relaxed);
    atomic_fetch_add_explicit(&out.channel[3][Y],     1, memory_order_relaxed);
    
    //
    // До кучи считаем сколько бинов содержат каналы.
    //
    atomic_fetch_add_explicit(&out.count, 1, memory_order_relaxed);
    
    outTexture.write(inColor,gid);
}
