//
// Created by denn nevera on 2019-12-23.
//

#include "FalseColorKernel.h"
#include "Defaults.h"

namespace imetalling {

    static std::string __profile_kernel("kernel_falseColor");

    FalseColorKernel::FalseColorKernel(const void *command_queue,
                                       const Texture &source,
                                       const Texture &destination,
                                       bool wait_until_completed) :
            Kernel(command_queue, __profile_kernel, source, destination,wait_until_completed),
            color_map_( )
    {
        for(auto c: Defaults::false_color_map) {
            color_map_.push_back(c);
        }
    }

    void FalseColorKernel::setup(CommandEncoder &compute_encoder) {
#ifdef __DEHANCER_USING_METAL__
        uint level = static_cast<uint>(color_map_.size());
        uint size = sizeof(simd::float3)*level;
        [compute_encoder setBytes:color_map_.data() length:size atIndex:0];
        [compute_encoder setBytes:&level length:sizeof(level) atIndex:1];
#endif
    }
}