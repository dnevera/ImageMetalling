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

#include "IMPMLSSolver.h"
#include "IMPMLSSolverCommon.h"

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
    float3 rgb = lut3d.sample(IMProcessing::lutSampler, vert.rgb).rgb;
    
    // вычисляем новую позицию вершины 
    float3 pos = (rgb - 0.5) * 2;
    
    // позиционируем в соответствии с проекцией
    vert.position   = scn_node.modelViewProjectionTransform * float4(pos, 1.0);
    
    return vert;
}

// Фрагментный шейдер программы
fragment float4 materialFragment(VertexOutput in [[stage_in]])
{
    // текущий семпл    
    
    return float4(in.rgb, 0.5);
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
    IMPMLSSolver solver = IMPMLSSolver(point,p,q,count,kind,alpha);
    output_points[gid] = solver.value(point);
}


inline float4 color_plane(float2 xy, float3 reference, IMPColorSpaceIndex space, uint2  spacePlanes, bool drawClipping) {
    
    float2 xrange = IMPgetColorSpaceRange (space, spacePlanes.x);
    float2 yrange = IMPgetColorSpaceRange (space, spacePlanes.y);
    
    float3 nc = reference;     
    
    nc[spacePlanes.x] = xy.x * (xrange.y - xrange.x) + xrange.x;
    nc[spacePlanes.y] = xy.y * (yrange.y - yrange.x) + yrange.x;
    
    nc = IMPConvertColor(space, IMPRgbSpace, nc);
    
    float4 result = float4(nc,1);
    float  a = 1;
    
    if (drawClipping){        
        for(int i=0; i<3; i++){
            if (result[i]<0 || result[i]>1) {
                a = 0.2;
                break;
            }
        }        
    }
    
    return mix(float4(0.2,0.2,0.2,1),result,float4(a));
}

kernel void kernel_mlsPlaneTransform(
                                     metal::texture2d<float, metal::access::sample> source     [[texture(0)]],
                                     metal::texture2d<float, metal::access::write>  outTexture [[texture(1)]],
                                     constant float3              &reference      [[buffer(0)]],
                                     constant IMPColorSpaceIndex  &space          [[buffer(1)]],
                                     constant uint2               &spacePlanes    [[buffer(2)]],
                                     
                                     constant float2  *p           [[buffer(3)]],
                                     constant float2  *q           [[buffer(4)]],
                                     constant int    &count        [[buffer(5)]],
                                     constant MLSSolverKind  &kind [[buffer(6)]],
                                     constant float    &alpha      [[buffer(7)]],
                                     
                                     metal::uint2 gid [[thread_position_in_grid]]
                                     )
{
    float2 xy = float2(gid)/float2(outTexture.get_width(),outTexture.get_height());    
    
    xy = float2(xy.x,1-xy.y);
    
    IMPMLSSolver solver = IMPMLSSolver(xy, p, q, count, kind, alpha);
    xy = solver.value(xy);
    
    float4 rgba = color_plane(xy, reference, space, spacePlanes, false);       
    
    outTexture.write(rgba, gid);    
}


kernel void kernel_mlsLutTransform(
                                     metal::texture2d<float, metal::access::read> lut [[texture(0)]],
                                     metal::texture2d<float, metal::access::write>  outTexture [[texture(1)]],
                                     constant float3              &reference      [[buffer(0)]],
                                     constant IMPColorSpaceIndex  &space          [[buffer(1)]],
                                     constant uint2               &spacePlanes    [[buffer(2)]],
                                     
                                     constant float2  *p           [[buffer(3)]],
                                     constant float2  *q           [[buffer(4)]],
                                     constant int    &count        [[buffer(5)]],
                                     constant MLSSolverKind  &kind [[buffer(6)]],
                                     constant float    &alpha      [[buffer(7)]],
                                     
                                     metal::uint2 gid [[thread_position_in_grid]]
                                     )
{
        
    float2 xyLut = float2(gid)/float2(outTexture.get_width(),outTexture.get_height());    
    xyLut = float2(xyLut.x, xyLut.y);    
    
    float3 rgb = lut.read(gid).rgb; 
    
    float3 lutXyz = IMPConvertToNormalizedColor(IMPRgbSpace, 
                                    space, 
                                    rgb);
    
    float2 xy(lutXyz[spacePlanes.x], lutXyz[spacePlanes.y]);
    
    float2 value = IMPMLSSolver(xy, p, q, count, kind, alpha).value(xy);
        
    lutXyz[spacePlanes.x] = value.x;
    lutXyz[spacePlanes.y] = value.y;
        
    float3 lutRgb = IMPConvertFromNormalizedColor(space, 
                                    IMPRgbSpace,
                                    lutXyz);
    
    outTexture.write(float4(lutRgb,1), gid);    
}
