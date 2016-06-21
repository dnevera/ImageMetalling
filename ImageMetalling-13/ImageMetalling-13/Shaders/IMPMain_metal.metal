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

inline const float4x4 operator*(IMPFloat2x4x4 const tensor, float4 const vector) {
    float4 v[4] = {float4(0),float4(0),float4(0),float4(0)};
    for (int j=0; j<4; j++){
        for (int i=0; i<4; i++){
            v[j] += float4(tensor.vectors[i][j],0,0)*vector[i];
        }
    }
    return float4x4(v[0],v[1],v[2],v[3]);
}

inline const float4x4 operator*(float4 const vector, IMPFloat2x4x4 const tensor) {
    float4 v[4] = {float4(0),float4(0),float4(0),float4(0)};
    for (int j=0; j<4; j++){
        for (int i=0; i<4; i++){
            v[i] += float4(tensor.vectors[j][i],0,0)*vector[j];
        }
    }
    return float4x4(v[0],v[1],v[2],v[3]);
}

fragment float4 fragment_bezierWarpTransformation(
                                                  IMPVertexOut in [[stage_in]],
                                                  texture2d<float, access::sample>  inTexture [[texture(0)]],
                                                  const device IMPFloat2x4x4        &surface  [[ buffer(0) ]],
                                                  const device float4               &color    [[ buffer(1) ]]
                                                  ){
    
    constexpr sampler s(address::clamp_to_zero, filter::linear, coord::normalized);
    float3 p = float3(in.texcoord.xy,0);
    
    float4x4 B = {
        {-1,  3, -3, 1},
        { 3, -6,  3, 0},
        {-3,  3,  0, 0},
        { 1,  0,  0, 0}
    };
    
    float4 BU = float4(pow(p.x,3), pow(p.x,2), p.x, 1) * B;
    float4 BV = B * float4(pow(p.y,3), pow(p.y,2), p.y, 1);
    
    float4 position = surface*BV*BU;
    
    float4 inColor = inTexture.sample(s,position.xy);
    
    if (inColor.a==0) {
        inColor = color;
    }
    
    return inColor;
    
}


/////
///// Отрисовка сетки на текстуре объекта
/////
//fragment float4 fragment_gridGenerator(
//                                       // поток вершин
//                                       IMPVertexOut in [[stage_in]],
//                                       // текстура фото-пластины
//                                       texture2d<float, access::sample> texture [[ texture(0) ]],
//                                       // шаг сетки в пиксела
//                                       const device uint      &gridStep        [[ buffer(0) ]],
//                                       // шаг дополнительной подсетки кратной основной
//                                       const device uint      &gridSubDiv      [[ buffer(1) ]],
//                                       // цвет сетки
//                                       const device float4    &gridColor       [[ buffer(2) ]],
//                                       // цвет подсетки
//                                       const device float4    &gridSubDivColor [[ buffer(3) ]],
//                                       // цвет области подсветки
//                                       const device float4    &spotAreaColor   [[ buffer(4) ]],
//                                       // область подсветки
//                                       const device IMPRegion &spotArea        [[ buffer(5) ]],
//                                       // типа заливки подсветки: 0 == .Grid, 1 == Solid
//                                       const device uint      &spotAreaType    [[ buffer(6) ]]
//                                       ) {
//    
//    constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
//    
//    uint w = texture.get_width();
//    uint h = texture.get_height();
//    uint x = uint(in.texcoord.x*w);
//    uint y = uint(in.texcoord.y*h);
//    uint sd = gridStep*gridSubDiv;
//    
//    float4 inColor = texture.sample(s, in.texcoord.xy);
//    float4 color = inColor;
//    
//    if (x == 0 ) return color;
//    if (y == 0 ) return color;
//    
//    ///
//    /// Дополнительные украшения сетки - рисуем подсвечиваемую область
//    ///
//    float2 coords  = float2(in.texcoord.x,in.texcoord.y);
//    ///  @brief Утилита проверки принадлежности пиксеоа региону ограниченному отступами из пакета IMPHistogram shader
//    ///
//    ///  @param v          координата
//    ///  @param bottomLeft отступ снизу слева
//    ///  @param topRight   справа сверху
//    ///
//    ///  @return 0 or 1
//    ///
//    /// inline  float coordsIsInsideBox(float2 v, float2 bottomLeft, float2 topRight) {
//    ///    float2 s =  step(bottomLeft, v) - step(topRight, v);
//    ///    return s.x * s.y;
//    ///}
//
//    float  isBoxed = IMProcessing::histogram::coordsIsInsideBox(coords, float2(spotArea.left,spotArea.bottom), float2(1.0-spotArea.right,1.0-spotArea.top));
//    
//    //
//    // Рисуем сетку
//    //
//    if(x % sd == 0 || y % sd == 0 ) {
//        //
//        // Подсетка
//        //
//        color = IMProcessing::blendNormal(inColor, gridSubDivColor);
//     
//        if (x % 2 == 0 && y % 2 == 0) color = inColor;
//        else if ((gridStep+1)%2 == 0) {
//            if (x % 2 != 0 && y % 2 != 0) color = inColor;
//        }
//        
//        if (spotAreaType == 0 && isBoxed) {
//            color = IMProcessing::blendNormal(color, spotAreaColor);
//        }
//
//    }
//    else if(x % gridStep==0 || y % gridStep==0) {
//        
//        color = IMProcessing::blendNormal(inColor, gridColor);
//        
//        //
//        // В основной сетке рисуем пикселы через раз
//        // (а можно как угодно, но захотелось так, по типу того как сделано по умолчанию в PS)
//        //
//        if (x % 2 == 0 && y % 2 == 0) color = inColor;
//        else if ((gridStep+1)%2 == 0) {
//            if (x % 2 != 0 && y % 2 != 0) color = inColor;
//        }
//        
//        if (spotAreaType == 0 && isBoxed) {
//            color = IMProcessing::blendNormal(color, spotAreaColor);
//        }
//
//    }
//
//    if (spotAreaType == 1 && isBoxed) {
//        color = IMProcessing::blendNormal(color, spotAreaColor);
//    }
//
//    return color;
//}
