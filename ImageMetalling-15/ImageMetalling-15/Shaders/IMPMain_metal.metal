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
    float2 texCoords [[ attribute(SCNVertexSemanticTexcoord0) ]];
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
    
    vert.rgb =  (in.position+1) * 0.5;
            
    float3 rgb = lut3d.sample(IMProcessing::lutSampler, vert.rgb).rgb;    
    vert.rgb = rgb;
    
    float3 pos = (rgb - 0.5) * 2;
    vert.position   = scn_node.modelViewProjectionTransform * float4( pos, 1.0);    
    vert.texCoords  = in.texCoords;
    
    return vert;
}

// Фрагментный шейдер программы
fragment float4 materialFragment(VertexOutput in [[stage_in]])
{
    // текущий семпл    
    return float4(in.rgb, 1)/2;
}
