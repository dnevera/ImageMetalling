//
//  IMPMain_metal.metal
//  ImageMetalling-09
//
//  Created by denis svinarchuk on 01.01.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

#include <metal_stdlib>
#include "IMPStdlib_metal.h"
#include "IMProcessing_metal.h"

using namespace metal;

/// 
/// Расчитываем средний цвет области текстуры
///
inline float3 avrgColor(int startx,   // начало области по x 
                        int endx,     // конец области по x
                        int starty,   // начало по y
                        int endy,     // конец y
                        uint2 gid,    // индекс семпла 
                        texture2d<float>  source // текстура
                        ){
    float3 color(0);
    float3 c(0);
    
    for(int i = startx; i<endx; i++ ){
        for(int j = starty; j<endy; j++ ){
            uint2 gid2 = uint2(int2(gid)+int2(i,j));
            float3 s = source.read(gid2).rgb;
            color += s;
            c+=float3(1);
        }
    }
    
    return color/c;
}

//
// Ядро чтения семплов текстуры с точностью до индекса и вычисление среднего значения цвета областей с центрами 
// в пространстве RGB 
//
kernel void kernel_regionColors(
                            // исходная текстура
                            metal::texture2d<float, metal::access::sample> source [[texture(0)]],
                            // список центров в которых нужно проситать семплы
                            device    float2 *centers   [[ buffer(0) ]],
                            // список усредненных цветов областей в которых мы прочитаем тектсуру 
                            device    float3 *colors    [[ buffer(1) ]],
                            // размер квадратной области 
                            constant  float &regionSize [[ buffer(2) ]],
                            // позиция треда GPU в гриде == индекс центра области  
                            uint2 tid [[thread_position_in_grid]]
                            )
{
    uint width  = source.get_width();
    uint height = source.get_height();
    float2 size = float2(width,height);
    

    float2 point = centers[tid.x];
    
    int rs = -regionSize/2;
    int re =  regionSize/2+1;
    uint2 gid = uint2(float2(point.x,point.y) * size);
    
    colors[tid.x] = avrgColor(rs, re,  rs, re, gid, source);
}

