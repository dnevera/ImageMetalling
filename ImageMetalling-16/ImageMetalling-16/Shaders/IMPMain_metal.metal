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
#include <SceneKit/scn_metal> 

#include "MLSSolver.hpp"
#include "MLSSolverCommon.h"

// Стандартные параметры модели (узла) 
typedef struct  {
    float4x4 modelTransform;
    float4x4 modelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
} NodeBuffer;

// Стандартные параметры вершины
typedef struct {    
    float3 position  [[ attribute(SCNVertexSemanticPosition) ]];
    float3 normal    [[ attribute(SCNVertexSemanticNormal) ]];
} VertexInput;


// Результат вершинного шейдера 
typedef struct {
    float4 position [[position]];
    float2 texCoords;
    float3 rgb;
    float3 surfaceColor;
} VertexOutput;


// Основной вершинный шейдер программы
vertex VertexOutput projectionVertex(VertexInput in [[ stage_in ]],
                                     texture3d<float, access::sample> lut3d  [[texture(0)]],
                                     constant SCNSceneBuffer &scn_frame     [[buffer(0)]],
                                     constant NodeBuffer   &scn_node      [[buffer(1)]]
                                     )
{    
    VertexOutput vert;
    
    // конвертируем координаты [-1:1] в представление цветов: [0:1]
    vert.rgb =  (in.position+1) * 0.5;
    
    // прикладываем LUT
    vert.rgb = lut3d.sample(IMProcessing::lutSampler, vert.rgb).rgb;
    
    // вычисляем новую позицию вершины 
    float3 pos = (vert.rgb - 0.5) * 2;
    
    // позиционируем в соответствии с проекцией
    vert.position   = scn_node.modelViewProjectionTransform * float4(pos, 1.0);
    
    return vert;
}

// Фрагментный шейдер программы
fragment float4 materialFragment(VertexOutput in [[stage_in]])
{
    // текущий семпл    
            
    return float4(in.rgb, 0.6);
}

kernel void kernel_mlsSolver(
                             constant float2  *input_points  [[buffer(0)]],
                             device float2    *output_points [[buffer(1)]],
                             constant float2  *p      [[buffer(2)]],
                             constant float2  *q      [[buffer(3)]],
                             constant int    &count   [[buffer(4)]],
                             constant MLSSolverKind  &kind [[buffer(5)]],
                             constant float    &alpha [[buffer(6)]],
                             uint gid [[thread_position_in_grid]]
                             ){
    float2 point = input_points[gid];
    MLSSolver solver = MLSSolver(point,p,q,count,kind,alpha);
    output_points[gid] = solver.value(point);
}
