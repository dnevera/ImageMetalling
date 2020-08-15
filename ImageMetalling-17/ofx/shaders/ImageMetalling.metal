#include <metal_stdlib>
using namespace metal;

static constant float3 kIMP_Y_YUV_factor = {0.2125, 0.7154, 0.0721};
constexpr sampler baseSampler(address::clamp_to_edge, filter::linear, coord::normalized);

inline float when_eq(float x, float y) {
  return 1.0 - abs(sign(x - y));
}

static inline float4 sampledColor(
        texture2d<float, access::sample> inTexture,
        texture2d<float, access::write> outTexture,
        uint2 gid
){
  float w = outTexture.get_width();
  return mix(inTexture.sample(baseSampler, float2(gid) * float2(1.0/(w-1.0), 1.0/float(outTexture.get_height()-1))),
             inTexture.read(gid),
             when_eq(inTexture.get_width(), w) // whe equal read exact texture color
  );
}

kernel void kernel_falseColor(
        texture2d<float, access::sample> inTexture [[texture(0)]],
        texture2d<float, access::write> outTexture [[texture(1)]],
        device float3* color_map [[ buffer(0) ]],
        constant uint& level [[ buffer(1) ]],
        uint2 gid [[thread_position_in_grid]])
{
  float4  inColor  = sampledColor(inTexture,outTexture,gid);
  float luminance = dot(inColor.rgb, kIMP_Y_YUV_factor);
  uint      index = clamp(uint(luminance*(level-1)),uint(0),uint(level-1));
  float4    color = float4(1);

  if (index<level)
    color.rgb = color_map[index];

  outTexture.write(color,gid);
}
