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

///  @brief Тензорное произведение
///
///  @param tensor тензор контрольных точек
///  @param vector вектор позиции
///
///  @return матрица
inline const float4x4 operator*(IMPFloat2x4x4 const tensor, float4 const vector) {
    float4 v[4] = {float4(0),float4(0),float4(0),float4(0)};
    for (int j=0; j<4; j++){
        for (int i=0; i<4; i++){
            v[j] += float4(tensor.vectors[i][j],0,0)*vector[i];
        }
    }
    return float4x4(v[0],v[1],v[2],v[3]);
}

///  @brief Тензорное произведение
///
///  @param vector вектор позиции
///  @param tensor тензор контрольных точек
///
///  @return матрица
inline const float4x4 operator*(float4 const vector, IMPFloat2x4x4 const tensor) {
    float4 v[4] = {float4(0),float4(0),float4(0),float4(0)};
    for (int j=0; j<4; j++){
        for (int i=0; i<4; i++){
            v[i] += float4(tensor.vectors[j][i],0,0)*vector[j];
        }
    }
    return float4x4(v[0],v[1],v[2],v[3]);
}

///  @brief Деформация поверхностью Безье на плоскости
///
fragment float4 fragment_bezierWarpTransformation(
                                                  IMPVertexOut in [[stage_in]],
                                                  // исходная текстура
                                                  texture2d<float, access::sample>  inTexture [[texture(0)]],
                                                  // контрольные точки
                                                  const device IMPFloat2x4x4        &surface  [[ buffer(0) ]],
                                                  // цвет фона
                                                  const device float4               &color    [[ buffer(1) ]]
                                                  ){
    
    constexpr sampler s(address::clamp_to_zero, filter::linear, coord::normalized);
    float3 p = float3(in.texcoord.xy,0);
    
    //
    // Финальная трансформация через эквивалетное тензорное произведение
    //
    // Q(u,v) = (u^3,u^2,u,1)B[P]B(v^3,v^2,v,1)
    // где [P] - тензор контрольных точек
    // https://en.wikipedia.org/wiki/Non-uniform_rational_B-spline
    // http://sernam.ru/book_mm3d.php?id=109
    // https://youtu.be/4sKocFWugiM
    //
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

