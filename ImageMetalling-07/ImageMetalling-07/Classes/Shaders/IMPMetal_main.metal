//
//  IMPMetal_main.metal
//  ImageMetalling-07
//
//  Created by denis svinarchuk on 15.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

inline float when_eq(float x, float y) {
    return 1.0 - abs(sign(x - y));
}

inline float4 sampledColor(
                           texture2d<float, access::sample> inTexture,
                           texture2d<float, access::write> outTexture,
                           uint2 gid
                           ){
    constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
    float w = outTexture.get_width();
    return mix(inTexture.sample(s, float2(gid) * float2(1.0/w, 1.0/outTexture.get_height())),
               inTexture.read(gid),
               when_eq(inTexture.get_width(), w) // whe equal read exact texture color
               );
}

kernel void kernel_passthrough(texture2d<float, access::sample> inTexture [[texture(0)]],
                               texture2d<float, access::write> outTexture [[texture(1)]],
                               uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = sampledColor(inTexture,outTexture,gid);
    outTexture.write(inColor, gid);
}

kernel void kernel_desaturate(texture2d<float, access::sample> inTexture [[texture(0)]],
                               texture2d<float, access::write> outTexture [[texture(1)]],
                               uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = sampledColor(inTexture,outTexture,gid);
    inColor.rgb = float3(dot(inColor.rgb,float3(0.3,0.6,0.1)));
    outTexture.write(inColor, gid);
}


typedef struct {
    packed_float2 position;
    packed_float2 texcoord;
} VertexIn;

typedef struct{
    uint   width;
    uint   height;
    float  resampleFactor;
} OutputTextureInfo;

typedef struct {
    float4 position [[position]];
    float2 texcoord;
} VertexOut;

/**
 * View rendering vertex
 */
vertex VertexOut vertex_passview(
                                 device VertexIn*    verticies [[ buffer(0) ]],
                                 unsigned int        vid       [[ vertex_id ]]
                                 ) {
    VertexOut out;
    
    device VertexIn& v = verticies[vid];
    
    float3 position = float3(float2(v.position) , 0.0);
    
    out.position = float4(position, 1.0);
    
    out.texcoord = float2(v.texcoord);
    
    return out;
}


/**
 *  Pass through fragment
 *
 */
fragment half4 fragment_passthrough(
                                    VertexOut in [[ stage_in ]],
                                    texture2d<float, access::sample> texture [[ texture(0) ]]
                                    ) {
    constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
    float3 rgb = texture.sample(s, in.texcoord).rgb;
    return half4(half3(rgb), 1.0);
}

