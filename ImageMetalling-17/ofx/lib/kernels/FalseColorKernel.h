//
// Created by denn nevera on 2019-12-23.
//
#pragma once

#include "Kernel.h"
#include <vector>

namespace imetalling {

    class FalseColorKernel: public Kernel {
    public:
        FalseColorKernel(const void *command_queue,
                         const Texture &source,
                         const Texture &destination,
                         bool wait_until_completed = WAIT_UNTIL_COMPLETED);
        void setup(CommandEncoder &commandEncoder) override ;
    private:
        std::vector<simd::float3> color_map_;
    };
}