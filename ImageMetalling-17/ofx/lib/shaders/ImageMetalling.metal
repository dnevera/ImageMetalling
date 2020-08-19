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

kernel void kernel_buffer_to_texture(

        const device float*    p_Input   [[buffer (0)]],
        texture2d<float, access::write>  destination  [[ texture(0) ]],

        constant unsigned int& p_Width   [[buffer (2)]],
        constant unsigned int& p_Height  [[buffer (3)]],

        uint2 id [[thread_position_in_grid]])
{
  if ((id.x < p_Width) && (id.y < p_Height)) {
    const int index = ((id.y * p_Width) + id.x) * 4;
    float4 inColor(p_Input[index + 0], p_Input[index + 1], p_Input[index + 2], p_Input[index + 3]);
    destination.write(inColor,id);
  }
}

kernel void kernel_texture_to_buffer(

        texture2d<float, access::read> source [[texture(0)]],
        device float*                  p_Output [[buffer (0)]],

        uint2 id [[thread_position_in_grid]])
{
  unsigned int p_Width = source.get_width();
  unsigned int p_Height = source.get_height();

  if ((id.x < p_Width) && (id.y < p_Height)) {
    const int index = ((id.y * p_Width) + id.x) * 4;

    float4 color     = source.read(id);

    p_Output[index + 0] = color.r;
    p_Output[index + 1] = color.g;
    p_Output[index + 2] = color.b;
    p_Output[index + 3] = color.rgba.a;
  }
}

kernel void kernel_dehancer_pass(
        texture2d<float, access::sample>  source       [[texture(0)]],
        texture2d<float, access::write>   destination  [[texture(1)]],

        uint2 id [[thread_position_in_grid]])
{
  float4 color     = source.read(id);
  destination.write(color, id);
}
